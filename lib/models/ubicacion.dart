/// Un lugar físico donde se guardan insumos: un armario, un estante, una
/// heladera ("Laboratorio 404 - Armario 1 - Estante A").
///
/// Hay una lista única de ubicaciones en vez de un texto libre en cada insumo,
/// para que "Armario 1" y "armario 1 " no terminen siendo lugares distintos.
class Ubicacion {
  const Ubicacion({required this.id, required this.nombre});

  /// El id es el nombre sin mayúsculas, tildes, espacios ni signos (ver
  /// `UbicacionesLogica.idDe`): así dos escrituras del mismo lugar dan el mismo
  /// documento y no se puede cargar dos veces.
  final String id;
  final String nombre;

  factory Ubicacion.fromMap(String id, Map<String, dynamic> data) =>
      Ubicacion(id: id, nombre: data['nombre'] as String);

  Map<String, dynamic> toMap() => {'nombre': nombre};

  @override
  bool operator ==(Object other) =>
      other is Ubicacion && other.id == id && other.nombre == nombre;

  @override
  int get hashCode => Object.hash(id, nombre);
}
