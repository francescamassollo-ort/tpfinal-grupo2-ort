import 'dart:convert';

import '../models/insumo.dart';
import '../models/sugerencia_categoria.dart';
import 'modelo_de_lenguaje.dart';
import 'similitud_texto.dart';

/// Sugiere la categoría de un insumo nuevo a partir de su nombre (y, si se la
/// conoce, su fórmula). Busca en capas y se queda con la primera que sabe:
///
/// 1. **Insumos parecidos** ([sugerir]): si ya hay un insumo con un nombre
///    parecido y con categoría, se usa la suya. Así se respetan las categorías
///    que el laboratorio ya usa y no se inventan nombres distintos para lo mismo.
/// 2. **Reglas** ([sugerir]): palabras del nombre ("guante", "etanol", "agar") y
///    formas de la fórmula ("...COOH" es un ácido). Sin internet.
/// 3. **IA** ([sugerirConIa]), solo cuando se la pide: se le manda el nombre y
///    la lista de categorías existentes y elige una o propone una nueva.
///
/// Las capas 1 y 2 son instantáneas y no gastan nada, por eso se pueden
/// calcular mientras se escribe. La 3 gasta cuota del modelo y manda el nombre a
/// un servicio externo, por eso va aparte.
class CategorySuggestionService {
  CategorySuggestionService([this._modelo]);

  final ModeloDeLenguaje? _modelo;

  /// Desde este parecido entre nombres (de 0 a 1) se toma la categoría de un
  /// insumo existente.
  static const double umbralParecido = 0.8;

  /// Hay un modelo configurado para [sugerirConIa].
  bool get tieneIa => _modelo != null;

  static const double confianzaReglas = 0.7;
  static const double confianzaFormula = 0.6;
  static const double confianzaIa = 0.6;

  /// Las capas 1 y 2. Devuelve null si ninguna sabe.
  static SugerenciaCategoria? sugerir(
    String nombre, {
    String? formula,
    Iterable<Insumo> insumos = const [],
  }) {
    final consulta = SimilitudTexto.normalizar(nombre);
    if (consulta.length < 3) return null;

    final deInsumos = _deInsumosParecidos(consulta, nombre, insumos);
    if (deInsumos != null) return deInsumos;

    final porNombre = _porReglasDeNombre(consulta);
    final porFormula = porNombre == null ? _porFormula(formula) : null;
    final canonica = porNombre ?? porFormula;
    if (canonica == null) return null;

    return SugerenciaCategoria(
      categoria: _conLaGrafiaExistente(
        canonica,
        [for (final i in insumos) i.categoria],
      ),
      confianza: porNombre != null ? confianzaReglas : confianzaFormula,
      origen: OrigenSugerencia.reglas,
    );
  }

  /// La capa 3: le pregunta al modelo. Lanza una [ModeloDeLenguajeException] si
  /// falla o si no hay modelo configurado. Solo se le manda el nombre, la
  /// fórmula y los nombres de las categorías existentes.
  Future<SugerenciaCategoria?> sugerirConIa(
    String nombre, {
    String? formula,
    Iterable<String> categoriasExistentes = const [],
  }) async {
    final modelo = _modelo;
    if (modelo == null) {
      throw const ModeloDeLenguajeException(
        'No hay un modelo de lenguaje configurado',
      );
    }

    final existentes = _unicas(categoriasExistentes);
    final respuesta = await modelo.responder(
      instrucciones: instruccionesIa,
      consulta: _armarConsulta(nombre, formula, existentes),
    );

    final categoria = _leerCategoria(respuesta);
    if (categoria == null) return null;

    return SugerenciaCategoria(
      categoria: _conLaGrafiaExistente(categoria, existentes),
      confianza: confianzaIa,
      origen: OrigenSugerencia.ia,
    );
  }

  static const String instruccionesIa =
      'Sos un asistente de un laboratorio de biotecnologia. Recibis el nombre '
      'de un insumo y, si se conoce, su formula, y la lista de categorias que '
      'el laboratorio ya usa. Devolve SOLO un JSON con la forma '
      '{"categoria": "Nombre de la categoria"}. Elegi una de las categorias '
      'existentes si alguna sirve; si ninguna sirve, propone una nueva, corta, '
      'en espanol, en plural y con la primera letra en mayuscula (por ejemplo '
      '"Enzimas" o "Material descartable"). Si no podes decidir, devolve '
      '{"categoria": ""}.';

