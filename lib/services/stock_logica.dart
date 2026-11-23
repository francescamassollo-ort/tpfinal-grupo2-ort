import '../models/movimiento_stock.dart';
import '../models/usuario_actual.dart';

/// Una operación de stock que no se puede hacer (cantidad inválida, stock
/// insuficiente, insumo inexistente). El mensaje se puede mostrar tal cual.
class StockException implements Exception {
  const StockException(this.mensaje, {this.insumoId});

  final String mensaje;

  /// El insumo que causó el problema, cuando se operó sobre varios a la vez
  /// (por ejemplo, el que no tiene stock suficiente). Sirve para decirle a la
  /// persona de cuál se trata. Null si no aplica.
  final String? insumoId;

  @override
  String toString() => mensaje;
}

/// Una línea de una salida de varios insumos: cuánto retirar de cuál.
typedef LineaDeSalida = ({String insumoId, int cantidad});

/// Lo que resulta de una operación de stock: cuánto queda y el movimiento que
/// hay que guardar para dejar constancia.
class CambioDeStock {
  const CambioDeStock({required this.stockNuevo, required this.movimiento});

  /// El stock que tiene que quedar guardado en el insumo.
  final int stockNuevo;

  /// El movimiento a guardar en el historial. Su id va vacío: lo asigna
  /// Firestore al guardarlo.
  final MovimientoStock movimiento;
}

/// Las cuentas del stock, sin tocar Firestore: valida la operación, calcula el
/// stock que queda y arma el movimiento. Así se prueban solas.
///
/// Quien guarda ([StockService]) tiene que escribir [CambioDeStock.stockNuevo]
/// y [CambioDeStock.movimiento] en la misma transacción: que no quede un stock
/// cambiado sin su movimiento ni al revés.
///
/// La cantidad del movimiento se guarda como pide [MovimientoStock]: positiva
/// en entradas y salidas (el sentido lo da el tipo) y con signo en los ajustes.
class StockLogica {
  StockLogica._();

  static const String mensajeCantidadInvalida =
      'La cantidad debe ser mayor a 0';
  static const String mensajeStockInsuficiente = 'Stock insuficiente';
  static const String mensajeInsumoNoEncontrado = 'Insumo no encontrado';
  static const String mensajeStockNegativo = 'El stock no puede ser negativo';
  static const String mensajeSinCambios = 'El stock ya es esa cantidad';
  static const String mensajeSinLineas = 'No hay insumos para retirar';
  static const String mensajeInsumoRepetido =
      'El mismo insumo está más de una vez';

  /// Motivo con el que queda registrada la entrada del stock inicial de un
  /// insumo nuevo.
  static const String motivoAlta = 'Alta de insumo';

  /// Suma [cantidad] al stock.
  static CambioDeStock entrada({
    required String insumoId,
    required int stockActual,
    required int cantidad,
    required UsuarioActual usuario,
    required DateTime ahora,
    String? motivo,
  }) {
    _validarCantidad(cantidad);
    return CambioDeStock(
      stockNuevo: stockActual + cantidad,
      movimiento: _movimiento(
        insumoId: insumoId,
        tipo: TipoMovimiento.entrada,
        cantidad: cantidad,
        usuario: usuario,
        ahora: ahora,
        motivo: motivo,
      ),
    );
  }

  /// Resta [cantidad] del stock. No se puede sacar más de lo que hay.
  static CambioDeStock salida({
    required String insumoId,
    required int stockActual,
    required int cantidad,
    required UsuarioActual usuario,
    required DateTime ahora,
    String? motivo,
  }) {
    _validarCantidad(cantidad);
    if (cantidad > stockActual) {
      throw const StockException(mensajeStockInsuficiente);
    }
    return CambioDeStock(
      stockNuevo: stockActual - cantidad,
      movimiento: _movimiento(
        insumoId: insumoId,
        tipo: TipoMovimiento.salida,
        cantidad: cantidad,
        usuario: usuario,
        ahora: ahora,
        motivo: motivo,
      ),
    );
  }

