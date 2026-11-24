import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/importacion.dart';
import 'similitud_texto.dart';

/// Una columna de la plantilla de importación.
class ColumnaPlantilla {
  const ColumnaPlantilla(
    this.titulo,
    this.ayuda, {
    this.aliases = const [],
    this.obligatoria = false,
  });

  /// Lo que dice el encabezado en el Excel.
  final String titulo;

  /// Qué va en la columna (sale en la hoja de instrucciones).
  final String ayuda;

  /// Otros títulos que también se reconocen, ya normalizados (sin tildes ni
  /// espacios).
  final List<String> aliases;
  final bool obligatoria;

  Set<String> get _claves => {SimilitudTexto.normalizar(titulo), ...aliases};
}

/// La plantilla de Excel para cargar insumos de a muchos (R19): se descarga de
/// la app, se completa y se vuelve a subir. Tiene un formato fijo, igual para
/// todos, y se lee con reglas claras: lo que está mal se avisa fila por fila.
///
/// El archivo tiene la hoja **Insumos** (una fila por insumo), una hoja de
/// **Instrucciones** y una de **Ubicaciones** con las que ya existen.
class PlantillaDeInsumos {
  PlantillaDeInsumos._();

  static const String hojaInsumos = 'Insumos';

  static const List<ColumnaPlantilla> columnas = [
    ColumnaPlantilla(
      'Nombre',
      'El nombre del insumo. Obligatorio.',
      obligatoria: true,
    ),
    ColumnaPlantilla(
      'Ubicación',
      'Dónde está guardado, por ejemplo "Laboratorio 404 - Armario 1 - Estante A". '
          'Usá el mismo texto para el mismo lugar (mirá la hoja Ubicaciones). Obligatoria.',
      aliases: ['lugar'],
      obligatoria: true,
    ),
    ColumnaPlantilla(
      'Cantidad',
      'Cuántas unidades hay, un número entero. Si no hay, poné 0. Obligatoria.',
      aliases: ['stock', 'cant'],
      obligatoria: true,
    ),
    ColumnaPlantilla(
      'Stock mínimo',
      'Desde cuántas unidades se avisa que hay que reponer. Si lo dejás vacío, se usa 1.',
      aliases: ['minimo', 'umbral', 'umbralminimo'],
    ),
    ColumnaPlantilla('Unidad', 'En qué se mide: ml, g, kg, unidades…'),
    ColumnaPlantilla(
      'Categoría',
      'Por ejemplo "Ácidos y bases" o "Medios de cultivo". Si la dejás vacía, la app sugiere una.',
    ),
    ColumnaPlantilla(
      'Código interno',
      'El código que el laboratorio le puso (Al-01, S2…). No es el código de barras.',
      aliases: ['codigo', 'cod'],
    ),
    ColumnaPlantilla('Fórmula', 'La fórmula química, si tiene.', aliases: ['formulaquimica']),
    ColumnaPlantilla(
      'Peso molecular',
      'En g/mol, un número mayor a 0 (con coma o punto).',
      aliases: ['pm'],
    ),
    ColumnaPlantilla('Marca', 'La marca del producto, si la sabés.'),
    ColumnaPlantilla(
      'Otros nombres',
      'Otros nombres con los que se conoce, separados por coma.',
      aliases: ['sinonimos'],
    ),
    ColumnaPlantilla(
      'Sedronar',
      '"Sí" si es una sustancia controlada por la Sedronar. Vacío o "No" si no.',
      aliases: ['controlado', 'sustanciacontrolada'],
    ),
  ];

  // ---- Armar la plantilla -----------------------------------------------------