  static String _armarConsulta(
    String nombre,
    String? formula,
    List<String> existentes,
  ) {
    return [
      'Insumo: ${nombre.trim()}',
      if (formula != null && formula.trim().isNotEmpty)
        'Formula: ${formula.trim()}',
      'Categorias existentes: ${existentes.isEmpty ? '(ninguna)' : existentes.join(', ')}',
    ].join('\n');
  }

  static String? _leerCategoria(String respuesta) {
    try {
      final inicio = respuesta.indexOf('{');
      final fin = respuesta.lastIndexOf('}');
      final json = jsonDecode(respuesta.substring(inicio, fin + 1)) as Map;
      final categoria = (json['categoria'] as String?)?.trim() ?? '';
      // Un nombre vacío o larguísimo no es una categoría: el modelo no supo.
      if (categoria.isEmpty || categoria.length > 40) return null;
      return categoria;
    } catch (_) {
      throw const ModeloDeLenguajeException(
        'La respuesta de la IA no tiene el formato esperado',
      );
    }
  }

  // ---- Capa 1: insumos parecidos -------------------------------------------

  static SugerenciaCategoria? _deInsumosParecidos(
    String consulta,
    String nombre,
    Iterable<Insumo> insumos,
  ) {
    // Para cada categoría, el mejor parecido y cuántos insumos la aportan.
    final puntaje = <String, double>{};
    final cuantos = <String, int>{};

    for (final insumo in insumos) {
      final categoria = insumo.categoria?.trim() ?? '';
      if (categoria.isEmpty) continue;

      final propio = SimilitudTexto.normalizar(insumo.nombre);
      if (propio.isEmpty) continue;

      final contiene = propio.contains(consulta) || consulta.contains(propio);
      final parecido = contiene
          ? 0.9
          : SimilitudTexto.entreNombres(nombre, insumo.nombre);
      if (parecido < umbralParecido) continue;

      puntaje.update(categoria, (p) => parecido > p ? parecido : p,
          ifAbsent: () => parecido);
      cuantos.update(categoria, (n) => n + 1, ifAbsent: () => 1);
    }
    if (puntaje.isEmpty) return null;

    // Gana la categoría con mejor parecido; si empatan, la que más insumos
    // parecidos tiene.
    final categorias = puntaje.keys.toList()
      ..sort((a, b) {
        final porPuntaje = puntaje[b]!.compareTo(puntaje[a]!);
        return porPuntaje != 0 ? porPuntaje : cuantos[b]!.compareTo(cuantos[a]!);
      });
    final elegida = categorias.first;

    return SugerenciaCategoria(
      categoria: elegida,
      confianza: puntaje[elegida]!,
      origen: OrigenSugerencia.insumoParecido,
    );
  }

  // ---- Capa 2: reglas ------------------------------------------------------

