import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/importacion.dart';
import 'package:tpfinal_grupo2/services/importador_de_insumos.dart';
import 'package:tpfinal_grupo2/services/lector_excel.dart';

ResultadoLectura _leer(String hoja, List<List<Object?>> filas) =>
    ImportadorDeInsumos.leer([HojaPlana(hoja, filas)]);

InsumoImportado _unico(ResultadoLectura r) {
  expect(r.insumos, hasLength(1));
  return r.insumos.single;
}

void main() {
  group('tabla con encabezado', () {
    test('lee código, nombre, fórmula y cantidad', () {
      final r = _leer('Organicos', [
        ['Código', 'Nombre', 'Fórmula', 'Cantidad'],
        ['Or-01', 'Acetamida', 'C2H5NO', 3],
      ]);

      final i = _unico(r);
      expect(i.codigoInterno, 'Or-01');
      expect(i.nombre, 'Acetamida');
      expect(i.formula, 'C2H5NO');
      expect(i.cantidad, 3);
      expect(i.hoja, 'Organicos');
      expect(i.fila, 2);
    });

    test('reconoce "Compuesto" y los acentos raros de los encabezados', () {
      final r = _leer('Hoja', [
        ['Còdigo', 'Compuesto', 'Fòrmula'],
        ['A1', 'Acetona', 'C3H6O'],
      ]);

      final i = _unico(r);
      expect(i.codigoInterno, 'A1');
      expect(i.formula, 'C3H6O');
    });

    test('lee "Otros nombres posibles" como lista', () {
      final r = _leer('Pañol - alcoholes', [
        ['Código', 'Compuesto', 'Otros nombres posibles'],
        ['I1', 'Alcohol Bencilico', 'Fenilmetanol; Bencenometanol'],
      ]);

      expect(_unico(r).otrosNombres, ['Fenilmetanol', 'Bencenometanol']);
    });

    test('una hoja de Sedronar marca todo como controlado', () {
      final r = _leer('Pañol - Sedronar', [
        ['Código', 'Compuesto'],
        ['S1', 'Acetona'],
        ['S2', 'Benceno'],
      ]);

      expect(r.insumos.every((i) => i.controlado), isTrue);
      final otra = _leer('Otra', [
        ['Código', 'Compuesto'],
        ['S1', 'Acetona'],
      ]);
      expect(_unico(otra).controlado, isFalse);
    });

    test('un código que Excel tomó por fecha vuelve a ser día-mes', () {
      final r = _leer('Organicos', [
        ['Código', 'Nombre'],
        [DateTime(2026, 2, 1), 'Acetanilida'],
      ]);

      expect(_unico(r).codigoInterno, '01-02');
    });

    test('un encabezado a la derecha y otro más abajo se leen los dos', () {
      final r = _leer('Inorganicos', [
        ['Estante 1'],
        ['CAJON 1', null, null, null, 'CAJON 2'],
        ['Código', 'Nombre', 'Fórmula', null, 'Código', 'Nombre', 'Fórmula'],
        ['Al-01', 'Aluminio metálico', 'Al', null, 'Ba-01', 'Bario carbonato', 'BaCO3'],
        ['Estante 2'],
        ['CAJON 1'],
        ['Código', 'Nombre', 'Fórmula'],
        ['Cu-01', 'Cobre', 'Cu'],
      ]);

      expect(r.insumos.map((i) => i.nombre), [
        'Aluminio metálico',
        'Bario carbonato',
        'Cobre',
      ]);
      expect(r.insumos[0].ubicacion, 'Inorganicos - Estante 1 - CAJON 1');
      expect(r.insumos[1].ubicacion, 'Inorganicos - Estante 1 - CAJON 2');
      expect(r.insumos[2].ubicacion, 'Inorganicos - Estante 2 - CAJON 1');
      expect(r.insumos[1].codigoInterno, 'Ba-01');
    });

    test('con el título del grupo y "Stock" al lado lee el stock y usa el título como categoría',
        () {
      final r = _leer('Agar en pañol', [
        [null, 'Agar', 'Stock - Armario 18'],
        [1, 'Agar - Agar', 4],
        [2, 'Baird - parker', 'NO HAY'],
      ]);

      expect(r.insumos.map((i) => i.cantidad), [4, 0]);
      expect(r.insumos.every((i) => i.categoria == 'Agar'), isTrue);
      expect(r.insumos.first.nombre, 'Agar - Agar');
    });

    test('una fila con la misma palabra de encabezado con números no es un encabezado', () {
      final r = _leer('Hoja', [
        ['Nombre', 'Cantidad'],
        ['Material', 4],
      ]);

      expect(_unico(r).nombre, 'Material');
      expect(_unico(r).cantidad, 4);
    });
  });

  group('cantidades', () {
    List<int> cantidades(List<Object?> valores) {
      final r = _leer('Hoja', [
        ['Nombre', 'Cantidad'],
        for (var i = 0; i < valores.length; i++) ['Insumo ${i + 1}', valores[i]],
      ]);
      return r.insumos.map((i) => i.cantidad).toList();
    }

    test('NO HAY y agotado son cero', () {
      expect(cantidades(['NO HAY', 'no hay ', 'Agotado']), [0, 0, 0]);
    });

    test('un número con texto toma el número ("3 bolsas")', () {
      expect(cantidades(['3 bolsas', '2.0']), [3, 2]);
    });

    test('una cantidad vacía es 1 y se avisa una sola vez por hoja', () {
      final r = _leer('Hoja', [
        ['Nombre', 'Cantidad'],
        ['Uno', null],
        ['Dos', null],
      ]);

      expect(r.insumos.map((i) => i.cantidad), [1, 1]);
      expect(r.avisos.where((a) => a.mensaje.contains('sin cantidad')), hasLength(1));
      expect(r.avisos.single.mensaje, contains('2 insumos sin cantidad'));
    });

    test('"Solo en pañol" es cero y se avisa', () {
      final r = _leer('Hoja', [
        ['Nombre', 'Cantidad'],
        ['Cerebro', 'Solo en pañol'],
      ]);

      expect(_unico(r).cantidad, 0);
      expect(r.avisos.single.toString(), contains('Solo en pañol'));
    });

    test('un texto que no se entiende es 1 y se avisa', () {
      final r = _leer('Hoja', [
        ['Nombre', 'Cantidad'],
        ['Reactivo de Fehling', 'Muchas'],
      ]);

      expect(_unico(r).cantidad, 1);
      expect(r.avisos.single.mensaje, contains('Muchas'));
    });

    test('decimales se redondean y negativos son cero, con aviso', () {
      final r = _leer('Hoja', [
        ['Nombre', 'Cantidad'],
        ['Alfa', 2.6],
        ['Beta', -3],
      ]);

      expect(r.insumos.map((i) => i.cantidad), [3, 0]);
      expect(r.avisos, hasLength(2));
    });

    test('"x5" al final del nombre es la cantidad cuando no hay otra', () {
      final r = _leer('Pañol - alcoholes', [
        ['Código', 'Compuesto'],
        ['I3', 'Etanol absoluto x5'],
        ['I4', 'Metanol'],
      ]);

      expect(r.insumos.first.nombre, 'Etanol absoluto');
      expect(r.insumos.first.cantidad, 5);
      expect(r.insumos.last.cantidad, 1);
    });
  });

  group('lista simple, sin encabezado', () {
    test('toma el nombre de la columna A y la cantidad de la B', () {
      final r = _leer('Heladera Pañol', [
        ['Estante 1'],
        ['Glicemia enzimatica', 3],
        ['Chagas Test HAI ', 2],
      ]);

      expect(r.insumos.map((i) => i.nombre), ['Glicemia enzimatica', 'Chagas Test HAI']);
      expect(r.insumos.map((i) => i.cantidad), [3, 2]);
      expect(r.insumos.first.ubicacion, 'Heladera Pañol - Estante 1');
      // Avisa que no tenía encabezado.
      expect(r.avisos.first.mensaje, contains('lista simple'));
    });

    test('el nombre de la hoja con solo un número es un laboratorio', () {
      final r = _leer('404', [
        ['LABORATORIO 404'],
        [null, null, null, null, 'Actualizado 31/03/2026'],
        ['Armario N°1 - Soluciones'],
        ['AgNO3 0,1N'],
      ]);

      final i = _unico(r);
      expect(i.nombre, 'AgNO3 0,1N');
      expect(i.ubicacion, 'Laboratorio 404 - Armario N°1 - Soluciones');
    });

    test('un título con "Actualizado" al lado sigue siendo un título', () {
      final r = _leer('403', [
        ['LABORATORIO 403', null, null, 'Actualizado 20/04/2026'],
        ['ARMARIO N°1 - Ing. Genetica'],
        ['Acetato de sodio'],
      ]);

      expect(r.insumos.map((i) => i.nombre), ['Acetato de sodio']);
    });

    test('"Caja 1" entre los insumos es el lugar de los que siguen', () {
      final r = _leer('Armario terciario', [
        ['Caja 1'],
        ['Tubos falcon 15 ml', '3 bolsas'],
        ['Caja 2'],
        ['Guantes', 'Muchas'],
      ]);

      expect(r.insumos.map((i) => i.ubicacion), [
        'Armario terciario - Caja 1',
        'Armario terciario - Caja 2',
      ]);
      expect(r.insumos.first.cantidad, 3);
    });
  });

  group('categoría', () {
    test('una columna de categoría manda sobre todo lo demás', () {
      final r = _leer('Hoja', [
        ['Nombre', 'Categoría'],
        ['Etanol', 'Mi categoría'],
      ]);

      expect(_unico(r).categoria, 'Mi categoría');
    });

    test('sin categoría se sugiere con las reglas de nombre', () {
      final r = _leer('Hoja', [
        ['Nombre'],
        ['Etanol absoluto'],
      ]);

      expect(_unico(r).categoria, 'Alcoholes y solventes');
    });

    test('las hojas de inorgánicos y orgánicos dan su categoría', () {
      expect(
        _unico(_leer('Inorganicos', [['Nombre'], ['Cobre']])).categoria,
        'Inorgánicos',
      );
      expect(
        _unico(_leer('Organicos', [['Nombre'], ['Manitol']])).categoria,
        'Orgánicos',
      );
    });
  });

  group('lo que no sirve', () {
    test('una hoja vacía o sin nada que leer queda ignorada', () {
      final r = ImportadorDeInsumos.leer([
        const HojaPlana('Vacía', []),
        const HojaPlana('Nada', [
          [null, null],
        ]),
        const HojaPlana('Buena', [
          ['Nombre'],
          ['Etanol'],
        ]),
      ]);

      expect(r.hojasLeidas, ['Buena']);
      expect(r.hojasIgnoradas, ['Vacía', 'Nada']);
    });

    test('los nombres que son solo números o están vacíos no son insumos', () {
      final r = _leer('Hoja', [
        ['Nombre', 'Cantidad'],
        ['1234', 2],
        [null, 3],
        ['  ', 1],
        ['Etanol', 1],
      ]);

      expect(r.insumos.map((i) => i.nombre), ['Etanol']);
    });

    test('la fila "Actualizado..." no es un insumo', () {
      final r = _leer('Hoja', [
        ['Nombre', 'Cantidad', 'Actualizado 20/04/2026'],
        ['Actualizado 20/04/2026'],
        ['Etanol', 1],
      ]);

      expect(r.insumos.map((i) => i.nombre), ['Etanol']);
    });
  });

  group('LectorExcel', () {
    test('lee de un archivo de verdad textos, números y hojas', () {
      final libro = Excel.createExcel();
      final hoja = libro['Hoja nueva'];
      hoja.appendRow([TextCellValue('Código'), TextCellValue('Nombre'), TextCellValue('Cantidad')]);
      hoja.appendRow([TextCellValue('X1'), TextCellValue('Etanol'), IntCellValue(4)]);
      final bytes = Uint8List.fromList(libro.encode()!);

      final hojas = LectorExcel.leer(bytes);
      final r = ImportadorDeInsumos.leer(hojas);

      final i = r.insumos.singleWhere((i) => i.hoja == 'Hoja nueva');
      expect(i.codigoInterno, 'X1');
      expect(i.nombre, 'Etanol');
      expect(i.cantidad, 4);
    });

    test('un archivo que no es un Excel lanza error', () {
      expect(
        () => LectorExcel.leer(Uint8List.fromList([1, 2, 3, 4])),
        throwsA(anything),
      );
    });
  });
}
