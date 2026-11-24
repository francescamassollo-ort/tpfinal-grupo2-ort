import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/filtro_historial.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/movimiento_stock.dart';
import 'package:tpfinal_grupo2/providers/historial_provider.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';

Insumo _insumo(String id, String nombre) => Insumo(
      id: id,
      nombre: nombre,
      tipo: InsumoTipo.comprado,
      stock: 10,
      ubicacion: 'Estante 1',
      umbralMinimo: 2,
    );

MovimientoStock _mov(
  String id, {
  required String producto,
  required TipoMovimiento tipo,
  DateTime? fecha,
}) {
  return MovimientoStock(
    id: id,
    productoId: producto,
    usuarioId: 'u1',
    usuarioNombre: 'Juan Perez',
    tipo: tipo,
    cantidad: 5,
    fecha: fecha ?? DateTime(2026, 11, 10, 12),
  );
}

// Un contenedor con movimientos e insumos de mentira, sin Firebase.
Future<ProviderContainer> _contenedor() async {
  final container = ProviderContainer(
    overrides: [
      movimientosStockProvider.overrideWith(
        (ref) => Stream.value([
          _mov('a', producto: 'p1', tipo: TipoMovimiento.entrada),
          _mov('b', producto: 'p2', tipo: TipoMovimiento.salida),
          _mov(
            'c',
            producto: 'p1',
            tipo: TipoMovimiento.salida,
            fecha: DateTime(2026, 11, 1, 9),
          ),
        ]),
      ),
      insumosConBajasProvider.overrideWith(
        (ref) => Stream.value([_insumo('p1', 'Etanol'), _insumo('p2', 'Pipetas')]),
      ),
    ],
  );
  addTearDown(container.dispose);
  // Como la pantalla real, el test tiene que escuchar los providers: en
  // Riverpod 3 un stream que nadie escucha queda pausado y nunca entrega.
  for (final provider in [movimientosStockProvider, insumosConBajasProvider]) {
    container.listen(provider, (previous, next) {});
  }
  container.listen(historialProvider, (previous, next) {});
  // Espera a que los dos streams entreguen su primer valor.
  await container.read(movimientosStockProvider.future);
  await container.read(insumosConBajasProvider.future);
  return container;
}

List<String> _ids(ProviderContainer container) => [
      for (final item in container.read(historialProvider).requireValue) item.id,
    ];

void main() {
  test('sin filtro muestra todos los movimientos', () async {
    final container = await _contenedor();

    expect(_ids(container), ['a', 'b', 'c']);
  });

  test('el filtro por tipo deja solo ese tipo', () async {
    final container = await _contenedor();

    container
        .read(filtroHistorialProvider.notifier)
        .cambiar(const FiltroHistorial(tipo: TipoMovimiento.salida));

    expect(_ids(container), ['b', 'c']);
  });

  test('el filtro por insumo usa el id del insumo', () async {
    final container = await _contenedor();

    container
        .read(filtroHistorialProvider.notifier)
        .cambiar(const FiltroHistorial(productoId: 'p1'));

    expect(_ids(container), ['a', 'c']);
  });

  test('los filtros se combinan con las fechas', () async {
    final container = await _contenedor();

    container.read(filtroHistorialProvider.notifier).cambiar(
          FiltroHistorial(
            productoId: 'p1',
            hasta: DateTime(2026, 11, 5),
          ),
        );

    expect(_ids(container), ['c']);
  });

  test('limpiar vuelve a mostrar todo', () async {
    final container = await _contenedor();
    final notifier = container.read(filtroHistorialProvider.notifier);

    notifier.cambiar(const FiltroHistorial(productoId: 'p2'));
    expect(_ids(container), ['b']);

    notifier.limpiar();
    expect(container.read(filtroHistorialProvider).estaVacio, isTrue);
    expect(_ids(container), ['a', 'b', 'c']);
  });

  test('un filtro sin coincidencias da una lista vacía, no un error', () async {
    final container = await _contenedor();

    container
        .read(filtroHistorialProvider.notifier)
        .cambiar(const FiltroHistorial(productoId: 'no-existe'));

    expect(container.read(historialProvider).hasError, isFalse);
    expect(_ids(container), isEmpty);
  });

  test('dos filtros con los mismos valores son iguales', () {
    expect(
      const FiltroHistorial(productoId: 'p1', tipo: TipoMovimiento.entrada),
      const FiltroHistorial(productoId: 'p1', tipo: TipoMovimiento.entrada),
    );
    expect(
      const FiltroHistorial(productoId: 'p1'),
      isNot(const FiltroHistorial(productoId: 'p2')),
    );
  });
}
