import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/movimiento_stock.dart';
import 'package:tpfinal_grupo2/services/exportacion_comun.dart';
import 'package:tpfinal_grupo2/services/historial_exportador.dart';

MovimientoStock _movimiento(
  String id, {
  String productoId = 'p1',
  TipoMovimiento tipo = TipoMovimiento.salida,
  int cantidad = 10,
  String usuario = 'Juan Perez',
  DateTime? fecha,
  String? motivo,
}) {
  return MovimientoStock(
    id: id,
    productoId: productoId,
    usuarioId: 'u1',
    usuarioNombre: usuario,
    tipo: tipo,
    cantidad: cantidad,
    fecha: fecha ?? DateTime(2026, 11, 7, 9, 5),
    motivo: motivo,
  );
}

const _nombres = {'p1': 'Etanol', 'p2': 'Agar LB'};
final _hoy = DateTime(2026, 11, 17);

void main() {
  group('nombre y textos', () {
    test('el nombre del archivo lleva la fecha y la extensión', () {
      expect(
        HistorialExportador.nombreArchivo(DateTime(2026, 11, 7), 'csv'),
        'historial-de-movimientos-2026-11-07.csv',
      );
      expect(
        HistorialExportador.nombreArchivo(DateTime(2026, 11, 7), 'pdf'),
        'historial-de-movimientos-2026-11-07.pdf',
      );
    });

    test('cada tipo tiene su texto', () {
      expect(HistorialExportador.tipoTexto(TipoMovimiento.entrada), 'Entrada');
      expect(HistorialExportador.tipoTexto(TipoMovimiento.salida), 'Salida');
      expect(HistorialExportador.tipoTexto(TipoMovimiento.ajuste), 'Ajuste');
    });
  });

  group('csv', () {
    test('tiene título, fecha, encabezados y un movimiento por línea', () {
      final texto = HistorialExportador.csv([
        _movimiento('a', motivo: 'Trabajo práctico 3'),
        _movimiento(
          'b',
          productoId: 'p2',
          tipo: TipoMovimiento.entrada,
          cantidad: 5,
          usuario: 'Ana Gomez',
          fecha: DateTime(2026, 11, 6, 16, 40),
        ),
      ], _nombres, _hoy);

      expect(texto.split('\r\n'), [
        'Historial de movimientos',
        'Generado el 17/11/2026',
        '',
        'Fecha;Insumo;Tipo;Cantidad;Persona;Motivo',
        '07/11/2026 09:05;Etanol;Salida;-10;Juan Perez;Trabajo práctico 3',
        '06/11/2026 16:40;Agar LB;Entrada;5;Ana Gomez;',
        '',
      ]);
    });

    test('la cantidad es la variación: la salida es negativa y no se escapa', () {
      final texto = HistorialExportador.csv([_movimiento('a', cantidad: 10)], _nombres, _hoy);

      // Sin apóstrofo delante: es un número que Excel tiene que leer como tal.
      expect(texto, contains(';Salida;-10;'));
      expect(texto, isNot(contains("'-10")));
    });

    test('un ajuste lleva el signo que tiene', () {
      final texto = HistorialExportador.csv([
        _movimiento('a', tipo: TipoMovimiento.ajuste, cantidad: -3),
        _movimiento('b', tipo: TipoMovimiento.ajuste, cantidad: 4),
      ], _nombres, _hoy);

      expect(texto, contains(';Ajuste;-3;'));
      expect(texto, contains(';Ajuste;4;'));
    });

    test('con filtros lo avisa, sin filtros no', () {
      final con = HistorialExportador.csv([_movimiento('a')], _nombres, _hoy, conFiltros: true);
      final sin = HistorialExportador.csv([_movimiento('a')], _nombres, _hoy);

      expect(con.split('\r\n')[2], 'Con filtros aplicados');
      expect(sin, isNot(contains('Con filtros aplicados')));
    });

    test('un insumo que ya no existe se exporta igual', () {
      final texto = HistorialExportador.csv([_movimiento('a', productoId: 'borrado')], _nombres, _hoy);

      expect(texto, contains(';Insumo eliminado;'));
    });

    test('un motivo con punto y coma o comillas se protege', () {
      final texto = HistorialExportador.csv([
        _movimiento('a', motivo: 'Lote 4; "urgente"'),
      ], _nombres, _hoy);

      expect(texto, contains('"Lote 4; ""urgente"""'));
    });

    test('un texto que Excel tomaría por fórmula se escapa', () {
      final texto = HistorialExportador.csv([
        _movimiento('a', usuario: '=SUMA(A1)', motivo: '@cmd'),
      ], _nombres, _hoy);

      expect(texto, contains("'=SUMA(A1)"));
      expect(texto, contains("'@cmd"));
    });

    test('sin movimientos deja solo el encabezado', () {
      final texto = HistorialExportador.csv(const [], _nombres, _hoy);

      expect(texto, contains('Fecha;Insumo;Tipo;Cantidad;Persona;Motivo'));
      expect(texto.trimRight().split('\r\n').length, 4);
    });

    test('los bytes llevan el BOM de UTF-8 y conservan las tildes', () {
      final bytes = HistorialExportador.csvBytes([
        _movimiento('a', motivo: 'Química'),
      ], _nombres, _hoy);

      expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
      expect(utf8.decode(bytes.sublist(3)), contains('Química'));
    });
  });

  group('pdf', () {
    test('es un PDF válido', () async {
      final bytes = await HistorialExportador.pdf([
        _movimiento('a', motivo: 'Trabajo práctico 3'),
        _movimiento('b', productoId: 'p2', tipo: TipoMovimiento.entrada),
      ], _nombres, _hoy);

      expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
    });

    test('con muchos movimientos sigue en más hojas y no falla', () async {
      final muchos = [
        for (var i = 0; i < 300; i++) _movimiento('m$i', motivo: 'Movimiento número $i'),
      ];

      final bytes = await HistorialExportador.pdf(muchos, _nombres, _hoy, conFiltros: true);

      expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
    });

    test('sin movimientos también arma el archivo', () async {
      final bytes = await HistorialExportador.pdf(const [], _nombres, _hoy);

      expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
    });
  });

  group('formato común', () {
    test('la fecha y la hora llevan ceros a la izquierda', () {
      expect(ExportacionComun.formatearFecha(DateTime(2026, 1, 5)), '05/01/2026');
      expect(
        ExportacionComun.formatearFechaHora(DateTime(2026, 1, 5, 9, 3)),
        '05/01/2026 09:03',
      );
      expect(ExportacionComun.fechaParaNombre(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });
}
