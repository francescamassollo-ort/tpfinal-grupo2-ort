import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/importacion.dart';
import 'package:tpfinal_grupo2/services/lector_excel.dart';
import 'package:tpfinal_grupo2/services/plantilla_de_insumos.dart';

const _encabezado = ['Nombre', 'Ubicación', 'Cantidad'];

ResultadoLectura _leer(List<List<Object?>> filas, {String hoja = 'Insumos'}) =>
    PlantillaDeInsumos.leer([HojaPlana(hoja, filas)]);

void main() {
  group('leer: filas correctas', () {
    test('una fila con lo obligatorio es un insumo', () {
      final r = _leer([
        _encabezado,
        ['Etanol absoluto', 'Armario 1', 5],
      ]);

      expect(r.errores, isEmpty);
      final i = r.insumos.single;
      expect(i.nombre, 'Etanol absoluto');
      expect(i.ubicacion, 'Armario 1');
      expect(i.cantidad, 5);
      expect(i.fila, 2);
      expect(i.stockMinimo, isNull);
      expect(i.controlado, isFalse);
    });

    test('lee todas las columnas opcionales', () {
      final r = _leer([
        [..._encabezado, 'Stock mínimo', 'Unidad', 'Categoría', 'Código interno', 'Fórmula',
          'Peso molecular', 'Marca', 'Otros nombres', 'Sedronar'],
        ['Etanol', 'Armario 1', 5, 2, 'ml', 'Alcoholes', 'I3', 'C2H6O', '46,07', 'Cicarelli',
          'Alcohol etílico; Etanol 96', 'Sí'],
      ]);

      final i = r.insumos.single;
      expect(i.stockMinimo, 2);
      expect(i.unidad, 'ml');
      expect(i.categoria, 'Alcoholes');
      expect(i.codigoInterno, 'I3');
      expect(i.formula, 'C2H6O');
      expect(i.pesoMolecular, 46.07);
      expect(i.marca, 'Cicarelli');
      expect(i.otrosNombres, ['Alcohol etílico', 'Etanol 96']);
      expect(i.controlado, isTrue);
    });

    test('las columnas pueden venir en cualquier orden y con otros títulos conocidos', () {
      final r = _leer([
        ['cantidad', 'LUGAR', 'nombre', 'Codigo'],
        [3, 'Estante 2', 'Acetona', 'S2'],
      ]);

      final i = r.insumos.single;
      expect(i.nombre, 'Acetona');
      expect(i.ubicacion, 'Estante 2');
      expect(i.cantidad, 3);
      expect(i.codigoInterno, 'S2');
    });

    test('la cantidad puede venir como texto y 0 es válido', () {
      final r = _leer([
        _encabezado,
        ['Uno', 'A1', '4'],
        ['Dos', 'A1', 0],
        ['Tres', 'A1', 2.0],
      ]);

      expect(r.insumos.map((i) => i.cantidad), [4, 0, 2]);
    });

    test('limpia los espacios de más y salta las filas vacías', () {
      final r = _leer([
        _encabezado,
        ['  Etanol   absoluto ', ' Armario   1 ', 1],
        [null, null, null],
        ['  ', '', ''],
      ]);

      expect(r.insumos.single.nombre, 'Etanol absoluto');
      expect(r.insumos.single.ubicacion, 'Armario 1');
      expect(r.errores, isEmpty);
    });

    test('el encabezado puede no estar en la primera fila', () {
      final r = _leer([
        ['Inventario del laboratorio'],
        [],
        _encabezado,
        ['Etanol', 'A1', 1],
      ]);

      expect(r.insumos.single.fila, 4);
    });

    test('usa la hoja "Insumos" aunque haya otras antes', () {
      final r = PlantillaDeInsumos.leer([
        const HojaPlana('Instrucciones', [
          ['Nombre', 'Qué va'],
          ['Nombre', 'El nombre'],
        ]),
        const HojaPlana('Insumos', [
          _encabezado,
          ['Etanol', 'A1', 1],
        ]),
      ]);

      expect(r.insumos.map((i) => i.nombre), ['Etanol']);
    });

    test('Sedronar acepta Sí, No y X en cualquier escritura', () {
      final r = _leer([
        [..._encabezado, 'Sedronar'],
        ['Alfa', 'U', 1, 'si'],
        ['Beta', 'U', 1, 'NO'],
        ['Gamma', 'U', 1, 'x'],
        ['Delta', 'U', 1, null],
      ]);

      expect(r.insumos.map((i) => i.controlado), [true, false, true, false]);
    });
  });

  group('leer: filas con errores', () {
    ResultadoLectura fila(List<Object?> datos) => _leer([_encabezado, datos]);

    test('sin nombre', () {
      final r = fila([null, 'A1', 1]);

      expect(r.insumos, isEmpty);
      expect(r.errores.single.fila, 2);
      expect(r.errores.single.mensaje, contains('falta el nombre'));
    });

    test('un nombre sin letras', () {
      expect(fila(['1234', 'A1', 1]).errores.single.mensaje, contains('no tiene letras'));
    });

    test('sin ubicación', () {
      expect(fila(['Etanol', '', 1]).errores.single.mensaje, contains('falta la ubicación'));
    });

    test('sin cantidad', () {
      expect(fila(['Etanol', 'A1', null]).errores.single.mensaje, contains('falta la cantidad'));
    });

    test('cantidad que no es un número', () {
      expect(fila(['Etanol', 'A1', 'mucha']).errores.single.mensaje, contains('no es un número'));
    });

    test('cantidad negativa o con decimales', () {
      expect(fila(['Etanol', 'A1', -2]).errores.single.mensaje, contains('negativa'));
      expect(fila(['Etanol', 'A1', 2.5]).errores.single.mensaje, contains('entero'));
    });

    test('varios problemas de la misma fila se dicen juntos', () {
      final error = fila([null, null, 'x']).errores.single;

      expect(error.mensaje, contains('falta el nombre'));
      expect(error.mensaje, contains('falta la ubicación'));
      expect(error.mensaje, contains('no es un número'));
      expect(error.toString(), startsWith('Fila 2: '));
    });

    test('stock mínimo, peso molecular y Sedronar mal escritos', () {
      final r = _leer([
        [..._encabezado, 'Stock mínimo', 'Peso molecular', 'Sedronar'],
        ['A', 'U', 1, 'poco', 'pesado', 'quizás'],
        ['B', 'U', 1, -1, 0, 'Sí'],
      ]);

      expect(r.insumos, isEmpty);
      expect(r.errores[0].mensaje, allOf(contains('stock mínimo'), contains('peso molecular'), contains('Sedronar')));
      expect(r.errores[1].mensaje, allOf(contains('stock mínimo no puede ser negativo'), contains('mayor a 0')));
    });

    test('una fila mala no frena a las buenas', () {
      final r = _leer([
        _encabezado,
        ['Bueno', 'A1', 1],
        [null, 'A1', 1],
        ['Otro bueno', 'A2', 3],
      ]);

      expect(r.insumos.map((i) => i.nombre), ['Bueno', 'Otro bueno']);
      expect(r.errores.single.fila, 3);
      expect(r.archivoInvalido, isFalse);
    });
  });

  group('leer: el archivo no sirve', () {
    test('no es la plantilla', () {
      final r = _leer([
        ['Producto raro', 'Otra cosa'],
        ['x', 'y'],
      ]);

      expect(r.archivoInvalido, isTrue);
      expect(r.errores.single.mensaje, PlantillaDeInsumos.avisoSinHoja);
    });

    test('le falta una columna obligatoria y dice cuál', () {
      final r = _leer([
        ['Nombre', 'Cantidad'],
        ['Etanol', 1],
      ]);

      expect(r.archivoInvalido, isTrue);
      expect(r.errores.single.mensaje, contains('Ubicación'));
    });

    test('la plantilla sin ningún insumo lo dice', () {
      final r = _leer([_encabezado]);

      expect(r.archivoInvalido, isTrue);
      expect(r.errores.single.mensaje, contains('ningún insumo'));
    });

    test('sin hojas', () {
      expect(PlantillaDeInsumos.leer(const []).archivoInvalido, isTrue);
    });
  });

  group('generar la plantilla', () {
    test('tiene las hojas de insumos, instrucciones y ubicaciones', () {
      final hojas = LectorExcel.leer(
        PlantillaDeInsumos.generar(ubicaciones: ['Armario 1', 'Heladera Pañol']),
      );

      expect(hojas.map((h) => h.nombre), ['Insumos', 'Instrucciones', 'Ubicaciones']);
      final ubicaciones = hojas.last.filas.map((f) => f.first).toList();
      expect(ubicaciones, containsAll(['Armario 1', 'Heladera Pañol']));
    });

    test('los títulos de la hoja de insumos son los de las columnas', () {
      final hojas = LectorExcel.leer(PlantillaDeInsumos.generar());

      expect(
        hojas.first.filas.first.where((c) => c != null),
        PlantillaDeInsumos.columnas.map((c) => c.titulo),
      );
    });

    test('la plantilla vacía se reconoce como plantilla pero sin insumos', () {
      final r = PlantillaDeInsumos.leer(LectorExcel.leer(PlantillaDeInsumos.generar()));

      expect(r.insumos, isEmpty);
      // Se reconoció: el aviso es que no hay insumos, no que no es la plantilla.
      expect(r.errores.single.mensaje, contains('ningún insumo'));
    });

    test('una plantilla completada a mano se lee de ida y vuelta', () {
      final hojas = LectorExcel.leer(PlantillaDeInsumos.generar());
      final insumos = hojas.first;
      final completada = [
        HojaPlana('Insumos', [
          insumos.filas.first,
          ['Etanol', 'Armario 1', 3, null, null, null, 'I3'],
        ]),
      ];

      final r = PlantillaDeInsumos.leer(completada);

      expect(r.errores, isEmpty);
      expect(r.insumos.single.nombre, 'Etanol');
      expect(r.insumos.single.codigoInterno, 'I3');
    });
  });
}
