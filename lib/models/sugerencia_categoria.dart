/// De dónde sale una sugerencia de categoría.
enum OrigenSugerencia {
  /// Un insumo que ya existe con un nombre parecido y esa categoría. Es la más
  /// confiable: respeta las categorías que ya usa el laboratorio.
  insumoParecido,

  /// Reglas por palabras del nombre o de la fórmula ("guante" es material
  /// descartable, "etanol" es un alcohol).
  reglas,

  /// Un modelo de lenguaje, cuando se lo pidió la persona.
  ia,
}

/// La categoría que se sugiere para un insumo. Es solo una sugerencia: la
/// persona decide si la usa.
class SugerenciaCategoria {
  const SugerenciaCategoria({
    required this.categoria,
    required this.confianza,
    required this.origen,
  });

  final String categoria;

  /// Qué tan segura es, de 0 a 1.
  final double confianza;

  final OrigenSugerencia origen;

  @override
  bool operator ==(Object other) =>
      other is SugerenciaCategoria &&
      other.categoria == categoria &&
      other.confianza == confianza &&
      other.origen == origen;

  @override
  int get hashCode => Object.hash(categoria, confianza, origen);

  @override
  String toString() => 'SugerenciaCategoria($categoria, $confianza, $origen)';
}
