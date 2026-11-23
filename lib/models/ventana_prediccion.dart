/// Cuántos días de consumo mira la predicción, y por qué esa cantidad.
/// Lo arma `StockPredictionService.elegirVentana`; no se guarda en Firestore.
class VentanaPrediccion {
  const VentanaPrediccion({
    required this.ventanaDias,
    required this.elegidaPorHistorial,
    this.errorRelativoPorVentana = const {},
    this.evaluaciones = 0,
  });

  /// Días hacia atrás que se miran para calcular el ritmo de consumo.
  final int ventanaDias;

  /// Si se eligió comparando con lo que realmente pasó (true), o si faltaba
  /// historial y se usó la ventana por defecto (false).
  final bool elegidaPorHistorial;

  /// Cuánto se equivocó cada ventana candidata al "predecir el pasado", como
  /// fracción de lo que realmente se consumió: 0,25 es un error del 25 %. Vacío
  /// si no hubo historial suficiente para evaluar.
  final Map<int, double> errorRelativoPorVentana;

  /// Cuántas comparaciones (un insumo en un momento del pasado) se hicieron.
  final int evaluaciones;
}
