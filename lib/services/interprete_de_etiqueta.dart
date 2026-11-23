import '../models/etiqueta_leida.dart';

/// Entiende el texto que se reconoció en la foto de una etiqueta y saca de ahí
/// lo que sirve para completar el Alta: nombre, fórmula, peso molecular, fecha de
/// vencimiento y número CAS.
///
/// Es puro (no usa la cámara ni internet), por eso se prueba con textos de
/// ejemplo. El reconocimiento de texto se equivoca y las etiquetas no siguen un
/// formato, así que esto es una heurística: prefiere **no completar** un dato a
/// completarlo mal. Lo que devuelve es una sugerencia que la persona revisa.
class InterpreteDeEtiqueta {
  InterpreteDeEtiqueta._();

  static EtiquetaLeida interpretar(String texto) {
    final lineas = [
      for (final linea in texto.split(RegExp(r'[\r\n]+')))
        if (linea.trim().isNotEmpty) linea.trim(),
    ];

    return EtiquetaLeida(
      nombre: _nombre(lineas),
      marca: _etiquetado(lineas, _clavesMarca),
      formula: _formula(lineas),
      pesoMolecular: _pesoMolecular(texto),
      fechaVencimiento: _fechaDeVencimiento(lineas),
      cas: _cas(texto),
      texto: texto,
    );
  }

  // ---- CAS -----------------------------------------------------------------

  /// El primer número CAS válido del texto, o null. Se valida el dígito de
  /// control: así una fecha o un lote parecido ("2026-11-1") no se confunde.
  static String? _cas(String texto) {
    for (final m in RegExp(r'(?<!\d)(\d{2,7})-(\d{2})-(\d)(?!\d)').allMatches(texto)) {
      final cas = m.group(0)!;
      if (esCasValido(cas)) return cas;
    }
    return null;
  }

  /// Un número CAS es válido si su último dígito es el de control: se multiplica
  /// cada dígito anterior por su posición contando desde la derecha (1, 2, 3…),
  /// se suma, y el resto de dividir por 10 tiene que ser ese dígito.
  static bool esCasValido(String cas) {
    final m = RegExp(r'^(\d{2,7})-(\d{2})-(\d)$').firstMatch(cas);
    if (m == null) return false;

    final digitos = '${m.group(1)}${m.group(2)}';
    var suma = 0;
    for (var i = 0; i < digitos.length; i++) {
      final desdeLaDerecha = digitos.length - i;
      suma += int.parse(digitos[i]) * desdeLaDerecha;
    }
    return suma % 10 == int.parse(m.group(3)!);
  }

  // ---- Peso molecular ------------------------------------------------------

  static double? _pesoMolecular(String texto) {
    final patrones = [
      // "Peso molecular: 46,07", "M.W. 46.07", "Mol. Wt.: 58.44", "PM 46,07"
      RegExp(
        r'(?:peso\s*molecular|masa\s*molar|mol(?:ecular)?\.?\s*w(?:eigh)?t\.?|'
        r'formula\s*weight|\bm\.?\s*w\.?|\bp\.?\s*m\.?)\s*[:=]?\s*(\d+(?:[.,]\d+)?)',
        caseSensitive: false,
      ),
      // "46,07 g/mol"
      RegExp(r'(\d+(?:[.,]\d+)?)\s*g\s*/\s*mol', caseSensitive: false),
    ];

    for (final patron in patrones) {
      for (final m in patron.allMatches(texto)) {
        final peso = double.tryParse(m.group(1)!.replaceAll(',', '.'));
        // Una masa molecular razonable: de 1 (hidrógeno) a un millón (enzimas).
        if (peso != null && peso >= 1 && peso <= 1000000) return peso;
      }
    }
    return null;
  }

  // ---- Fórmula -------------------------------------------------------------

  // Con una etiqueta "Fórmula:", se acepta cualquier fórmula válida. Sin
  // etiqueta, solo las que tienen algún número ("H2O", "CH3COOH") o están en la
  // lista de las comunes sin número: si no, palabras como "CON" o "SON" (C+O+N,
  // S+O+N) pasarían por fórmulas.
  static const _sinNumero = {
    'NaCl', 'KCl', 'HCl', 'HBr', 'LiCl', 'CaO', 'MgO', 'ZnO', 'NaF', 'KI',
    'NaI', 'NaOH', 'KOH', 'CuO',
  };

  static String? _formula(List<String> lineas) {
    final conEtiqueta = RegExp(
      r'(?:f[oó]rmula(?:\s*molecular|\s*qu[ií]mica)?|mol(?:ecular)?\.?\s*formula)\s*[:=]?\s*([A-Za-z0-9()·.]+)',
      caseSensitive: false,
    );
    for (final linea in lineas) {
      final m = conEtiqueta.firstMatch(linea);
      final candidata = m?.group(1);
      if (candidata != null && esFormulaQuimica(candidata)) return candidata;
    }

    for (final linea in lineas) {
      for (final palabra in linea.split(RegExp(r'[\s,;:/]+'))) {
        if (!esFormulaQuimica(palabra)) continue;
        if (RegExp(r'\d').hasMatch(palabra) || _sinNumero.contains(palabra)) {
          return palabra;
        }
      }
    }
    return null;
  }

