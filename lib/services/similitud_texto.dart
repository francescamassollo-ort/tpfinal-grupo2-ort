import 'dart:math' as math;

/// Funciones para comparar nombres de insumos. Son puras: no dependen de
/// Firestore ni de nada externo, por eso se pueden probar solas.
class SimilitudTexto {
  SimilitudTexto._();

  static const Map<String, String> _sinTildes = {
    'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a',
    'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
    'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
    'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o',
    'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
    'ñ': 'n',
  };

  /// Deja solo letras y números, en minúscula y sin tildes. Así "Etanol 96%" y
  /// "etanol 96 %" dan lo mismo: "etanol96".
  static String normalizar(String texto) {
    final buffer = StringBuffer();
    for (final rune in texto.toLowerCase().runes) {
      final caracter = String.fromCharCode(rune);
      final limpio = _sinTildes[caracter] ?? caracter;
      if (RegExp(r'[a-z0-9]').hasMatch(limpio)) buffer.write(limpio);
    }
    return buffer.toString();
  }

  /// Números que aparecen en el texto, en orden. La coma decimal se toma como
  /// punto: "0,5 M" da ["0.5"].
  static List<String> numerosEn(String texto) {
    return RegExp(r'\d+(?:[.,]\d+)?')
        .allMatches(texto)
        .map((m) => m.group(0)!.replaceAll(',', '.'))
        .toList();
  }

  /// Cantidad mínima de cambios (agregar, borrar o reemplazar una letra) para
  /// convertir [a] en [b].
  static int distancia(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var anterior = List<int>.generate(b.length + 1, (j) => j);
    for (var i = 1; i <= a.length; i++) {
      final actual = List<int>.filled(b.length + 1, 0);
      actual[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final costo = a[i - 1] == b[j - 1] ? 0 : 1;
        actual[j] = math.min(
          math.min(actual[j - 1] + 1, anterior[j] + 1),
          anterior[j - 1] + costo,
        );
      }
      anterior = actual;
    }
    return anterior[b.length];
  }

  /// Parecido entre dos nombres, de 0 (nada que ver) a 1 (iguales). Compara
  /// los textos normalizados.
  ///
  /// Si los números de los nombres son distintos ("Ácido 1M" y "Ácido 2M")
  /// devuelve 0: son productos distintos aunque el texto se parezca.
  static double entreNombres(String a, String b) {
    if (!mismosNumeros(a, b)) return 0;

    final normalizadoA = normalizar(a);
    final normalizadoB = normalizar(b);
    final largo = math.max(normalizadoA.length, normalizadoB.length);
    if (largo == 0) return 0;

    return 1 - distancia(normalizadoA, normalizadoB) / largo;
  }

  /// Los dos textos tienen los mismos números, en el mismo orden. Dos nombres
  /// con números distintos ("1M" y "2M") son productos distintos.
  static bool mismosNumeros(String a, String b) {
    final numerosA = numerosEn(a);
    final numerosB = numerosEn(b);
    if (numerosA.length != numerosB.length) return false;
    for (var i = 0; i < numerosA.length; i++) {
      if (numerosA[i] != numerosB[i]) return false;
    }
    return true;
  }
}
