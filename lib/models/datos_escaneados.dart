/// Lo que el escáner le devuelve al Alta de insumo para que complete el
/// formulario. Solo [codigo] es seguro: el resto viene de una base externa y
/// puede faltar o estar mal, por eso el Alta lo deja editable.
class DatosEscaneados {
  const DatosEscaneados({
    required this.codigo,
    this.nombre,
    this.marca,
    this.formula,
    this.pesoMolecular,
  });

  final String codigo;
  final String? nombre;
  final String? marca;
  final String? formula;
  final double? pesoMolecular;

  @override
  bool operator ==(Object other) =>
      other is DatosEscaneados &&
      other.codigo == codigo &&
      other.nombre == nombre &&
      other.marca == marca &&
      other.formula == formula &&
      other.pesoMolecular == pesoMolecular;

  @override
  int get hashCode => Object.hash(codigo, nombre, marca, formula, pesoMolecular);
}