  static const _elementos = {
    'H', 'He', 'Li', 'Be', 'B', 'C', 'N', 'O', 'F', 'Ne', 'Na', 'Mg', 'Al',
    'Si', 'P', 'S', 'Cl', 'Ar', 'K', 'Ca', 'Sc', 'Ti', 'V', 'Cr', 'Mn', 'Fe',
    'Co', 'Ni', 'Cu', 'Zn', 'Ga', 'Ge', 'As', 'Se', 'Br', 'Kr', 'Rb', 'Sr',
    'Y', 'Zr', 'Nb', 'Mo', 'Ag', 'Cd', 'In', 'Sn', 'Sb', 'Te', 'I', 'Xe', 'Cs',
    'Ba', 'La', 'Ce', 'W', 'Pt', 'Au', 'Hg', 'Pb', 'Bi', 'U',
  };

  /// Si [texto] tiene forma de fórmula química: elementos reales, con su
  /// cantidad, y paréntesis balanceados ("C2H6O", "Ca(OH)2", "H2SO4"). No dice
  /// si existe esa sustancia.
  static bool esFormulaQuimica(String texto) {
    var t = texto.replaceAll('·', '.').trim();
    // Se saca la puntuación de los bordes ("C2H6O." al final de una frase).
    t = t.replaceAll(RegExp(r'^[.,;:]+|[.,;:]+$'), '');
    if (t.length < 2 || !RegExp(r'^[A-Z(]').hasMatch(t)) return false;
    if (!RegExp(r'^[A-Za-z0-9().]+$').hasMatch(t)) return false;

    // Paréntesis balanceados.
    var profundidad = 0;
    for (final c in t.split('')) {
      if (c == '(') profundidad++;
      if (c == ')') profundidad--;
      if (profundidad < 0) return false;
    }
    if (profundidad != 0) return false;

    // Cada elemento tiene que existir ("Xx" o una palabra cualquiera no sirve).
    final elementos = RegExp(r'[A-Z][a-z]?').allMatches(t).toList();
    if (elementos.isEmpty) return false;
    // Todas las letras tienen que pertenecer a algún elemento.
    final letras = t.replaceAll(RegExp(r'[^A-Za-z]'), '').length;
    final cubiertas = elementos.fold<int>(0, (n, m) => n + m.group(0)!.length);
    if (cubiertas != letras) return false;

    return elementos.every((m) => _elementos.contains(m.group(0)));
  }

  // ---- Fecha de vencimiento ------------------------------------------------

  // Las palabras que anuncian una fecha de vencimiento.
  static final _anuncioVencimiento = RegExp(
    r'(?:fecha\s*de\s*)?(?:vencimiento|vence|venc\.?|vto\.?|caducidad|caduca|'
    r'v[aá]lido\s*hasta|expir(?:y|ation|a|ación)?(?:\s*date)?|exp\.?(?:\s*date)?|'
    r'best\s*before|use\s*by|use\s*before|bbe?)',
    caseSensitive: false,
  );

  static const _meses = {
    'ene': 1, 'jan': 1, 'feb': 2, 'mar': 3, 'abr': 4, 'apr': 4, 'may': 5,
    'jun': 6, 'jul': 7, 'ago': 8, 'aug': 8, 'sep': 9, 'set': 9, 'oct': 10,
    'nov': 11, 'dic': 12, 'dec': 12,
  };

  static DateTime? _fechaDeVencimiento(List<String> lineas) {
    for (var i = 0; i < lineas.length; i++) {
      final anuncio = _anuncioVencimiento.firstMatch(lineas[i]);
      if (anuncio == null) continue;

      // Primero lo que sigue a la palabra en la misma línea; si no hay fecha, la
      // línea de abajo ("Vencimiento:" y, abajo, "12/2027").
      final resto = lineas[i].substring(anuncio.end);
      final fecha = fechaEn(resto) ??
          (i + 1 < lineas.length ? fechaEn(lineas[i + 1]) : null);
      if (fecha != null) return fecha;
    }
    return null;
  }

