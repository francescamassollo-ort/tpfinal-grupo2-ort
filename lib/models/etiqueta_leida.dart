/// Lo que se pudo entender del texto de la etiqueta de un insumo. Todo es una
/// sugerencia que sale de reconocer texto en una foto: puede faltar o venir
/// mal, por eso el Alta lo deja editable.
class EtiquetaLeida {
  const EtiquetaLeida({
    this.nombre,
    this.marca,
    this.formula,
    this.pesoMolecular,
    this.fechaVencimiento,
    this.cas,
    this.texto = '',
  });

  final String? nombre;
  final String? marca;
  final String? formula;
  final double? pesoMolecular;
  final DateTime? fechaVencimiento;

  /// Número CAS (por ejemplo "64-17-5"), validado con su dígito de control. El
  /// Alta no lo guarda: sirve para pedirle a PubChem la fórmula y el peso.
  final String? cas;

  /// Todo el texto que se reconoció, tal cual.
  final String texto;

  /// No se entendió ningún dato.
  bool get vacia =>
      nombre == null &&
      marca == null &&
      formula == null &&
      pesoMolecular == null &&
      fechaVencimiento == null &&
      cas == null;

  EtiquetaLeida copiarCon({
    String? formula,
    double? pesoMolecular,
  }) {
    return EtiquetaLeida(
      nombre: nombre,
      marca: marca,
      formula: formula ?? this.formula,
      pesoMolecular: pesoMolecular ?? this.pesoMolecular,
      fechaVencimiento: fechaVencimiento,
      cas: cas,
      texto: texto,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is EtiquetaLeida &&
      other.nombre == nombre &&
      other.marca == marca &&
      other.formula == formula &&
      other.pesoMolecular == pesoMolecular &&
      other.fechaVencimiento == fechaVencimiento &&
      other.cas == cas &&
      other.texto == texto;

  @override
  int get hashCode => Object.hash(
        nombre,
        marca,
        formula,
        pesoMolecular,
        fechaVencimiento,
        cas,
        texto,
      );

  @override
  String toString() =>
      'EtiquetaLeida(nombre: $nombre, marca: $marca, formula: $formula, '
      'peso: $pesoMolecular, vence: $fechaVencimiento, cas: $cas)';
}
