import 'movimiento_stock.dart';

/// Filtros del historial de movimientos. Todos son opcionales: un filtro vacío
/// deja pasar todos los movimientos.
///
/// Se aplica sobre una lista ya cargada y no con consultas a Firestore, para no
/// exigir índices compuestos. Sirve mientras el historial entre en memoria
/// (ver el tope de [HistorialService]).
class FiltroHistorial {
  const FiltroHistorial({
    this.productoId,
    this.usuarioId,
    this.desde,
    this.hasta,
    this.tipo,
  });

  /// Solo los movimientos de este insumo.
  final String? productoId;

  /// Solo los movimientos de esta persona.
  final String? usuarioId;

  /// Desde este día, inclusive. Cuenta el día completo, no la hora.
  final DateTime? desde;

  /// Hasta este día, inclusive. Cuenta el día completo, hasta las 23:59.
  final DateTime? hasta;

  final TipoMovimiento? tipo;

  bool get estaVacio =>
      productoId == null &&
      usuarioId == null &&
      desde == null &&
      hasta == null &&
      tipo == null;

  /// Deja los movimientos que cumplen todos los filtros puestos, en el mismo
  /// orden en que venían.
  List<MovimientoStock> aplicar(List<MovimientoStock> movimientos) {
    // Se compara contra el inicio del día siguiente al último día pedido, así
    // el último día entra completo sin importar la hora del movimiento.
    final inicio = desde == null ? null : _soloDia(desde!);
    final limite = hasta == null
        ? null
        : _soloDia(hasta!).add(const Duration(days: 1));

    return [
      for (final m in movimientos)
        if ((productoId == null || m.productoId == productoId) &&
            (usuarioId == null || m.usuarioId == usuarioId) &&
            (tipo == null || m.tipo == tipo) &&
            (inicio == null || !m.fecha.isBefore(inicio)) &&
            (limite == null || m.fecha.isBefore(limite)))
          m,
    ];
  }

  static DateTime _soloDia(DateTime fecha) =>
      DateTime(fecha.year, fecha.month, fecha.day);
}
