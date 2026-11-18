import 'insumo_service.dart';

class StockService {
  final InsumoService _insumoService = InsumoService();

  Future<int> getStockByInsumo(String insumoId) async {
    final insumo = await _insumoService.obtenerInsumo(insumoId);

    if (insumo == null) {
      throw Exception('Insumo no encontrado');
    }

    return insumo.stock;
  }

  Future<void> registrarEntrada(
    String insumoId,
    int cantidad,
    String motivo,
  ) async {
    final insumo = await _insumoService.obtenerInsumo(insumoId);

    if (insumo == null) {
      throw Exception('Insumo no encontrado');
    }

    final nuevoStock = insumo.stock + cantidad;

    await _insumoService.actualizarStock(
      insumoId,
      nuevoStock,
    );
  }

  Future<void> registrarSalida(
    String insumoId,
    int cantidad,
    String motivo,
  ) async {
    final insumo = await _insumoService.obtenerInsumo(insumoId);

    if (insumo == null) {
      throw Exception('Insumo no encontrado');
    }

    if (cantidad > insumo.stock) {
      throw Exception('Stock insuficiente');
    }

    final nuevoStock = insumo.stock - cantidad;

    await _insumoService.actualizarStock(
      insumoId,
      nuevoStock,
    );
  }

  Future<void> registrarAjuste(
    String insumoId,
    int cantidadNueva,
    String motivo,
  ) async {
    final insumo = await _insumoService.obtenerInsumo(insumoId);

    if (insumo == null) {
      throw Exception('Insumo no encontrado');
    }

    await _insumoService.actualizarStock(
      insumoId,
      cantidadNueva,
    );
  }
}