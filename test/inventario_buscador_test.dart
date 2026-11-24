import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/inventario_filter_provider.dart';
import 'package:tpfinal_grupo2/screens/inventario/inventario_screen.dart';

void main() {
  testWidgets('al volver a Inventario el buscador conserva el texto que filtra', (tester) async {
    final container = ProviderContainer(overrides: [
      insumosProvider.overrideWith((ref) => Stream.value(<Insumo>[])),
    ]);
    addTearDown(container.dispose);
    Future<void> mostrar(Widget w) async {
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Scaffold(body: w)),
      ));
      await tester.pump();
    }

    await mostrar(const InventarioScreen());
    await tester.enterText(find.byType(TextField), 'Bromuro');
    await tester.pump();

    await mostrar(const Text('otra pantalla'));
    await mostrar(const InventarioScreen());

    expect(find.text('Bromuro'), findsOneWidget);
    expect(container.read(inventarioFilterProvider).searchText, 'Bromuro');
  });
}
