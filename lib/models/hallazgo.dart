/// Qué encontró la revisión de datos en un insumo o entre varios.
enum TipoHallazgo {
  /// Dos insumos que son el mismo producto: mismo código de barras o mismo
  /// nombre una vez normalizado.
  duplicadoExacto,

  /// Dos insumos con nombres muy parecidos que probablemente son el mismo.
  duplicadoProbable,

  stockNegativo,
  umbralNegativo,

  /// La alarma de vencimiento está activada pero no hay fecha de vencimiento.
  alarmaSinFecha,

  /// La fecha de vencimiento es anterior a la de elaboración.
  vencimientoAnteriorAElaboracion,

  sinUbicacion,

  /// Solución preparada sin concentración, que es un dato obligatorio.
  solucionSinConcentracion;

  /// Los duplicados involucran a dos insumos; las inconsistencias, a uno.
  bool get esDuplicado =>
      this == TipoHallazgo.duplicadoExacto ||
      this == TipoHallazgo.duplicadoProbable;
}

/// Un duplicado o una inconsistencia detectada en los insumos.
///
/// No se guarda: se calcula a partir de los insumos, igual que las alertas.
class Hallazgo {
  const Hallazgo({
    required this.tipo,
    required this.insumoIds,
    this.confianza = 1,
  });

  final TipoHallazgo tipo;

  /// Ids de los insumos involucrados: dos en un duplicado, uno en una
  /// inconsistencia.
  final List<String> insumoIds;

  /// Qué tan seguro es el hallazgo, de 0 a 1. Las inconsistencias son 1; en
  /// los duplicados probables es la similitud entre los nombres.
  final double confianza;

  @override
  bool operator ==(Object other) =>
      other is Hallazgo &&
      other.tipo == tipo &&
      other.confianza == confianza &&
      _mismosIds(other.insumoIds, insumoIds);

  @override
  int get hashCode => Object.hash(tipo, confianza, Object.hashAll(insumoIds));

  static bool _mismosIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
