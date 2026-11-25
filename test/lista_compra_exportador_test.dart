import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/screens/compras/item_compra.dart';
import 'package:tpfinal_grupo2/services/lista_compra_exportador.dart';

ItemCompra _item(String nombre, {int stock = 2, int pedir = 8}) {
  return ItemCompra(
    id: nombre,
    nombre: nombre,
    stock: stock,
    cantidadSolicitada: pedir,
  );
}

final _fecha = DateTime(2026, 11, 7);

void main() {
  group('formatearFecha y nombreArchivo', () {
    test('la fecha lleva ceros a la izquierda', () {
      expect(ListaCompraExportador.formatearFecha(_fecha), '07/11/2026');
    });

    test('el nombre del archivo lleva la fecha y la extensión', () {
      expect(
        ListaCompraExportador.nombreArchivo(_fecha, 'csv'),
        'lista-de-compras-2026-11-07.csv',
      );
      expect(
        ListaCompraExportador.nombreArchivo(_fecha, 'pdf'),
        'lista-de-compras-2026-11-07.pdf',
      );
    });
  });

  group('csv', () {
    test('tiene título, fecha, encabezados y un ítem por línea', () {
      final texto = ListaCompraExportador.csv([
        _item('Guantes de nitrilo', stock: 3, pedir: 8),
        _item('Agar LB', stock: 0, pedir: 5),
      ], _fecha);

      expect(texto.split('\r\n'), [
        'Lista de compras',
        'Generada el 07/11/2026',
        '',
        'Insumo;Stock actual;Cantidad a comprar',
        'Guantes de nitrilo;3;8',
        'Agar LB;0;5',
        '',
      ]);
    });

    test('con la lista vacía deja solo el encabezado', () {
      final texto = ListaCompraExportador.csv([], _fecha);

      expect(texto, contains('Insumo;Stock actual;Cantidad a comprar'));
      expect(texto.trimRight().split('\r\n').length, 4);
    });

    test('un nombre con punto y coma va entre comillas', () {
      final texto = ListaCompraExportador.csv([_item('Tubo; 15 ml')], _fecha);

      expect(texto, contains('"Tubo; 15 ml";2;8'));
    });

    test('las comillas dentro del nombre se duplican', () {
      final texto = ListaCompraExportador.csv([_item('Pinza 5" larga')], _fecha);

      expect(texto, contains('"Pinza 5"" larga";2;8'));
    });

    test('un salto de línea dentro del nombre no parte la fila', () {
      final texto = ListaCompraExportador.csv([_item('Buffer\nTAE')], _fecha);

      expect(texto, contains('"Buffer\nTAE";2;8'));
    });

    test('un nombre que parece fórmula se muestra como texto', () {
      final texto = ListaCompraExportador.csv([
        _item('=SUMA(A1:A2)'),
        _item('+54 reactivo'),
        _item('@usuario'),
      ], _fecha);

      expect(texto, contains("'=SUMA(A1:A2);2;8"));
      expect(texto, contains("'+54 reactivo;2;8"));
      expect(texto, contains("'@usuario;2;8"));
    });

    test('las tildes y la eñe pasan sin cambios', () {
      final texto = ListaCompraExportador.csv([_item('Pañol: Ácido acético')], _fecha);

      expect(texto, contains('Pañol: Ácido acético;2;8'));
    });
  });

  group('csvBytes', () {
    test('empieza con el BOM de UTF-8', () {
      final bytes = ListaCompraExportador.csvBytes([_item('Agar LB')], _fecha);

      expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
    });

    test('después del BOM sigue el mismo texto, bien codificado', () {
      final items = [_item('Ácido acético')];
      final bytes = ListaCompraExportador.csvBytes(items, _fecha);

      expect(
        utf8.decode(bytes.sublist(3)),
        ListaCompraExportador.csv(items, _fecha),
      );
    });
  });

  group('pdf', () {
    // Todo PDF válido empieza con "%PDF".
    bool esPdf(List<int> bytes) =>
        bytes.length > 4 && ascii.decode(bytes.sublist(0, 4)) == '%PDF';

    test('genera un PDF con ítems', () async {
      final bytes = await ListaCompraExportador.pdf([
        _item('Guantes de nitrilo'),
        _item('Pañol: Ácido acético'),
      ], _fecha);

      expect(esPdf(bytes), isTrue);
    });

    test('genera un PDF aunque la lista esté vacía', () async {
      final bytes = await ListaCompraExportador.pdf([], _fecha);

      expect(esPdf(bytes), isTrue);
    });

    test('una lista larga sigue en más hojas sin fallar', () async {
      final items = [for (var i = 0; i < 200; i++) _item('Insumo número $i')];

      final bytes = await ListaCompraExportador.pdf(items, _fecha);

      expect(esPdf(bytes), isTrue);
    });

    test('una lista enorme (más de 20 hojas) no falla', () async {
      // Tras una importación grande, "agregar sugerencias" puede sumar cientos.
      final items = [for (var i = 0; i < 800; i++) _item('Insumo número $i')];

      final bytes = await ListaCompraExportador.pdf(items, _fecha);

      expect(esPdf(bytes), isTrue);
    });
  });
}