  /// La primera fecha que aparece en [texto], o null. Entiende "15/03/2027",
  /// "15-03-27", "15.03.2027", "03/2027" (el último día de ese mes),
  /// "2027-03-15", "15 NOV 2026" y "NOV 2026". Con día y mes ambiguos
  /// ("03/04/2027") se toma día/mes, como en Argentina.
  static DateTime? fechaEn(String texto) {
    // 2027-03-15 o 2027/03/15
    var m = RegExp(r'(?<!\d)(20\d{2})[-/.](\d{1,2})[-/.](\d{1,2})(?!\d)').firstMatch(texto);
    if (m != null) {
      return _valida(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
    }

    // 15/03/2027, 15-03-27, 15.03.2027
    m = RegExp(r'(?<!\d)(\d{1,2})[-/.](\d{1,2})[-/.](\d{4}|\d{2})(?!\d)').firstMatch(texto);
    if (m != null) {
      var a = int.parse(m.group(1)!);
      var b = int.parse(m.group(2)!);
      // Si el segundo número no puede ser un mes pero el primero sí, está
      // escrito mes/día (a la americana).
      if (b > 12 && a <= 12) {
        final intercambio = a;
        a = b;
        b = intercambio;
      }
      return _valida(_anio(m.group(3)!), b, a);
    }

    // 15 NOV 2026, 15-NOV-2026, 15 noviembre 2026
    m = RegExp(r'(?<!\d)(\d{1,2})[\s.\-/]*([A-Za-zÁÉÍÓÚáéíóú]{3,10})[\s.\-/]*(\d{4}|\d{2})(?!\d)')
        .firstMatch(texto);
    if (m != null) {
      final mes = _mesPorNombre(m.group(2)!);
      if (mes != null) {
        return _valida(_anio(m.group(3)!), mes, int.parse(m.group(1)!));
      }
    }

    // NOV 2026, noviembre 2026, NOV/26
    m = RegExp(r'(?<![A-Za-z])([A-Za-zÁÉÍÓÚáéíóú]{3,10})[\s.\-/]*(\d{4}|\d{2})(?!\d)')
        .firstMatch(texto);
    if (m != null) {
      final mes = _mesPorNombre(m.group(1)!);
      if (mes != null) return _finDeMes(_anio(m.group(2)!), mes);
    }

    // 03/2027, 03-2027, 03.27
    m = RegExp(r'(?<!\d)(\d{1,2})[-/.](\d{4}|\d{2})(?!\d)').firstMatch(texto);
    if (m != null) {
      final mes = int.parse(m.group(1)!);
      if (mes >= 1 && mes <= 12) return _finDeMes(_anio(m.group(2)!), mes);
    }

    return null;
  }

  static int? _mesPorNombre(String nombre) {
    final inicio = nombre
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    return inicio.length < 3 ? null : _meses[inicio.substring(0, 3)];
  }

  static int _anio(String texto) {
    final n = int.parse(texto);
    return texto.length == 2 ? 2000 + n : n;
  }

  static DateTime? _valida(int anio, int mes, int dia) {
    if (anio < 2000 || anio > 2100 || mes < 1 || mes > 12 || dia < 1) return null;
    final ultimo = DateTime(anio, mes + 1, 0).day;
    if (dia > ultimo) return null;
    return DateTime(anio, mes, dia);
  }

  static DateTime? _finDeMes(int anio, int mes) {
    if (anio < 2000 || anio > 2100) return null;
    return DateTime(anio, mes + 1, 0);
  }

  // ---- Nombre y marca ------------------------------------------------------

  static final _clavesNombre = RegExp(
    r'^(?:nombre|producto|product(?:\s*name)?|name|reactivo)\s*[:=]\s*(.+)$',
    caseSensitive: false,
  );
  static final _clavesMarca = RegExp(
    r'^(?:marca|brand|fabricante|manufacturer|elaborado\s*por)\s*[:=]\s*(.+)$',
    caseSensitive: false,
  );

  // Líneas que no son el nombre del producto: datos de la etiqueta.
  static final _noEsNombre = RegExp(
    r'\b(?:lote|lot|batch|cas|f[oó]rmula|formula|peso|mw|m\.w|mol\.?|venc|vence|'
    r'vto|exp|elab|fab|mfg|contenido|net|neto|vol|volumen|pureza|purity|assay|'
    r'fabricado|elaborado|almacenar|store|temperatura|www|tel|hecho|made|'
    r'industria|importado|precauci[oó]n|peligro|warning|danger|caducidad|'
    r'best\s*before|use\s*by)\b|@|https?:|\.com',
    caseSensitive: false,
  );

  static String? _nombre(List<String> lineas) {
    final etiquetado = _etiquetado(lineas, _clavesNombre);
    if (etiquetado != null) return _presentar(etiquetado);

    for (final linea in lineas) {
      if (_noEsNombre.hasMatch(linea)) continue;
      final letras = RegExp(r'[A-Za-zÁÉÍÓÚáéíóúÑñ]').allMatches(linea).length;
      // Con pocas letras o más números que letras no es un nombre.
      if (letras < 3) continue;
      final digitos = RegExp(r'\d').allMatches(linea).length;
      if (digitos > letras) continue;
      return _presentar(linea);
    }
    return null;
  }

  static String? _etiquetado(List<String> lineas, RegExp clave) {
    for (final linea in lineas) {
      final valor = clave.firstMatch(linea)?.group(1)?.trim();
      if (valor != null && valor.isNotEmpty) return _presentar(valor);
    }
    return null;
  }

  // "ETANOL ABSOLUTO" -> "Etanol absoluto". Si ya tiene minúsculas se deja como
  // viene.
  static String _presentar(String texto) {
    final t = texto.trim();
    if (t != t.toUpperCase() || t == t.toLowerCase()) return t;
    return t[0] + t.substring(1).toLowerCase();
  }
}
