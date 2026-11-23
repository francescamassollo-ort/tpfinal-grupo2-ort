import '../models/movimiento_stock.dart';
import '../models/usuario_actual.dart';

/// Una operación de stock que no se puede hacer (cantidad inválida, stock
/// insuficiente, insumo inexistente). El mensaje se puede mostrar tal cual.
class StockException implements Exception {
  const StockException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

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
