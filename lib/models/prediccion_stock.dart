/// Cuándo se estima que se agota un insumo si sigue consumiéndose al ritmo
/// reciente. Lo arma `StockPredictionService`; no se guarda en Firestore.
class PrediccionStock {
  const PrediccionStock({
    required this.productoId,
    required this.productoNombre,
    required this.stock,
    required this.consumoDiario,
    required this.diasRestantes,
    required this.fechaAgotamiento,
    required this.seAgotaAntesDeLaCompra,
  });

  final String productoId;
  final String productoNombre;

  /// Stock actual del insumo.
  final int stock;

  /// Unidades que se consumen por día, en promedio, en el período observado.
  final double consumoDiario;

  /// Días completos que alcanza el stock al ritmo actual. Cero si ya no queda.
  final int diasRestantes;

  /// Día estimado en que se agota: hoy más [diasRestantes].
  final DateTime fechaAgotamiento;

  /// Si se agota antes de la próxima compra institucional (julio o diciembre).
  /// Es lo que más le importa al laboratorio: lo que se agota antes de esa
  /// fecha ya no se puede reponer a tiempo.
  final bool seAgotaAntesDeLaCompra;
}
