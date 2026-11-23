import 'package:cloud_firestore/cloud_firestore.dart';

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
