import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/insumo.dart';
import '../models/usuario_actual.dart';
import 'historial_service.dart';
import 'insumo_service.dart';
import 'stock_logica.dart';
import 'usuario_actual_service.dart';

/// Cambia el stock de los insumos y deja constancia de cada cambio en el
/// historial de movimientos.
///
/// Cada operación guarda dos cosas en una sola transacción de Firestore: el
/// stock nuevo del insumo y el [MovimientoStock] que lo explica. Si una falla,
/// no se guarda ninguna: no puede quedar un stock cambiado sin su movimiento ni
/// al revés. Las cuentas (validar, calcular el stock que queda, armar el
/// movimiento) están en [StockLogica], que se prueba sola.
///
/// El movimiento queda a nombre de la persona con sesión (ver
/// [UsuarioActualService]); sin sesión, a nombre de "Sin sesión".
///
/// Si una operación no se puede hacer (cantidad inválida, stock insuficiente,
/// insumo inexistente) lanza una [StockException] con un mensaje listo para
/// mostrar.
class StockService {
  StockService({
    FirebaseFirestore? db,
    UsuarioActualService? usuarioActual,
  })  : _dbOpcional = db,
        _usuarioActual = usuarioActual ?? UsuarioActualService();

  final FirebaseFirestore? _dbOpcional;
  final UsuarioActualService _usuarioActual;

  // Se pide recién al usarlo: crear un StockService no toca Firebase.
  FirebaseFirestore get _db => _dbOpcional ?? FirebaseFirestore.instance;

  Future<int> getStockByInsumo(String insumoId) async {
    final insumo = await InsumoService().obtenerInsumo(insumoId);

    if (insumo == null) {
      throw const StockException(StockLogica.mensajeInsumoNoEncontrado);
    }

    return insumo.stock;
  }

  /// Da de alta un insumo nuevo y, si trae stock, deja una entrada con ese
  /// stock inicial en el historial. Las dos escrituras van juntas: o se guardan
  /// las dos o ninguna. Devuelve el id del insumo creado.
  Future<String> registrarAlta(Insumo insumo) async {
    final usuario = await _usuarioActual.obtener();

    final insumoRef = _db.collection(InsumoService.coleccion).doc();
    final movimiento = StockLogica.altaDeInsumo(
      insumoId: insumoRef.id,
      stockInicial: insumo.stock,
      usuario: usuario,
      ahora: DateTime.now(),
    );

    final lote = _db.batch()..set(insumoRef, insumo.toMap());
    if (movimiento != null) {
      lote.set(
        _db.collection(HistorialService.coleccion).doc(),
        movimiento.toMap(),
      );
    }
    await lote.commit();

    return insumoRef.id;
  }

  /// Suma [cantidad] al stock del insumo. Deja un movimiento de entrada.
  Future<void> registrarEntrada(
    String insumoId,
    int cantidad,
    String motivo,
  ) {
    return _aplicar(
      insumoId,
      (stockActual, usuario, ahora) => StockLogica.entrada(
        insumoId: insumoId,
        stockActual: stockActual,
        cantidad: cantidad,
        usuario: usuario,
        ahora: ahora,
        motivo: motivo,
      ),
    );
  }

  /// Resta [cantidad] del stock del insumo. Deja un movimiento de salida.
  Future<void> registrarSalida(
    String insumoId,
    int cantidad,
    String motivo,
  ) {
    return _aplicar(
      insumoId,
      (stockActual, usuario, ahora) => StockLogica.salida(
        insumoId: insumoId,
        stockActual: stockActual,
        cantidad: cantidad,
        usuario: usuario,
        ahora: ahora,
        motivo: motivo,
      ),
    );
  }

  /// Retira varios insumos a la vez, por ejemplo el consumo de un trabajo
  /// práctico. Es todo o nada: si falla una línea (por ejemplo, no hay stock
  /// suficiente de un insumo), no se registra ninguna. Cada línea deja su propio
  /// movimiento de salida, con el mismo [motivo].
  ///
  /// Si una línea no se puede hacer, lanza una [StockException] cuyo
  /// [StockException.insumoId] dice cuál.
  Future<void> registrarSalidas(
    List<LineaDeSalida> lineas,
    String motivo,
  ) async {
    final usuario = await _usuarioActual.obtener();
    final referencias = {
      for (final linea in lineas)
        linea.insumoId:
            _db.collection(InsumoService.coleccion).doc(linea.insumoId),
    };

    await _db.runTransaction((transaccion) async {
      // Firestore exige hacer todas las lecturas antes de la primera
      // escritura.
      final stocks = <String, int>{};
      for (final entrada in referencias.entries) {
        final doc = await transaccion.get(entrada.value);
        final datos = doc.data();
        if (!doc.exists || datos == null) {
          throw StockException(
            StockLogica.mensajeInsumoNoEncontrado,
            insumoId: entrada.key,
          );
        }
        stocks[entrada.key] = (datos['stock'] as num).toInt();
      }

      final cambios = StockLogica.salidas(
        lineas: lineas,
        stocks: stocks,
        usuario: usuario,
        ahora: DateTime.now(),
        motivo: motivo,
      );

      for (var i = 0; i < lineas.length; i++) {
        transaccion.update(
          referencias[lineas[i].insumoId]!,
          {'stock': cambios[i].stockNuevo},
        );
        transaccion.set(
          _db.collection(HistorialService.coleccion).doc(),
          cambios[i].movimiento.toMap(),
        );
      }
    });
  }

  /// Deja el stock del insumo en [cantidadNueva]. Deja un movimiento de ajuste
  /// con la diferencia.
  Future<void> registrarAjuste(
    String insumoId,
    int cantidadNueva,
    String motivo,
  ) {
    return _aplicar(
      insumoId,
      (stockActual, usuario, ahora) => StockLogica.ajuste(
        insumoId: insumoId,
        stockActual: stockActual,
        stockDeseado: cantidadNueva,
        usuario: usuario,
        ahora: ahora,
        motivo: motivo,
      ),
    );
  }

  /// Lee el stock actual del insumo, calcula el cambio con [calcular] y guarda
  /// el stock nuevo y el movimiento, todo en una transacción. La lectura va
  /// dentro de la transacción para que dos consumos a la vez no se pisen.
  Future<void> _aplicar(
    String insumoId,
    CambioDeStock Function(
      int stockActual,
      UsuarioActual usuario,
      DateTime ahora,
    ) calcular,
  ) async {
    // Quién es la persona se averigua antes: es una lectura de otra colección
    // y no tiene por qué ir dentro de la transacción.
    final usuario = await _usuarioActual.obtener();

    final insumoRef = _db.collection(InsumoService.coleccion).doc(insumoId);
    final movimientoRef = _db.collection(HistorialService.coleccion).doc();

    await _db.runTransaction((transaccion) async {
      final doc = await transaccion.get(insumoRef);
      final datos = doc.data();
      if (!doc.exists || datos == null) {
        throw const StockException(StockLogica.mensajeInsumoNoEncontrado);
      }

      final cambio = calcular(
        (datos['stock'] as num).toInt(),
        usuario,
        DateTime.now(),
      );

      transaccion.update(insumoRef, {'stock': cambio.stockNuevo});
      transaccion.set(movimientoRef, cambio.movimiento.toMap());
    });
  }
}
