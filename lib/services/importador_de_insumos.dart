import '../models/importacion.dart';
import 'category_suggestion_service.dart';
import 'similitud_texto.dart';

/// Interpreta las planillas de Excel del laboratorio y arma la lista de insumos
/// que se pueden cargar (R19: carga inicial desde Excel).
///
/// Las planillas de Jana no tienen un formato único: cada hoja es de un lugar y
/// se arma distinto. Por eso no se espera una plantilla fija, se reconocen las
/// formas que aparecen:
///
/// - **Tabla con encabezado:** una fila con "Nombre" o "Compuesto" y, alrededor,
///   "Código", "Fórmula", "Cantidad", "Otros nombres posibles"... Si el
///   encabezado se repite hacia la derecha (varios cajones lado a lado) o hacia
///   abajo (un encabezado por estante), se leen todos los bloques.
/// - **Título y "Stock":** una columna con el título del grupo ("Agar",
///   "Caldos") seguida de "Stock - Armario 18".
/// - **Lista simple:** una hoja sin encabezado, con el nombre en la primera
///   columna y, a veces, la cantidad en la segunda.
///
/// En cualquiera de las formas, las filas con un solo título ("Estante 1",
/// "CAJON 2", "Armario N°1 - Soluciones") se usan para armar la ubicación de lo
/// que viene debajo.
///
/// Todo es puro (recibe filas ya leídas) para poder probarlo sin archivos.
class ImportadorDeInsumos {
  ImportadorDeInsumos._();

  static const _nombre = {
    'nombre', 'compuesto', 'producto', 'insumo', 'reactivo', 'descripcion',
    'articulo', 'material',
  };
  static const _codigo = {'codigo', 'cod', 'codigointerno'};
  static const _formula = {'formula', 'formulaquimica'};
  static const _aliasCantidad = {'cantidad', 'cant', 'stock', 'existencia'};
  static const _categoria = {'categoria', 'rubro', 'grupo'};
  static const _otros = {
    'otrosnombresposibles', 'otrosnombres', 'sinonimos', 'nombresalternativos',
  };
  static const _ubicacion = {'ubicacion', 'lugar'};

  /// Lee todas las hojas.
  static ResultadoLectura leer(List<HojaPlana> hojas) {
    final insumos = <InsumoImportado>[];
    final avisos = <AvisoImportacion>[];
    final leidas = <String>[];
    final ignoradas = <String>[];

    for (final hoja in hojas) {
      final resultado = _leerHoja(hoja);
      insumos.addAll(resultado.insumos);
      avisos.addAll(resultado.avisos);
      (resultado.insumos.isEmpty ? ignoradas : leidas).add(hoja.nombre);
    }

    return ResultadoLectura(
      insumos: insumos,
      avisos: avisos,
      hojasLeidas: leidas,
      hojasIgnoradas: ignoradas,
    );
  }

  // ---- Una hoja -------------------------------------------------------------

