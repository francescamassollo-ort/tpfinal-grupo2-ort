import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/usuario.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/inventario_filter_provider.dart';
import 'package:tpfinal_grupo2/providers/role_provider.dart';
import 'package:tpfinal_grupo2/screens/inventario/filtro_dialog.dart';
import 'package:tpfinal_grupo2/screens/inventario/insumo_detalle_screen.dart';

Insumo _insumo(String nombre, int stock, {num umbral = 2, String? categoria, String? proveedor, InsumoTipo tipo = InsumoTipo.comprado}) =>
    Insumo(
      id: nombre,
      nombre: nombre,
      tipo: tipo,
      stock: stock,
      ubicacion: 'Armario 1',
      umbralMinimo: umbral,
      categoria: categoria,
      proveedor: proveedor,
    );

void main() {
  group('EstadoStock', () {
    test('cero es sin stock, en el mínimo o por debajo es bajo, por encima es en stock', () {
      expect(EstadoStock.de(_insumo('a', 0)), EstadoStock.sinStock);
      expect(EstadoStock.de(_insumo('b', 1)), EstadoStock.stockBajo);
      expect(EstadoStock.de(_insumo('c', 2)), EstadoStock.stockBajo);
      expect(EstadoStock.de(_insumo('d', 3)), EstadoStock.enStock);
    });

    test('un mínimo en cero: con stock es en stock y sin stock es sin stock', () {
      expect(EstadoStock.de(_insumo('a', 0, umbral: 0)), EstadoStock.sinStock);
      expect(EstadoStock.de(_insumo('b', 1, umbral: 0)), EstadoStock.enStock);
    });
  });

  group('filtro por estado en el Inventario', () {
    ProviderContainer contenedor() {
      final c = ProviderContainer(
        overrides: [
          insumosProvider.overrideWith(
            (ref) => Stream.value([
              _insumo('Sin nada', 0),
              _insumo('Casi sin', 2),
              _insumo('Sobra', 9),
              _insumo('Sobra más', 20),
            ]),
          ),
        ],
      );
      addTearDown(c.dispose);
      c.listen(inventarioFiltradoProvider, (_, _) {});
      return c;
    }

    Future<List<String>> nombres(ProviderContainer c) async {
      await c.read(insumosProvider.future);
      return [for (final i in c.read(inventarioFiltradoProvider).requireValue) i.nombre];
    }

    test('sin elegir un estado se ven todos', () async {
      expect(await nombres(contenedor()), hasLength(4));
    });

    test('cada estado deja solo los suyos', () async {
      final c = contenedor();
      final notifier = c.read(inventarioFilterProvider.notifier);

      notifier.applyFilters(sort: InventarioSort.nombre, estado: EstadoStock.sinStock);
      expect(await nombres(c), ['Sin nada']);

      notifier.applyFilters(sort: InventarioSort.nombre, estado: EstadoStock.stockBajo);
      expect(await nombres(c), ['Casi sin']);

      notifier.applyFilters(sort: InventarioSort.nombre, estado: EstadoStock.enStock);
      expect(await nombres(c), ['Sobra', 'Sobra más']);
    });

    test('el estado se conserva cuando se escribe en el buscador', () async {
      final c = contenedor();
      final notifier = c.read(inventarioFilterProvider.notifier);
      notifier.applyFilters(sort: InventarioSort.nombre, estado: EstadoStock.enStock);

      notifier.setSearchText('más');

      expect(c.read(inventarioFilterProvider).estado, EstadoStock.enStock);
      expect(await nombres(c), ['Sobra más']);
    });

    test('se combina con los otros filtros', () async {
      final c = contenedor();
      c.read(inventarioFilterProvider.notifier).applyFilters(
            sort: InventarioSort.stockMayor,
            estado: EstadoStock.enStock,
            ubicacion: 'Armario 1',
          );

      expect(await nombres(c), ['Sobra más', 'Sobra']);
    });
  });

  group('panel de filtros', () {
    // Abre el panel y guarda en [resultado] lo que devuelve al cerrarse.
    Future<void> abrir(
      WidgetTester tester, {
      InventarioFilter actual = const InventarioFilter(),
      List<InventarioFilter?>? resultado,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  final devuelto = await showDialog<InventarioFilter>(
                    context: context,
                    builder: (_) => FiltroDialog(
                      filtroActual: actual,
                      insumos: [_insumo('A', 1)],
                    ),
                  );
                  resultado?.add(devuelto);
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('ofrece elegir el estado del stock y lo devuelve', (tester) async {
      final resultado = <InventarioFilter?>[];
      await abrir(tester, resultado: resultado);
      expect(find.text('Estado del stock'), findsOneWidget);

      await tester.tap(find.text('Estado del stock'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stock bajo').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Filtrar'));
      await tester.pumpAndSettle();

      expect(resultado.single?.estado, EstadoStock.stockBajo);
    });

    testWidgets('sin tocar el estado, devuelve "todos"', (tester) async {
      final resultado = <InventarioFilter?>[];
      await abrir(tester, resultado: resultado);

      await tester.tap(find.text('Filtrar'));
      await tester.pumpAndSettle();

      expect(resultado.single?.estado, isNull);
    });

    testWidgets('abre con el estado que ya estaba elegido', (tester) async {
      await abrir(tester, actual: const InventarioFilter(estado: EstadoStock.sinStock));

      expect(find.text('Sin stock'), findsOneWidget);
    });
  });

  group('ficha del detalle', () {
    Future<void> abrir(WidgetTester tester, Insumo insumo) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            insumosProvider.overrideWith((ref) => Stream.value([insumo])),
            rolDeSesionProvider.overrideWith((ref) => Stream.value(UserRole.docente)),
          ],
          child: MaterialApp(
            home: Scaffold(body: InsumoDetalleScreen(insumoId: insumo.id)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('un producto comprado muestra su categoría y su proveedor', (tester) async {
      await abrir(tester, _insumo('Etanol', 5, categoria: 'Alcoholes y solventes', proveedor: 'Droguería Sur'));

      expect(find.text('Categoría'), findsOneWidget);
      expect(find.text('Alcoholes y solventes'), findsOneWidget);
      expect(find.text('Proveedor'), findsOneWidget);
      expect(find.text('Droguería Sur'), findsOneWidget);
    });

    testWidgets('si no tiene categoría ni proveedor, dice "—"', (tester) async {
      await abrir(tester, _insumo('Etanol', 5));

      expect(find.text('Categoría'), findsOneWidget);
      expect(find.text('—'), findsWidgets);
    });

    testWidgets('una solución preparada muestra su categoría', (tester) async {
      await abrir(
        tester,
        _insumo('Buffer', 2, categoria: 'Buffers y soluciones', tipo: InsumoTipo.solucion),
      );

      expect(find.text('Buffers y soluciones'), findsOneWidget);
      expect(find.text('Proveedor'), findsNothing);
    });
  });
}
