import 'similitud_texto.dart';

/// Las reglas de la lista de ubicaciones, sin Firestore para poder probarlas
/// solas.
class UbicacionesLogica {
  UbicacionesLogica._();

  /// Desde este parecido (de 0 a 1) una ubicación se ofrece como "¿quisiste
  /// decir...?".
  static const double umbralParecido = 0.75;

  /// El id de una ubicación: el nombre sin mayúsculas, tildes, espacios ni
  /// signos. "Armario N°1" y "armario n° 1" dan lo mismo.
  static String idDe(String nombre) => SimilitudTexto.normalizar(nombre);

  /// El nombre limpio: sin espacios de más (ni al principio, ni al final, ni
  /// repetidos adentro).
  static String limpiar(String nombre) =>
      nombre.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// El nombre con el que hay que guardar [texto]: si ya existe una ubicación
  /// igual (sin mirar mayúsculas, tildes ni espacios) se usa **su** escritura;
  /// si no, el texto limpio. Así dos personas que escriben distinto el mismo
  /// lugar terminan con el mismo nombre.
  static String canonica(String texto, Iterable<String> existentes) {
    final limpio = limpiar(texto);
    final id = idDe(limpio);
    if (id.isEmpty) return limpio;
    for (final existente in existentes) {
      if (idDe(existente) == id) return existente;
    }
    return limpio;
  }

  /// Si [texto] ya es una ubicación de la lista.
  static bool existe(String texto, Iterable<String> existentes) {
    final id = idDe(texto);
    return id.isNotEmpty && existentes.any((e) => idDe(e) == id);
  }

  /// Las ubicaciones de la lista que se parecen a [texto] sin ser iguales:
  /// las que lo contienen o lo tienen parecido (un error de tipeo). Si los
  /// números difieren ("Armario 1" y "Armario 2") no se parecen: son lugares
  /// distintos. Las que empiezan igual van primero.
  static List<String> parecidas(
    String texto,
    Iterable<String> existentes, {
    int maximo = 3,
  }) {
    final id = idDe(texto);
    if (id.length < 2) return const [];

    final candidatas = <(String, bool)>[];
    for (final existente in existentes) {
      final otro = idDe(existente);
      if (otro == id) continue;
      final contiene = otro.contains(id);
      final parecido =
          SimilitudTexto.entreNombres(texto, existente) >= umbralParecido;
      if (contiene || parecido) candidatas.add((existente, otro.startsWith(id)));
    }
    candidatas.sort((a, b) {
      if (a.$2 != b.$2) return a.$2 ? -1 : 1;
      return a.$1.compareTo(b.$1);
    });
    return [for (final c in candidatas.take(maximo)) c.$1];
  }
}
