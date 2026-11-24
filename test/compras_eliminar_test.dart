import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/core/app_strings.dart';
import 'package:tpfinal_grupo2/models/lista_compra.dart';
import 'package:tpfinal_grupo2/providers/lista_compra_provider.dart';
import 'package:tpfinal_grupo2/screens/compras/compras_screen.dart';
import 'package:tpfinal_grupo2/screens/compras/item_compra.dart';

class _Acciones implements ComprasAcciones {
  final eliminados = <String>[];

  @override
  Future<void> eliminar(Iterable<String> ids) async => eliminados.addAll(ids);

  @override
  Future<void> cambiarEstado(String id, EstadoCompra estado) async {}
  @override
  Future<void> incrementar(String id) async {}
  @override
  Future<void> decrementar(String id) async {}
  @override
  Future<void> agregar(String productoId, int cantidad) async {}
  @override
  Future<int> agregarSugerencias() async => 0;
}

const _items = [
  ItemCompra(id: '1', nombre: 'Guantes', stock: 3, cantidadSolicitada: 8),
  ItemCompra(id: '2', nombre: 'Agar LB', stock: 0, cantidadSolicitada: 5),
  ItemCompra(id: '3', nombre: 'Etanol', stock: 1, cantidadSolicitada: 2),
];

Future<_Acciones> _abrir(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2700);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final acciones = _Acciones();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        itemsCompraProvider.overrideWith((ref) => const AsyncData(_items)),
        comprasAccionesProvider.overrideWithValue(acciones),
      ],
      child: const MaterialApp(home: ComprasScreen()),
    ),
  );
  await tester.pump();
  return acciones;
}

void main() {
  testWidgets('ya no hay lupa', (tester) async {
    await _abrir(tester);
    expect(find.byIcon(Icons.search), findsNothing);
  });

  testWidgets('el tacho abre el modo eliminar y se eligen ítems', (tester) async {
    await _abrir(tester);
    await tester.tap(find.byTooltip(AppStrings.comprasSeleccionar));
    await tester.pump();

    expect(find.byType(Checkbox), findsNWidgets(3));
    expect(find.text('0 seleccionados'), findsOneWidget);

    await tester.tap(find.text('Guantes'));
    await tester.pump();
    expect(find.text('1 seleccionado'), findsOneWidget);

    await tester.tap(find.text(AppStrings.comprasSeleccionarTodos));
    await tester.pump();
    expect(find.text('3 seleccionados'), findsOneWidget);
  });

  testWidgets('eliminar pide confirmar y borra solo lo elegido', (tester) async {
    final acciones = await _abrir(tester);
    await tester.tap(find.byTooltip(AppStrings.comprasSeleccionar));
    await tester.pump();
    await tester.tap(find.text('Agar LB'));
    await tester.pump();

    await tester.tap(find.byTooltip(AppStrings.comprasEliminarSeleccionados));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.comprasEliminarTitulo), findsOneWidget);
    expect(acciones.eliminados, isEmpty);

    await tester.tap(find.text(AppStrings.comprasEliminarConfirmar));
    await tester.pumpAndSettle();

    expect(acciones.eliminados, ['2']);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('cancelar la confirmación no borra nada', (tester) async {
    final acciones = await _abrir(tester);
    await tester.tap(find.byTooltip(AppStrings.comprasSeleccionar));
    await tester.pump();
    await tester.tap(find.text('Etanol'));
    await tester.pump();
    await tester.tap(find.byTooltip(AppStrings.comprasEliminarSeleccionados));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.cancelar));
    await tester.pumpAndSettle();

    expect(acciones.eliminados, isEmpty);
  });

  testWidgets('cancelar la selección vuelve a la lista normal', (tester) async {
    await _abrir(tester);
    await tester.tap(find.byTooltip(AppStrings.comprasSeleccionar));
    await tester.pump();
    await tester.tap(find.byTooltip(AppStrings.comprasCancelarSeleccion));
    await tester.pump();

    expect(find.byType(Checkbox), findsNothing);
    expect(find.byTooltip(AppStrings.comprasSeleccionar), findsOneWidget);
  });
}