  static ({List<InsumoImportado> insumos, List<AvisoImportacion> avisos})
      _leerHoja(HojaPlana hoja) {
    final insumos = <InsumoImportado>[];
    final avisos = <AvisoImportacion>[];
    final filas = [
      for (final f in hoja.filas) [for (final c in f) c],
    ];

    var bloques = <_Bloque>[];
    final hayEncabezado = filas.any((f) => _bloquesDe(f) != null);
    if (!hayEncabezado) {
      // Lista simple: el nombre en la primera columna, la cantidad en la segunda.
      bloques = [const _Bloque(nombre: 0, cantidad: 1)];
      avisos.add(AvisoImportacion(
        hoja.nombre,
        0,
        'No tiene encabezado: se leyó como lista simple (nombre en la columna A, cantidad en la B)',
      ));
    }

    final contextos = <_Contexto>[];
    final base = _nombreDeHoja(hoja.nombre);
    final controlada = SimilitudTexto.normalizar(hoja.nombre).contains('sedronar');
    var sinCantidad = 0;

    for (var i = 0; i < filas.length; i++) {
      final fila = filas[i];
      final numero = i + 1;
      final celdas = [for (final c in fila) _texto(c)];
      if (celdas.every((c) => c.isEmpty)) continue;

      final nuevos = _bloquesDe(fila);
      if (nuevos != null) {
        bloques = nuevos;
        continue;
      }
      if (_esActualizado(celdas)) continue;

      final contexto = _contextosDe(fila);
      if (contexto != null) {
        final minimo = contexto.map((c) => c.rango).reduce((a, b) => a < b ? a : b);
        contextos.removeWhere((c) => c.rango >= minimo);
        contextos.addAll(contexto);
        continue;
      }
      if (bloques.isEmpty) continue;

      for (final bloque in bloques) {
        final crudo = _celda(celdas, bloque.nombre);
        var nombre = _limpiarNombre(crudo);
        if (!_esNombreValido(nombre)) continue;

        // "Caja 1" entre los insumos: es el lugar de los que siguen.
        final inicio = _sinTildes(nombre.toLowerCase());
        if (_esContexto.hasMatch(inicio)) {
          final rango = _rango(inicio);
          contextos.removeWhere((c) => c.rango >= rango && c.columna == bloque.nombre);
          contextos.add(_Contexto(bloque.nombre, nombre, rango));
          continue;
        }

        // "Etanol absoluto x5": el x5 es la cantidad.
        int? cantidadDelNombre;
        final sufijo = RegExp(r'\s+[xX]\s*(\d+)\s*$').firstMatch(nombre);
        if (sufijo != null) {
          cantidadDelNombre = int.parse(sufijo.group(1)!);
          nombre = nombre.substring(0, sufijo.start).trim();
        }

        final celdaCantidad = bloque.cantidad == null ? null : _celdaCruda(fila, bloque.cantidad!);
        final lectura = _cantidad(celdaCantidad);
        int cantidad;
        if (lectura.cantidad != null) {
          cantidad = lectura.cantidad!;
          if (lectura.aviso != null) {
            avisos.add(AvisoImportacion(hoja.nombre, numero, '"$nombre": ${lectura.aviso}'));
          }
        } else if (cantidadDelNombre != null) {
          cantidad = cantidadDelNombre;
        } else {
          cantidad = 1;
          sinCantidad++;
        }

        final formula = _celda(celdas, bloque.formula);
        final categoria = _categoriaDe(
          bloque: bloque,
          celdas: celdas,
          hoja: hoja.nombre,
          nombre: nombre,
          formula: formula,
        );

        insumos.add(InsumoImportado(
          nombre: nombre,
          cantidad: cantidad,
          ubicacion: _celda(celdas, bloque.ubicacion).isNotEmpty
              ? '$base - ${_celda(celdas, bloque.ubicacion)}'
              : _ubicacionDe(base, contextos, bloque),
          hoja: hoja.nombre,
          fila: numero,
          codigoInterno: _codigoDe(_celdaCruda(fila, bloque.codigo)),
          formula: formula.isEmpty ? null : formula,
          categoria: categoria,
          otrosNombres: _separar(_celda(celdas, bloque.otros)),
          controlado: controlada,
        ));
      }
    }

    if (sinCantidad > 0 && insumos.isNotEmpty) {
      avisos.add(AvisoImportacion(
        hoja.nombre,
        0,
        '$sinCantidad insumo${sinCantidad == 1 ? '' : 's'} sin cantidad: se cargó 1 de cada uno',
      ));
    }
    return (insumos: insumos, avisos: avisos);
  }

  // ---- Encabezados ----------------------------------------------------------

  /// Si [fila] es un encabezado, los bloques de columnas que describe; si no,
  /// null.
  static List<_Bloque>? _bloquesDe(List<Object?> fila) {
    final celdas = [for (final c in fila) _texto(c)];
    final normal = [for (final c in celdas) SimilitudTexto.normalizar(c)];

    var nombres = [
      for (var c = 0; c < normal.length; c++)
        if (_nombre.contains(normal[c])) c,
    ];
    // Un encabezado de verdad no trae números: una fila de datos puede tener un
    // insumo llamado "Material" y no por eso es un encabezado.
    if (nombres.isNotEmpty && fila.any((c) => c is num)) return null;

    String? tituloFijo;
    int? cantidadDeTitulo;
    if (nombres.isEmpty) {
      // "Agar | Stock - Armario 18": el título del grupo y, al lado, el stock.
      for (var c = 1; c < normal.length; c++) {
        if (normal[c].startsWith('stock') &&
            celdas[c - 1].isNotEmpty &&
            fila[c - 1] is! num) {
          nombres = [c - 1];
          tituloFijo = celdas[c - 1].trim();
          cantidadDeTitulo = c;
          break;
        }
      }
    }
    if (nombres.isEmpty) return null;

    final bloques = <_Bloque>[];
    for (var k = 0; k < nombres.length; k++) {
      final n = nombres[k];
      final limite = k + 1 < nombres.length ? nombres[k + 1] : normal.length;

      int? izquierda(Set<String> alias) {
        for (var c = n - 1; c >= 0 && c >= n - 3; c--) {
          if (alias.contains(normal[c])) return c;
        }
        return null;
      }

      int? derecha(Set<String> alias) {
        for (var c = n + 1; c < limite && c <= n + 6; c++) {
          if (alias.contains(normal[c])) return c;
        }
        return null;
      }

      bloques.add(_Bloque(
        nombre: n,
        codigo: izquierda(_codigo),
        formula: derecha(_formula),
        cantidad: cantidadDeTitulo ?? derecha(_aliasCantidad),
        categoria: derecha(_categoria),
        otros: derecha(_otros),
        ubicacion: derecha(_ubicacion),
        tituloFijo: tituloFijo,
      ));
    }
    return bloques;
  }

