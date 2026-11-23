import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/movimiento_stock.dart';
import 'package:tpfinal_grupo2/models/trabajo_practico.dart';
import 'package:tpfinal_grupo2/providers/historial_provider.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/prediccion_provider.dart';
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

// Un trabajo práctico de hoy que pide [cantidad] del insumo [producto]. Como el
// provider usa la hora actual, se arma respecto de hoy. Es de hoy y no de
// mañana porque hoy siempre cae antes de la próxima compra, sin importar en
// qué día se corran los tests.
TrabajoPractico _tp(String producto, double cantidad) {
  return TrabajoPractico(
    id: 'tp-$producto',
    nombre: 'PCR',
    descripcion: '',
    fecha: DateTime.now(),
    docente: '',
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
    await container.read(tpsStreamProvider.future);

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
    await container.read(tpsStreamProvider.future);

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
    await container.read(tpsStreamProvider.future);

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
    await container.read(tpsStreamProvider.future);
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

  group('trabajos prácticos', () {
    test('un TP planificado se cruza con el stock del insumo', () async {
      final container = _contenedor(
        movimientos: Stream.value(const []),
        insumos: Stream.value([_insumo('p1', 'Etanol', stock: 2)]),
        tps: Stream.value([_tp('p1', 5)]),
      );
      await container.read(movimientosStockProvider.future);
      await container.read(insumosProvider.future);
      await container.read(tpsStreamProvider.future);

      final p = container.read(prediccionStockProvider).requireValue.single;

      expect(p.demandaPlanificada, 5);
      expect(p.faltaParaTps, isTrue);
      expect(p.primerTpSinCobertura!.nombre, 'PCR');
    });

    test('espera a que carguen los TP antes de dar la predicción', () async {
      // Los movimientos y los insumos ya llegaron, los TP todavía no.
      final tps = StreamController<List<TrabajoPractico>>();
      addTearDown(tps.close);
      final container = _contenedor(
        movimientos: Stream.value([_salida('p1', 14, diasAtras: 2)]),
        insumos: Stream.value([_insumo('p1', 'Etanol', stock: 10)]),
        tps: tps.stream,
      );
      await container.read(movimientosStockProvider.future);
      await container.read(insumosProvider.future);

      expect(container.read(prediccionStockProvider).isLoading, isTrue);

      tps.add(const []);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(prediccionStockProvider).hasValue, isTrue);
    });

    test('si los TP fallan, sigue con el ritmo de consumo', () async {
      final container = _contenedor(
        movimientos: Stream.value([_salida('p1', 14, diasAtras: 2)]),
        insumos: Stream.value([_insumo('p1', 'Etanol', stock: 10)]),
        tps: Stream.error(Exception('sin permisos')),
      );
      await container.read(movimientosStockProvider.future);
      await container.read(insumosProvider.future);
      await Future<void>.delayed(Duration.zero);

      final estado = container.read(prediccionStockProvider);

      expect(estado.hasError, isFalse);
      expect(estado.requireValue.single.diasRestantes, 5);
      expect(estado.requireValue.single.demandaPlanificada, 0);
    });

    test('un TP nuevo cambia la predicción en vivo', () async {
      final tps = StreamController<List<TrabajoPractico>>();
      addTearDown(tps.close);
      final container = _contenedor(
        movimientos: Stream.value(const []),
        insumos: Stream.value([_insumo('p1', 'Etanol', stock: 2)]),
        tps: tps.stream,
      );
      tps.add(const []);
      await container.read(movimientosStockProvider.future);
      await container.read(insumosProvider.future);
      await container.read(tpsStreamProvider.future);

      expect(container.read(prediccionStockProvider).requireValue, isEmpty);

      tps.add([_tp('p1', 5)]);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(prediccionStockProvider).requireValue.single.faltaParaTps,
        isTrue,
      );
    });
  });

  group('ventana de la predicción', () {
    // Dos insumos con 1 unidad por día durante 150 días y una salida única de
    // 100 unidades hace 40 días: un pico aislado, con el que la ventana de 60
    // días se equivoca menos que la de 30.
    List<MovimientoStock> historialConPico() => [
          for (final p in ['p1', 'p2']) ...[
            for (var dias = 150; dias >= 0; dias--) _salida(p, 1, diasAtras: dias),
            _salida(p, 100, diasAtras: 40),
          ],
        ];

    test('sin historial usa 30 días y dice que no pudo elegir', () async {
      final container = _contenedor(
        movimientos: Stream.value(const []),
        insumos: Stream.value([_insumo('p1', 'Etanol')]),
      );
      await container.read(movimientosStockProvider.future);

      final ventana = container.read(ventanaPrediccionProvider).requireValue;

      expect(ventana.ventanaDias, 30);
      expect(ventana.elegidaPorHistorial, isFalse);
    });

    test('con historial elige la que menos se equivoca', () async {
      final container = _contenedor(
        movimientos: Stream.value(historialConPico()),
        insumos: Stream.value([_insumo('p1', 'Etanol'), _insumo('p2', 'Pipetas')]),
      );
      await container.read(movimientosStockProvider.future);

      final ventana = container.read(ventanaPrediccionProvider).requireValue;

      expect(ventana.elegidaPorHistorial, isTrue);
      expect(ventana.ventanaDias, 60);
      expect(
        ventana.errorRelativoPorVentana[60]!,
        lessThan(ventana.errorRelativoPorVentana[30]!),
      );
    });

    test('la predicción usa la ventana elegida', () async {
      final container = _contenedor(
        movimientos: Stream.value(historialConPico()),
        insumos: Stream.value([
          _insumo('p1', 'Etanol', stock: 100),
          _insumo('p2', 'Pipetas', stock: 100),
        ]),
      );
      await container.read(movimientosStockProvider.future);
      await container.read(insumosProvider.future);
      await container.read(tpsStreamProvider.future);

      final p1 = container
          .read(prediccionStockProvider)
          .requireValue
          .firstWhere((p) => p.productoId == 'p1');

      // Con 60 días entran 60 salidas de 1 unidad y el pico de 100: 160 / 60.
      // Con 30 días habría sido 1 por día, porque el pico queda afuera.
      expect(p1.consumoDiario, closeTo(160 / 60, 0.01));
    });

    test('mientras llegan los movimientos está cargando', () {
      final container = _contenedor(
        movimientos: StreamController<List<MovimientoStock>>().stream,
        insumos: Stream.value([_insumo('p1', 'Etanol')]),
      );

      expect(container.read(ventanaPrediccionProvider).isLoading, isTrue);
    });

    test('un error al leer los movimientos se propaga', () async {
      final container = _contenedor(
        movimientos: Stream.error(Exception('sin conexión')),
        insumos: Stream.value([_insumo('p1', 'Etanol')]),
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(ventanaPrediccionProvider).hasError, isTrue);
    });
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