  /// Retira varios insumos a la vez, por ejemplo un consumo de un trabajo
  /// práctico. [stocks] es el stock actual de cada insumo (por id). Devuelve un
  /// cambio por línea, en el mismo orden.
  ///
  /// Es todo o nada: si una línea no se puede hacer (stock insuficiente, insumo
  /// inexistente, cantidad inválida) lanza una [StockException] con el
  /// [StockException.insumoId] de esa línea, y no hay cambios que aplicar para
  /// ninguna. Un mismo insumo no puede estar en dos líneas: el control de stock
  /// se haría contra cada una por separado y podría pasarse de lo que hay.
  static List<CambioDeStock> salidas({
    required List<LineaDeSalida> lineas,
    required Map<String, int> stocks,
    required UsuarioActual usuario,
    required DateTime ahora,
    String? motivo,
  }) {
    if (lineas.isEmpty) throw const StockException(mensajeSinLineas);

    final vistos = <String>{};
    for (final linea in lineas) {
      if (!vistos.add(linea.insumoId)) {
        throw StockException(mensajeInsumoRepetido, insumoId: linea.insumoId);
      }
    }

    return [
      for (final linea in lineas)
        _salidaDeLinea(
          linea,
          stocks: stocks,
          usuario: usuario,
          ahora: ahora,
          motivo: motivo,
        ),
    ];
  }

  static CambioDeStock _salidaDeLinea(
    LineaDeSalida linea, {
    required Map<String, int> stocks,
    required UsuarioActual usuario,
    required DateTime ahora,
    required String? motivo,
  }) {
    final stockActual = stocks[linea.insumoId];
    if (stockActual == null) {
      throw StockException(
        mensajeInsumoNoEncontrado,
        insumoId: linea.insumoId,
      );
    }

    try {
      return salida(
        insumoId: linea.insumoId,
        stockActual: stockActual,
        cantidad: linea.cantidad,
        usuario: usuario,
        ahora: ahora,
        motivo: motivo,
      );
    } on StockException catch (error) {
      // Se vuelve a lanzar diciendo de qué insumo se trata.
      throw StockException(error.mensaje, insumoId: linea.insumoId);
    }
  }

  /// Deja el stock en [stockDeseado], por ejemplo después de contar el
  /// inventario. El movimiento guarda la diferencia con signo: positiva si el
  /// stock subió y negativa si bajó.
  static CambioDeStock ajuste({
    required String insumoId,
    required int stockActual,
    required int stockDeseado,
    required UsuarioActual usuario,
    required DateTime ahora,
    String? motivo,
  }) {
    if (stockDeseado < 0) throw const StockException(mensajeStockNegativo);
    final diferencia = stockDeseado - stockActual;
    // Un ajuste que no cambia nada no es un movimiento: ensuciaría el
    // historial.
    if (diferencia == 0) throw const StockException(mensajeSinCambios);

    return CambioDeStock(
      stockNuevo: stockDeseado,
      movimiento: _movimiento(
        insumoId: insumoId,
        tipo: TipoMovimiento.ajuste,
        cantidad: diferencia,
        usuario: usuario,
        ahora: ahora,
        motivo: motivo,
      ),
    );
  }

  /// El movimiento que deja el alta de un insumo con [stockInicial]: una
  /// entrada por todo ese stock, para que el historial cuente desde el primer
  /// día. Devuelve null si el stock inicial es 0, porque no hay nada que
  /// registrar.
  static MovimientoStock? altaDeInsumo({
    required String insumoId,
    required int stockInicial,
    required UsuarioActual usuario,
    required DateTime ahora,
  }) {
    if (stockInicial < 0) throw const StockException(mensajeStockNegativo);
    if (stockInicial == 0) return null;

    return _movimiento(
      insumoId: insumoId,
      tipo: TipoMovimiento.entrada,
      cantidad: stockInicial,
      usuario: usuario,
      ahora: ahora,
      motivo: motivoAlta,
    );
  }

  static void _validarCantidad(int cantidad) {
    if (cantidad <= 0) throw const StockException(mensajeCantidadInvalida);
  }

  static MovimientoStock _movimiento({
    required String insumoId,
    required TipoMovimiento tipo,
    required int cantidad,
    required UsuarioActual usuario,
    required DateTime ahora,
    required String? motivo,
  }) {
    final motivoLimpio = motivo?.trim();
    return MovimientoStock(
      id: '',
      productoId: insumoId,
      usuarioId: usuario.id,
      usuarioNombre: usuario.nombre,
      tipo: tipo,
      cantidad: cantidad,
      fecha: ahora,
      // Un motivo vacío es lo mismo que no tener motivo.
      motivo: motivoLimpio == null || motivoLimpio.isEmpty ? null : motivoLimpio,
    );
  }
}