  // ---- Ubicación ------------------------------------------------------------

  static final _esContexto = RegExp(
    r'^(laboratorio|lab|armario|armarios|heladera|estante|estantes|repisa|'
    r'cajon|cajones|caja|mesada|placard|freezer)\b',
  );

  /// Si [fila] es solo títulos de lugar ("Estante 1", "CAJON 1 ... CAJON 2"),
  /// esos títulos con la columna en la que están; si no, null.
  static List<_Contexto>? _contextosDe(List<Object?> fila) {
    final encontrados = <_Contexto>[];
    for (var c = 0; c < fila.length; c++) {
      final celda = fila[c];
      if (celda == null || _texto(celda).isEmpty) continue;
      // "Actualizado 20/04/2026" puede estar al lado de un título.
      if (SimilitudTexto.normalizar(_texto(celda)).startsWith('actualizado')) continue;
      if (celda is! String) return null;
      final texto = _limpiarNombre(celda);
      final inicio = _sinTildes(texto.toLowerCase());
      if (!_esContexto.hasMatch(inicio)) return null;
      encontrados.add(_Contexto(c, texto, _rango(inicio)));
    }
    return encontrados.isEmpty ? null : encontrados;
  }

  /// Qué tan "arriba" está un lugar: un laboratorio contiene armarios, que
  /// contienen estantes, que contienen cajones.
  static int _rango(String inicio) {
    if (inicio.startsWith('lab')) return 0;
    if (RegExp(r'^(armario|heladera|mesada|placard|freezer)').hasMatch(inicio)) return 1;
    if (RegExp(r'^(estante|repisa)').hasMatch(inicio)) return 2;
    return 3;
  }

  static String _ubicacionDe(String base, List<_Contexto> contextos, _Bloque bloque) {
    final inicio = bloque.codigo != null && bloque.codigo! < bloque.nombre
        ? bloque.codigo!
        : bloque.nombre;

    // De cada nivel, el título más cercano que esté a la izquierda del bloque.
    final porRango = <int, _Contexto>{};
    for (final c in contextos) {
      if (c.columna > inicio) continue;
      final actual = porRango[c.rango];
      if (actual == null || c.columna >= actual.columna) porRango[c.rango] = c;
    }
    final rangos = porRango.keys.toList()..sort();
    final partes = [base, for (final r in rangos) porRango[r]!.texto];
    // Si el título del primer nivel ya repite el nombre de la hoja
    // ("LABORATORIO 404" en la hoja "Laboratorio 404") no se dice dos veces.
    final vistos = <String>{};
    return [
      for (final p in partes)
        if (vistos.add(SimilitudTexto.normalizar(p))) p,
    ].join(' - ');
  }

  static String _nombreDeHoja(String nombre) {
    final limpio = nombre.trim();
    if (RegExp(r'^\d{1,4}$').hasMatch(limpio)) return 'Laboratorio $limpio';
    return limpio;
  }

  // ---- Categoría ------------------------------------------------------------

  static String? _categoriaDe({
    required _Bloque bloque,
    required List<String> celdas,
    required String hoja,
    required String nombre,
    required String formula,
  }) {
    final propia = _celda(celdas, bloque.categoria);
    if (propia.isNotEmpty) return propia;
    if (bloque.tituloFijo != null && bloque.tituloFijo!.isNotEmpty) {
      return bloque.tituloFijo;
    }

    final hojaNormal = SimilitudTexto.normalizar(hoja);
    if (hojaNormal.contains('alcohol')) return 'Alcoholes y solventes';
    if (hojaNormal.contains('inorganic')) return 'Inorgánicos';
    if (hojaNormal.contains('organic')) return 'Orgánicos';

    return CategorySuggestionService.sugerir(
      nombre,
      formula: formula.isEmpty ? null : formula,
    )?.categoria;
  }

  // ---- Cantidad -------------------------------------------------------------

