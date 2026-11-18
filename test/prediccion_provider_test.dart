import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/movimiento_stock.dart';
import 'package:tpfinal_grupo2/providers/historial_provider.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/prediccion_provider.dart';

Insumo _insumo(String id, String nombre, {int stock = 10}) => Insumo(
      id: id,
      nombre: nombre,
      tipo: InsumoTipo.comprado,
      stock: stock,
      ubicacion: 'Estante 1',
      umbralMinimo: 2,
    );

// Una salida de [cantidad] unidades hace [diasAtras] días. El provider usa la
// hora actual, así que las fechas se arman respecto de hoy.
MovimientoStock _salida(String producto, int cantidad, {required int diasAtras}) {
  return MovimientoStock(
    id: '$producto-$diasAtras',
    productoId: producto,
    usuarioId: 'u1',
    usuarioNombre: 'Juan Perez',
    tipo: TipoMovimiento.salida,
    cantidad: cantidad,
    fecha: DateTime.now().subtract(Duration(days: diasAtras)),
  );
}

ProviderContainer _contenedor({
  required Stream<List<MovimientoStock>> movimientos,
  required Stream<List<Insumo>> insumos,
}) {
  final container = ProviderContainer(
    // Sin reintentos: un error de prueba tiene que quedar como error.
    retry: (retries, error) => null,
    overrides: [
      movimientosStockProvider.overrideWith((ref) => movimientos),
      insumosProvider.overrideWith((ref) => insumos),
    ],
  );
  addTearDown(container.dispose);
  // Como la pantalla real, el test tiene que escuchar los providers: en
  // Riverpod 3 un stream que nadie escucha queda pausado.
  container.listen(prediccionStockProvider, (previous, next) {});
  return container;
}

void main() {
  test('cruza los movimientos con los insumos y predice', () async {
    final container = _contenedor(
      movimientos: Stream.value([_salida('p1', 14, diasAtras: 2)]),
      insumos: Stream.value([_insumo('p1', 'Etanol', stock: 10)]),
    );
    await container.read(movimientosStockProvider.future);
    await container.read(insumosProvider.future);

    final predicciones = container.read(prediccionStockProvider).requireValue;

    expect(predicciones, hasLength(1));
    expect(predicciones.single.productoNombre, 'Etanol');
    // 14 unidades en 7 días (el mínimo observado) = 2 por día; 10 / 2 = 5.
    expect(predicciones.single.diasRestantes, 5);
  });

  test('un insumo sin salidas no aparece', () async {
    final container = _contenedor(
      movimientos: Stream.value([_salida('p1', 14, diasAtras: 2)]),
      insumos: Stream.value([_insumo('p1', 'Etanol'), _insumo('p2', 'Pipetas')]),
    );
    await container.read(movimientosStockProvider.future);
    await container.read(insumosProvider.future);

    final predicciones = container.read(prediccionStockProvider).requireValue;

    expect([for (final p in predicciones) p.productoId], ['p1']);
  });

  test('sin movimientos da una lista vacía, no un error', () async {
    final container = _contenedor(
      movimientos: Stream.value(const []),
      insumos: Stream.value([_insumo('p1', 'Etanol')]),
    );
    await container.read(movimientosStockProvider.future);
    await container.read(insumosProvider.future);

    final estado = container.read(prediccionStockProvider);

    expect(estado.hasError, isFalse);
    expect(estado.requireValue, isEmpty);
  });

  test('mientras no llegan los datos está cargando', () {
    // Streams que todavía no emitieron nada.
    final container = _contenedor(
      movimientos: StreamController<List<MovimientoStock>>().stream,
      insumos: StreamController<List<Insumo>>().stream,
    );

    expect(container.read(prediccionStockProvider).isLoading, isTrue);
  });

  test('se recalcula cuando llega un movimiento nuevo', () async {
    final movimientos = StreamController<List<MovimientoStock>>();
    addTearDown(movimientos.close);
    final container = _contenedor(
      movimientos: movimientos.stream,
      insumos: Stream.value([_insumo('p1', 'Etanol', stock: 10)]),
    );

    movimientos.add([_salida('p1', 7, diasAtras: 2)]);
    await container.read(movimientosStockProvider.future);
    await container.read(insumosProvider.future);
    // 7 unidades en 7 días = 1 por día: alcanza 10 días.
    expect(
      container.read(prediccionStockProvider).requireValue.single.diasRestantes,
      10,
    );

    // Entra una salida más: ahora se consume el doble de rápido.
    movimientos.add([
      _salida('p1', 7, diasAtras: 2),
      _salida('p1', 7, diasAtras: 1),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(prediccionStockProvider).requireValue.single.diasRestantes,
      5,
    );
  });

  test('un error al leer los movimientos se propaga como error', () async {
    final container = _contenedor(
      movimientos: Stream.error(Exception('sin conexión')),
      insumos: Stream.value([_insumo('p1', 'Etanol')]),
    );
    await Future<void>.delayed(Duration.zero);

    expect(container.read(prediccionStockProvider).hasError, isTrue);
  });
}
