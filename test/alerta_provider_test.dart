import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/alerta.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/movimiento_stock.dart';
import 'package:tpfinal_grupo2/models/trabajo_practico.dart';
import 'package:tpfinal_grupo2/providers/alerta_provider.dart';
import 'package:tpfinal_grupo2/providers/historial_provider.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/trabajopractico_provider.dart';

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

// Un trabajo práctico de hoy que pide [cantidad] del insumo [producto]. Es de
// hoy porque hoy siempre cae antes de la próxima compra, sin importar el día
// en que se corran los tests.
TrabajoPractico _tp(String producto, double cantidad) {
  return TrabajoPractico(
    id: 'tp-$producto',
    nombre: 'PCR',
    descripcion: '',
    fecha: DateTime.now(),
    insumos: [InsumoRequerido(insumoId: producto, cantidad: cantidad, unidad: 'u')],
  );
}

ProviderContainer _contenedor({
  required Stream<List<MovimientoStock>> movimientos,
  required Stream<List<Insumo>> insumos,
  Stream<List<TrabajoPractico>>? tps,
}) {
  final container = ProviderContainer(
    // Sin reintentos: un error de prueba tiene que quedar como error.
    retry: (retries, error) => null,
    overrides: [
      movimientosStockProvider.overrideWith((ref) => movimientos),
      insumosProvider.overrideWith((ref) => insumos),
      // Sin TP por defecto: así no se intenta abrir Firestore en los tests.
      tpsStreamProvider.overrideWith((ref) => tps ?? Stream.value(const [])),
    ],
  );
  addTearDown(container.dispose);
  // Como la pantalla real, el test tiene que escuchar el provider: en
  // Riverpod 3 un stream que nadie escucha queda pausado.
  container.listen(alertasProvider, (previous, next) {});
  return container;
}

List<TipoAlerta> _tipos(ProviderContainer container) => [
      for (final a in container.read(alertasProvider).requireValue) a.tipo,
    ];

void main() {
  test('sin movimientos solo hay alertas de los insumos', () async {
    final container = _contenedor(
      movimientos: Stream.value(const []),
      insumos: Stream.value([_insumo('p1', 'Etanol', stock: 0)]),
    );
    await container.read(movimientosStockProvider.future);
    await container.read(insumosProvider.future);
    await container.read(tpsStreamProvider.future);

    expect(_tipos(container), [TipoAlerta.sinStock]);
  });

  test('un consumo alto suma el aviso de que se agota', () async {
    final container = _contenedor(
      // 700 unidades en 2 días: el stock de 10 se acaba hoy mismo, antes de
      // cualquier próxima compra.
      movimientos: Stream.value([_salida('p1', 700, diasAtras: 2)]),
      insumos: Stream.value([_insumo('p1', 'Etanol', stock: 10)]),
    );
    await container.read(movimientosStockProvider.future);
    await container.read(insumosProvider.future);
    await container.read(tpsStreamProvider.future);

    final alertas = container.read(alertasProvider).requireValue;

    expect(alertas, hasLength(1));
    expect(alertas.single.tipo, TipoAlerta.agotamientoProximo);
    expect(alertas.single.productoNombre, 'Etanol');
    expect(alertas.single.fecha, isNotNull);
  });

  test('un TP que pide más que el stock suma el aviso del TP', () async {
    final container = _contenedor(
      movimientos: Stream.value(const []),
      insumos: Stream.value([_insumo('p1', 'Etanol', stock: 10)]),
      tps: Stream.value([_tp('p1', 100)]),
    );
    await container.read(movimientosStockProvider.future);
    await container.read(insumosProvider.future);
    await container.read(tpsStreamProvider.future);

    final alertas = container.read(alertasProvider).requireValue;

    expect(alertas, hasLength(1));
    expect(alertas.single.tipo, TipoAlerta.tpSinCobertura);
    expect(alertas.single.trabajoPractico, 'PCR');
  });

  test('las de los insumos van antes que las de la predicción', () async {
    final container = _contenedor(
      movimientos: Stream.value([_salida('p1', 700, diasAtras: 2)]),
      insumos: Stream.value([
        _insumo('p1', 'Alcohol', stock: 10),
        _insumo('p2', 'Zinc', stock: 0),
      ]),
    );
    await container.read(movimientosStockProvider.future);
    await container.read(insumosProvider.future);
    await container.read(tpsStreamProvider.future);

    expect(_tipos(container), [
      TipoAlerta.sinStock,
      TipoAlerta.agotamientoProximo,
    ]);
  });

  test('si falla la lectura de los movimientos, las alertas siguen', () async {
    final container = _contenedor(
      movimientos: Stream.error(Exception('sin permiso')),
      insumos: Stream.value([_insumo('p1', 'Etanol', stock: 0)]),
    );
    await container.read(insumosProvider.future);
    await container.read(tpsStreamProvider.future);
    // Deja que el error del stream de movimientos llegue al provider.
    await Future<void>.delayed(Duration.zero);

    expect(container.read(alertasProvider).hasError, isFalse);
    expect(_tipos(container), [TipoAlerta.sinStock]);
  });

  test('mientras la predicción carga, ya se ven las alertas de los insumos', () async {
    final sinTerminar = StreamController<List<MovimientoStock>>();
    addTearDown(sinTerminar.close);
    final container = _contenedor(
      movimientos: sinTerminar.stream,
      insumos: Stream.value([_insumo('p1', 'Etanol', stock: 0)]),
    );
    await container.read(insumosProvider.future);

    expect(container.read(alertasProvider).isLoading, isFalse);
    expect(_tipos(container), [TipoAlerta.sinStock]);
  });

  test('si no se pueden leer los insumos, es un error', () async {
    final container = _contenedor(
      movimientos: Stream.value(const []),
      insumos: Stream.error(Exception('sin permiso')),
    );
    await Future<void>.delayed(Duration.zero);

    expect(container.read(alertasProvider).hasError, isTrue);
  });

  test('cuando entra un movimiento nuevo, el aviso aparece solo', () async {
    final movimientos = StreamController<List<MovimientoStock>>();
    addTearDown(movimientos.close);
    final container = _contenedor(
      movimientos: movimientos.stream,
      insumos: Stream.value([_insumo('p1', 'Etanol', stock: 10)]),
    );
    movimientos.add(const []);
    await container.read(movimientosStockProvider.future);
    await container.read(insumosProvider.future);
    await container.read(tpsStreamProvider.future);
    expect(_tipos(container), isEmpty);

    movimientos.add([_salida('p1', 700, diasAtras: 2)]);
    await Future<void>.delayed(Duration.zero);

    expect(_tipos(container), [TipoAlerta.agotamientoProximo]);
  });
}