  /// El archivo de Excel de la plantilla. [ubicaciones] son las que ya existen:
  /// van en una hoja aparte para copiar el texto tal cual.
  static Uint8List generar({Iterable<String> ubicaciones = const []}) {
    final libro = Excel.createExcel();
    libro.rename('Sheet1', hojaInsumos);

    final insumos = libro[hojaInsumos];
    final negrita = CellStyle(bold: true);
    for (var c = 0; c < columnas.length; c++) {
      final celda = insumos.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
      celda.value = TextCellValue(columnas[c].titulo);
      celda.cellStyle = negrita;
      insumos.setColumnWidth(c, 22);
    }
    insumos.setColumnWidth(1, 42);

    final instrucciones = libro['Instrucciones'];
    instrucciones.setColumnWidth(0, 22);
    instrucciones.setColumnWidth(1, 100);
    for (final linea in [
      'Cómo completar la plantilla',
      '1. En la hoja "Insumos" escribí un insumo por fila, debajo de los títulos. No cambies los títulos de las columnas.',
      '2. Las columnas Nombre, Ubicación y Cantidad son obligatorias; el resto se puede dejar vacío.',
      '3. Si una fila tiene un error, la app te dice cuál y por qué, y esa fila no se carga; las demás sí.',
      '4. Después de completarla, en la app: menú, Importar desde Excel, Elegir archivo.',
      '5. Si subís el mismo archivo dos veces, los insumos que ya están cargados (mismo nombre y misma ubicación) se saltan.',
    ]) {
      instrucciones.appendRow([TextCellValue(linea)]);
    }
    instrucciones.appendRow([TextCellValue('')]);
    instrucciones.appendRow([TextCellValue('Columna'), TextCellValue('Qué va')]);
    for (final c in columnas) {
      instrucciones.appendRow([TextCellValue(c.titulo), TextCellValue(c.ayuda)]);
    }

    final lugares = libro['Ubicaciones'];
    lugares.setColumnWidth(0, 60);
    lugares.appendRow([TextCellValue('Ubicaciones que ya existen (copiá el texto tal cual)')]);
    for (final u in ubicaciones) {
      lugares.appendRow([TextCellValue(u)]);
    }

    libro.setDefaultSheet(hojaInsumos);
    return Uint8List.fromList(libro.encode()!);
  }

  // ---- Leer la plantilla ------------------------------------------------------

  static const String avisoSinHoja =
      'No es la plantilla: no encontré una hoja con la columna "Nombre". '
      'Descargá la plantilla de la app y completala.';

  /// Lee la plantilla de [hojas]. Usa la hoja "Insumos" o, si no hay, la primera
  /// que tenga una columna "Nombre". Cada fila correcta es un insumo; cada fila
  /// con problemas va a `errores` y no se carga.
  static ResultadoLectura leer(List<HojaPlana> hojas) {
    final hoja = _buscarHoja(hojas);
    if (hoja == null) {
      return const ResultadoLectura(insumos: [], errores: [AvisoImportacion(0, avisoSinHoja)]);
    }

    final (filaEncabezado, posiciones, filas) = hoja;
    final faltan = [
      for (final c in columnas)
        if (c.obligatoria && !posiciones.containsKey(c.titulo)) c.titulo,
    ];
    if (faltan.isNotEmpty) {
      return ResultadoLectura(
        insumos: const [],
        errores: [
          AvisoImportacion(
            0,
            'Falta${faltan.length == 1 ? '' : 'n'} la${faltan.length == 1 ? '' : 's'} '
            'columna${faltan.length == 1 ? '' : 's'} obligatoria${faltan.length == 1 ? '' : 's'}: '
            '${faltan.join(', ')}. Usá la plantilla de la app.',
          ),
        ],
      );
    }

    final insumos = <InsumoImportado>[];
    final errores = <AvisoImportacion>[];

    for (var i = filaEncabezado + 1; i < filas.length; i++) {
      final fila = filas[i];
      if (fila.every((c) => _texto(c).isEmpty)) continue;
      final numero = i + 1;

      String celda(String titulo) {
        final columna = posiciones[titulo];
        return columna == null || columna >= fila.length ? '' : _texto(fila[columna]);
      }

      Object? cruda(String titulo) {
        final columna = posiciones[titulo];
        return columna == null || columna >= fila.length ? null : fila[columna];
      }

      final problemas = <String>[];

      final nombre = _limpiar(celda('Nombre'));
      if (nombre.isEmpty) {
        problemas.add('falta el nombre');
      } else if (!RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]').hasMatch(nombre)) {
        problemas.add('el nombre "$nombre" no tiene letras');
      }

      final ubicacion = _limpiar(celda('Ubicación'));
      if (ubicacion.isEmpty) problemas.add('falta la ubicación');

      int? cantidad;
      final textoCantidad = celda('Cantidad');
      if (textoCantidad.isEmpty) {
        problemas.add('falta la cantidad');
      } else {
        final numeroCantidad = _numero(cruda('Cantidad'));
        if (numeroCantidad == null) {
          problemas.add('la cantidad "$textoCantidad" no es un número');
        } else if (numeroCantidad < 0) {
          problemas.add('la cantidad no puede ser negativa ($textoCantidad)');
        } else if (numeroCantidad != numeroCantidad.roundToDouble()) {
          problemas.add('la cantidad tiene que ser un número entero ($textoCantidad)');
        } else {
          cantidad = numeroCantidad.toInt();
        }
      }

      num? stockMinimo;
      if (celda('Stock mínimo').isNotEmpty) {
        stockMinimo = _numero(cruda('Stock mínimo'));
        if (stockMinimo == null) {
          problemas.add('el stock mínimo "${celda('Stock mínimo')}" no es un número');
        } else if (stockMinimo < 0) {
          problemas.add('el stock mínimo no puede ser negativo');
        }
      }

      double? peso;
      if (celda('Peso molecular').isNotEmpty) {
        peso = _numero(cruda('Peso molecular'))?.toDouble();
        if (peso == null) {
          problemas.add('el peso molecular "${celda('Peso molecular')}" no es un número');
        } else if (peso <= 0) {
          problemas.add('el peso molecular tiene que ser mayor a 0');
        }
      }

      var controlado = false;
      final textoControlado = SimilitudTexto.normalizar(celda('Sedronar'));
      if (textoControlado.isNotEmpty) {
        if (const {'si', 's', 'x', '1', 'true', 'verdadero'}.contains(textoControlado)) {
          controlado = true;
        } else if (!const {'no', 'n', '0', 'false', 'falso'}.contains(textoControlado)) {
          problemas.add('Sedronar tiene que decir Sí o No (dice "${celda('Sedronar')}")');
        }
      }

      if (problemas.isNotEmpty) {
        errores.add(AvisoImportacion(numero, problemas.join('; ')));
        continue;
      }

      insumos.add(InsumoImportado(
        nombre: nombre,
        cantidad: cantidad!,
        ubicacion: ubicacion,
        fila: numero,
        stockMinimo: stockMinimo,
        unidad: _opcional(celda('Unidad')),
        categoria: _opcional(celda('Categoría')),
        codigoInterno: _opcional(celda('Código interno')),
        formula: _opcional(celda('Fórmula')),
        pesoMolecular: peso,
        marca: _opcional(celda('Marca')),
        otrosNombres: _separar(celda('Otros nombres')),
        controlado: controlado,
      ));
    }

