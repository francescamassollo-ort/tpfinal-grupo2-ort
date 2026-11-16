import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/lista_compra.dart';
import 'package:tpfinal_grupo2/services/lista_compra_service.dart';

Insumo _insumo(String id, {required int stock, required num umbral}) {
  return Insumo(
    id: id,
    nombre: 'Insumo $id',
    tipo: InsumoTipo.comprado,
    stock: stock,
    ubicacion: 'Estante A',
    umbralMinimo: umbral,
  );
}

void main() {
  group('cantidadSugeridaPara', () {
    test('repone hasta el doble del umbral mínimo', () {
      // 5 * 2 - 2 = 8
      expect(
        ListaCompraService.cantidadSugeridaPara(_insumo('a', stock: 2, umbral: 5)),
        8,
      );
    });

    test('con stock en cero pide el doble del umbral', () {
      expect(
        ListaCompraService.cantidadSugeridaPara(_insumo('a', stock: 0, umbral: 3)),
        6,
      );
    });

    test('nunca sugiere menos que la cantidad mínima', () {
      // 5 * 2 - 10 = 0, pero el mínimo es 1.
      expect(
        ListaCompraService.cantidadSugeridaPara(_insumo('a', stock: 10, umbral: 5)),
        ListaCompra.cantidadMinima,
      );
    });

    test('redondea hacia arriba cuando el umbral es decimal', () {
      // 2.5 * 2 - 1 = 4
      expect(
        ListaCompraService.cantidadSugeridaPara(_insumo('a', stock: 1, umbral: 2.5)),
        4,
      );
    });
  });

  group('calcularSugerencias', () {
    test('incluye los insumos con stock en o por debajo del umbral', () {
      final sugerencias = ListaCompraService.calcularSugerencias(
        [
          _insumo('bajo', stock: 2, umbral: 5),
          _insumo('justo', stock: 5, umbral: 5),
          _insumo('ok', stock: 20, umbral: 5),
        ],
        {},
      );

      expect(sugerencias.keys, containsAll(['bajo', 'justo']));
      expect(sugerencias.containsKey('ok'), isFalse);
    });

    test('no repite los que ya están en la lista', () {
      final sugerencias = ListaCompraService.calcularSugerencias(
        [
          _insumo('a', stock: 1, umbral: 5),
          _insumo('b', stock: 1, umbral: 5),
        ],
        {'a'},
      );

      expect(sugerencias.keys, ['b']);
    });

    test('devuelve vacío si no hay stock bajo', () {
      final sugerencias = ListaCompraService.calcularSugerencias(
        [_insumo('a', stock: 50, umbral: 5)],
        {},
      );

      expect(sugerencias, isEmpty);
    });
  });

  group('ListaCompra', () {
    final item = ListaCompra(
      id: 'x',
      productoId: 'p',
      cantidadSugerida: 8,
      cantidadSolicitada: 8,
      generadaEn: DateTime(2026, 11, 15),
    );

    test('la cantidad mínima es 1', () {
      expect(ListaCompra.cantidadMinima, 1);
    });

    test('empieza pendiente', () {
      expect(item.estado, EstadoCompra.pendiente);
    });

    test('editar la cantidad no cambia la sugerida', () {
      final editado = item.copyWith(cantidadSolicitada: 12);

      expect(editado.cantidadSolicitada, 12);
      expect(editado.cantidadSugerida, 8);
    });

    test('cambiar el estado no toca las cantidades', () {
      final descartado = item.copyWith(estado: EstadoCompra.descartado);

      expect(descartado.estado, EstadoCompra.descartado);
      expect(descartado.cantidadSolicitada, 8);
    });
  });
}
