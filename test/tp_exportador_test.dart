import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/trabajo_practico.dart';
import 'package:tpfinal_grupo2/services/tp_exportador.dart';

Insumo _insumo(String id, String nombre, String ubicacion, {int stock = 10}) {
  return Insumo(
    id: id,
    nombre: nombre,
    tipo: InsumoTipo.comprado,
    stock: stock,
    ubicacion: ubicacion,
    umbralMinimo: 2,
  );
}

TrabajoPractico _tp(
  List<InsumoRequerido> insumos, {
  String nombre = 'TP Titulaciones',
  String docente = 'Ana Pérez',
}) {
  return TrabajoPractico(
    id: 'tp1',
    nombre: nombre,
    descripcion: '',
    fecha: DateTime(2026, 11, 7),
    docente: docente,
    insumos: insumos,
  );
}

InsumoRequerido _req(String id, double cantidad, [String unidad = 'ml']) {
  return InsumoRequerido(insumoId: id, cantidad: cantidad, unidad: unidad);
}

void main() {
  group('nombreArchivo', () {
    test('lleva el nombre del TP, la fecha del TP y la extensión', () {
      expect(
        TpExportador.nombreArchivo('TP Titulaciones', DateTime(2026, 11, 7), 'csv'),
        'tp-tp-titulaciones-2026-11-07.csv',
      );
    });

    test('saca tildes, símbolos y barras', () {
      final nombre = TpExportador.nombreArchivo(
        'Práctica Nº 3: ¡Ácido/Base! "pH"',
        DateTime(2026, 11, 7),
        'pdf',
      );
      expect(nombre, 'tp-practica-n-3-acido-base-ph-2026-11-07.pdf');
      expect(nombre, matches(r'^[a-z0-9.\-]+$'));
    });

    test('un nombre sin letras ni números usa uno genérico', () {
      expect(
        TpExportador.nombreArchivo('???', DateTime(2026, 11, 7), 'csv'),
        'tp-trabajo-practico-2026-11-07.csv',
      );
    });

    test('un nombre larguísimo se recorta', () {
      final nombre = TpExportador.nombreArchivo('a' * 200, DateTime(2026, 11, 7), 'csv');
      expect(nombre.length, lessThan(70));
    });
  });

  group('armarFilas', () {
    test('ordena por ubicación y después por nombre, sin mirar mayúsculas', () {
      final tp = _tp([_req('1', 1), _req('2', 1), _req('3', 1), _req('4', 1)]);
      final filas = TpExportador.armarFilas(
        tp,
        [
          _insumo('1', 'Zinc', 'estante b'),
          _insumo('2', 'Acetona', 'Heladera 2'),
          _insumo('3', 'Etanol', 'Estante A'),
          _insumo('4', 'Agar', 'Estante B'),
        ],
        const {},
      );
      expect(filas.map((f) => f.nombre), ['Etanol', 'Agar', 'Zinc', 'Acetona']);
    });

    test('un insumo que ya no existe va al final y sin ubicación inventada', () {
      final tp = _tp([_req('borrado', 1), _req('1', 1)]);
      final filas = TpExportador.armarFilas(
        tp,
        [_insumo('1', 'Etanol', 'Estante A')],
        const {'borrado': 1},
      );
      expect(filas.last.nombre, 'Insumo no encontrado');
      expect(filas.last.ubicacion, isEmpty);
      expect(filas.last.stock, 0);
      expect(filas.last.falta, 1);
    });

    test('marca lo que falta y cuánto', () {
      final tp = _tp([_req('1', 5), _req('2', 1)]);
      final filas = TpExportador.armarFilas(
        tp,
        [_insumo('1', 'Etanol', 'A', stock: 2), _insumo('2', 'Agar', 'B')],
        const {'1': 3},
      );
      expect(filas[0].faltaStock, isTrue);
      expect(filas[0].falta, 3);
      expect(filas[1].faltaStock, isFalse);
    });
  });

  group('csv', () {
    test('tiene título, fecha, docente, encabezados y un insumo por línea', () {
      final tp = _tp([_req('1', 5), _req('2', 1.5, 'g')]);
      final filas = TpExportador.armarFilas(
        tp,
        [
          _insumo('1', 'Etanol', 'Estante A', stock: 2),
          _insumo('2', 'Agar LB', 'Heladera 2'),
        ],
        const {'1': 3},
      );
      final lineas = TpExportador.csv(tp, filas).split('\r\n');
      expect(lineas[0], 'TP Titulaciones');
      expect(lineas[1], 'Fecha: 07/11/2026');
      expect(lineas[2], 'Docente: Ana Pérez');
      expect(lineas[3], '');
      expect(
        lineas[4],
        'Ubicación;Insumo;Cantidad pedida;Stock disponible;Falta',
      );
      expect(lineas[5], 'Estante A;Etanol;5 ml;2;3');
      expect(lineas[6], 'Heladera 2;Agar LB;1.5 g;10;-');
      // Termina con salto de línea.
      expect(lineas.last, '');
    });

    test('protege los valores con ; o que Excel tomaría por fórmula', () {
      final tp = _tp([_req('1', 1)], nombre: '=SUMA(A1)', docente: '');
      final filas = TpExportador.armarFilas(
        tp,
        [_insumo('1', 'Sal; fina', 'Estante A')],
        const {},
      );
      final texto = TpExportador.csv(tp, filas);
      expect(texto, startsWith("'=SUMA(A1)\r\n"));
      expect(texto, contains('Docente: -'));
      expect(texto, contains('"Sal; fina"'));
    });

    test('los bytes llevan BOM y las tildes en UTF-8', () {
      final tp = _tp([_req('1', 1)]);
      final filas = TpExportador.armarFilas(
        tp,
        [_insumo('1', 'Ácido', 'Estante A')],
        const {},
      );
      final bytes = TpExportador.csvBytes(tp, filas);
      expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
      expect(utf8.decode(bytes.sublist(3)), contains('Ácido'));
    });
  });

  group('pdf', () {
    test('genera un PDF válido', () async {
      final tp = _tp([_req('1', 5), _req('2', 1)]);
      final filas = TpExportador.armarFilas(
        tp,
        [
          _insumo('1', 'Etanol', 'Estante A', stock: 2),
          _insumo('2', 'Agar LB', 'Estante A'),
        ],
        const {'1': 3},
      );
      final bytes = await TpExportador.pdf(tp, filas);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });

    test('también con una lista larga que ocupa varias hojas', () async {
      final requeridos = [for (var i = 0; i < 120; i++) _req('i$i', 1)];
      final insumos = [
        for (var i = 0; i < 120; i++) _insumo('i$i', 'Insumo $i', 'Lugar ${i % 7}'),
      ];
      final tp = _tp(requeridos);
      final bytes = await TpExportador.pdf(
        tp,
        TpExportador.armarFilas(tp, insumos, const {}),
      );
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });
  });
}