    if (insumos.isEmpty && errores.isEmpty) {
      errores.add(const AvisoImportacion(0, 'La plantilla no tiene ningún insumo cargado.'));
    }
    return ResultadoLectura(insumos: insumos, errores: errores);
  }

  // ---- Piezas -----------------------------------------------------------------

  /// La hoja a leer: la fila del encabezado, dónde está cada columna y las filas.
  static (int, Map<String, int>, List<List<Object?>>)? _buscarHoja(List<HojaPlana> hojas) {
    final ordenadas = [
      ...hojas.where((h) => SimilitudTexto.normalizar(h.nombre) == 'insumos'),
      ...hojas.where((h) => SimilitudTexto.normalizar(h.nombre) != 'insumos'),
    ];
    for (final hoja in ordenadas) {
      final limite = hoja.filas.length < 10 ? hoja.filas.length : 10;
      for (var i = 0; i < limite; i++) {
        final posiciones = _columnasDe(hoja.filas[i]);
        if (posiciones.containsKey('Nombre')) return (i, posiciones, hoja.filas);
      }
    }
    return null;
  }

  static Map<String, int> _columnasDe(List<Object?> fila) {
    final posiciones = <String, int>{};
    for (var c = 0; c < fila.length; c++) {
      final clave = SimilitudTexto.normalizar(_texto(fila[c]));
      if (clave.isEmpty) continue;
      for (final columna in columnas) {
        if (columna._claves.contains(clave)) {
          posiciones.putIfAbsent(columna.titulo, () => c);
        }
      }
    }
    return posiciones;
  }

  static String _texto(Object? valor) {
    if (valor == null) return '';
    if (valor is String) return valor.trim();
    if (valor is num) {
      return valor == valor.roundToDouble() ? valor.toInt().toString() : valor.toString();
    }
    return valor.toString().trim();
  }

  static String _limpiar(String texto) => texto.trim().replaceAll(RegExp(r'\s+'), ' ');

  static String? _opcional(String texto) {
    final limpio = _limpiar(texto);
    return limpio.isEmpty ? null : limpio;
  }

  /// Un número de una celda: ya numérica, o escrita con coma o punto decimal.
  static num? _numero(Object? valor) {
    if (valor is num) return valor;
    return num.tryParse(_texto(valor).replaceAll(',', '.'));
  }

  static List<String> _separar(String texto) {
    final vistos = <String>{};
    return [
      for (final parte in texto.split(RegExp(r'[,;]')))
        if (parte.trim().isNotEmpty && vistos.add(parte.trim().toLowerCase()))
          _limpiar(parte),
    ];
  }
}