  /// Qué stock dice una celda. `cantidad` es null si la celda está vacía.
  static ({int? cantidad, String? aviso}) _cantidad(Object? valor) {
    if (valor == null) return (cantidad: null, aviso: null);

    if (valor is num) {
      if (valor < 0) return (cantidad: 0, aviso: 'cantidad negativa ($valor): se cargó 0');
      if (valor != valor.roundToDouble()) {
        return (cantidad: valor.round(), aviso: 'cantidad con decimales ($valor): se redondeó');
      }
      return (cantidad: valor.toInt(), aviso: null);
    }

    final texto = _texto(valor);
    if (texto.isEmpty) return (cantidad: null, aviso: null);

    final normal = _sinTildes(texto.toLowerCase());
    if (RegExp(r'\bno hay\b|\bagotado\b|\bsin stock\b').hasMatch(normal)) {
      return (cantidad: 0, aviso: null);
    }
    final numero = RegExp(r'\d+').firstMatch(normal);
    if (numero != null) {
      return (cantidad: int.parse(numero.group(0)!), aviso: null);
    }
    if (normal.contains('solo en')) {
      return (cantidad: 0, aviso: 'dice "$texto": se cargó 0');
    }
    return (cantidad: 1, aviso: 'no se entendió la cantidad "$texto": se cargó 1');
  }

  // ---- Piezas ---------------------------------------------------------------

  static bool _esActualizado(List<String> celdas) =>
      celdas.where((c) => c.isNotEmpty).length == 1 &&
      SimilitudTexto.normalizar(celdas.firstWhere((c) => c.isNotEmpty))
          .startsWith('actualizado');

  static bool _esNombreValido(String nombre) {
    if (nombre.length < 2) return false;
    if (!RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]').hasMatch(nombre)) return false;
    // Los encabezados ya se reconocen aparte; un insumo puede llamarse "Material".
    return !SimilitudTexto.normalizar(nombre).startsWith('actualizado');
  }

  static String _limpiarNombre(String texto) =>
      texto.trim().replaceAll(RegExp(r'\s+'), ' ');

  static String _texto(Object? valor) {
    if (valor == null) return '';
    if (valor is String) return valor.trim();
    if (valor is num) {
      return valor == valor.roundToDouble() ? valor.toInt().toString() : valor.toString();
    }
    return valor.toString().trim();
  }

  static String _celda(List<String> celdas, int? columna) =>
      columna == null || columna >= celdas.length ? '' : celdas[columna];

  static Object? _celdaCruda(List<Object?> fila, int? columna) {
    if (columna == null || columna >= fila.length) return null;
    final valor = fila[columna];
    if (valor is String && valor.trim().isEmpty) return null;
    return valor;
  }

  /// El código tal como se ve: un número entero sin ".0" y, si Excel lo tomó por
  /// una fecha ("01-02" pasó a ser el 1 de febrero), de vuelta a día-mes.
  static String? _codigoDe(Object? valor) {
    if (valor == null) return null;
    if (valor is DateTime) {
      final dia = valor.day.toString().padLeft(2, '0');
      final mes = valor.month.toString().padLeft(2, '0');
      return '$dia-$mes';
    }
    final texto = _texto(valor);
    return texto.isEmpty ? null : texto;
  }

  static List<String> _separar(String texto) {
    final vistos = <String>{};
    return [
      for (final parte in texto.split(RegExp(r'[,;/]')))
        if (parte.trim().isNotEmpty && vistos.add(parte.trim().toLowerCase()))
          _limpiarNombre(parte),
    ];
  }

  static String _sinTildes(String texto) {
    const mapa = {
      'á': 'a', 'à': 'a', 'é': 'e', 'è': 'e', 'í': 'i', 'ì': 'i',
      'ó': 'o', 'ò': 'o', 'ú': 'u', 'ù': 'u', 'ü': 'u', 'ñ': 'n',
    };
    return texto.split('').map((c) => mapa[c] ?? c).join();
  }
}

/// Dónde están, dentro de una fila de encabezado, las columnas de un insumo.
class _Bloque {
  const _Bloque({
    required this.nombre,
    this.codigo,
    this.formula,
    this.cantidad,
    this.categoria,
    this.otros,
    this.ubicacion,
    this.tituloFijo,
  });

  final int nombre;
  final int? codigo;
  final int? formula;
  final int? cantidad;
  final int? categoria;
  final int? otros;
  final int? ubicacion;

  /// El título del grupo cuando el encabezado es "Agar | Stock - ...".
  final String? tituloFijo;
}

/// Un título de lugar ("Estante 1") y en qué columna aparece.
class _Contexto {
  const _Contexto(this.columna, this.texto, this.rango);

  final int columna;
  final String texto;
  final int rango;
}
