import '../models/insumo.dart';

/// El texto con que se muestra cada insumo en un desplegable: id del insumo ->
/// etiqueta.
///
/// Dos insumos pueden llamarse igual (por ejemplo, el mismo producto en dos
/// armarios). A esos se les suma la ubicación para poder distinguirlos, como en
/// "Algodon - Armario 5"; si el nombre es único, es solo el nombre. Las
/// mayúsculas no cuentan: "Algodon" y "algodon" se consideran el mismo nombre.
Map<String, String> etiquetasDeInsumos(Iterable<Insumo> insumos) {
  final cuantos = <String, int>{};
  for (final insumo in insumos) {
    cuantos.update(insumo.nombre.toLowerCase(), (n) => n + 1, ifAbsent: () => 1);
  }

  return {
    for (final insumo in insumos)
      insumo.id: cuantos[insumo.nombre.toLowerCase()]! > 1
          ? '${insumo.nombre} - ${insumo.ubicacion}'
          : insumo.nombre,
  };
}