  // Cada categoría con las palabras que la delatan. Las palabras van sin tildes,
  // en minúscula y sin espacios (como las deja SimilitudTexto.normalizar), y
  // alcanza con que el nombre las contenga. El orden importa: gana la primera
  // categoría que coincide, por eso las más específicas van antes ("Buffer para
  // Taq" es un buffer, no una enzima).
  static const List<(String, List<String>)> _reglas = [
    (
      'Buffers y soluciones',
      ['buffer', 'tampon', 'tris', 'pbs', 'edta', 'solucion'],
    ),
    (
      'Enzimas',
      [
        'enzima', 'polimerasa', 'taq', 'ligasa', 'nucleasa', 'proteinasa',
        'lipasa', 'amilasa', 'tripsina', 'transcriptasa', 'helicasa',
        'endonucleasa', 'dnasa', 'rnasa', 'lisozima', 'catalasa', 'celulasa',
      ],
    ),
    (
      'Medios de cultivo',
      [
        'agar', 'caldo', 'peptona', 'levadura', 'mediodecultivo', 'mueller',
        'sabouraud', 'macconkey',
      ],
    ),
    (
      'Colorantes',
      [
        'colorante', 'tincion', 'azuldemetileno', 'cristalvioleta',
        'safranina', 'eosina', 'hematoxilina', 'giemsa', 'etidio',
      ],
    ),
    (
      'Alcoholes y solventes',
      [
        'etanol', 'metanol', 'isopropanol', 'propanol', 'butanol', 'acetona',
        'alcohol', 'glicerol', 'glicerina', 'cloroformo', 'hexano', 'tolueno',
        'xilol', 'dmso', 'acetonitrilo', 'acetatodeetilo',
      ],
    ),
    (
      'Ácidos y bases',
      [
        'acido', 'hidroxido', 'amoniaco', 'clorhidrico', 'sulfurico',
        'nitrico', 'fosforico', 'naoh', 'koh',
      ],
    ),
    (
      'Sales',
      [
        'cloruro', 'sulfato', 'nitrato', 'fosfato', 'carbonato', 'bicarbonato',
        'acetato', 'citrato',
      ],
    ),
    (
      'Metales',
      ['aluminio', 'cobre', 'zinc', 'hierro', 'magnesio', 'platino'],
    ),
    (
      'Material de vidrio',
      [
        'probeta', 'erlenmeyer', 'matraz', 'vasodeprecipitado', 'tubodeensayo',
        'portaobjeto', 'cubreobjeto', 'balon', 'embudo', 'mortero', 'petri',
        'varilla', 'kitasato', 'cristalizador', 'bureta', 'pipeta',
      ],
    ),
    (
      'Material descartable',
      [
        'guante', 'barbijo', 'cofia', 'descartable', 'jeringa', 'punta',
        'gasa', 'algodon', 'papelfiltro', 'microtubo', 'eppendorf', 'falcon',
        'criovial', 'parafilm', 'barbijos', 'tips',
      ],
    ),
  ];

  static String? _porReglasDeNombre(String consulta) {
    for (final (categoria, palabras) in _reglas) {
      for (final palabra in palabras) {
        if (consulta.contains(palabra)) return categoria;
      }
    }
    return null;
  }

  // La forma de la fórmula también dice algo: "...COOH" es un ácido orgánico,
  // "NaOH" una base, "C2H5OH" un alcohol, "H2SO4" un ácido.
  static String? _porFormula(String? formula) {
    final f = formula?.replaceAll(RegExp(r'\s'), '') ?? '';
    if (f.length < 2) return null;

    if (f.contains('COOH')) return 'Ácidos y bases';
    if (RegExp(r'^[A-Z][a-z]?OH$').hasMatch(f)) return 'Ácidos y bases';
    if (RegExp(r'^H\d?(Cl|Br|F|NO3|SO4|PO4|ClO4)').hasMatch(f)) {
      return 'Ácidos y bases';
    }
    if (f.startsWith('C') && f.endsWith('OH')) return 'Alcoholes y solventes';
    return null;
  }

  // ---- Auxiliares -----------------------------------------------------------

  // Si el laboratorio ya tiene esa categoría escrita de otra forma ("Enzima",
  // "enzimas"), se usa esa grafía en vez de crear una nueva casi igual.
  static String _conLaGrafiaExistente(
    String categoria,
    Iterable<String?> existentes,
  ) {
    final buscada = _sinPlural(SimilitudTexto.normalizar(categoria));
    for (final existente in existentes) {
      final texto = existente?.trim() ?? '';
      if (texto.isNotEmpty &&
          _sinPlural(SimilitudTexto.normalizar(texto)) == buscada) {
        return texto;
      }
    }
    return categoria;
  }

  static String _sinPlural(String texto) =>
      texto.length > 3 && texto.endsWith('s')
          ? texto.substring(0, texto.length - 1)
          : texto;

  // Las categorías sin repetir (sin mirar mayúsculas), en orden alfabético.
  static List<String> _unicas(Iterable<String> categorias) {
    final vistas = <String, String>{};
    for (final categoria in categorias) {
      final texto = categoria.trim();
      if (texto.isNotEmpty) {
        vistas.putIfAbsent(SimilitudTexto.normalizar(texto), () => texto);
      }
    }
    return vistas.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }
}
