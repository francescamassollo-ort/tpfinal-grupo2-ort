import '../models/insumo.dart';
import 'similitud_texto.dart';

/// Lógica del buscador del Inventario. Es pura (no depende de Firestore ni de
/// Flutter), así que se prueba sola.
class BusquedaDeInsumos {
  BusquedaDeInsumos._();

  /// Los textos de un insumo donde se busca: nombre, fórmula, código interno,
  /// otros nombres, categoría, marca, código de barras y ubicación.
  static List<String> camposBuscables(Insumo insumo) => [
        insumo.nombre,
        if (insumo.formula != null) insumo.formula!,
        if (insumo.codigoInterno != null) insumo.codigoInterno!,
        ...insumo.otrosNombres,
        if (insumo.categoria != null) insumo.categoria!,
        if (insumo.marca != null) insumo.marca!,
        if (insumo.codigoBarras != null) insumo.codigoBarras!,
        insumo.ubicacion,
      ];

  /// Dice si [insumo] coincide con lo que se escribió en el buscador.
  ///
  /// No mira mayúsculas ni tildes ("acido" encuentra "Ácido acético"). El
  /// texto se parte en palabras y TODAS tienen que aparecer, cada una en algún
  /// campo (que no hace falta que sea el mismo): "acetico acido" también lo
  /// encuentra. Un texto vacío (o sin letras ni números) no filtra nada.
  static bool coincide(Insumo insumo, String texto) {
    final palabras = texto
        .split(RegExp(r'\s+'))
        .map(SimilitudTexto.normalizar)
        .where((p) => p.isNotEmpty)
        .toList();
    if (palabras.isEmpty) return true;

    final campos = camposBuscables(insumo).map(SimilitudTexto.normalizar).toList();
    return palabras.every((palabra) => campos.any((c) => c.contains(palabra)));
  }
}
