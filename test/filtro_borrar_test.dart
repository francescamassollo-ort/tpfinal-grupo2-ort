import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/providers/inventario_filter_provider.dart';
import 'package:tpfinal_grupo2/screens/inventario/filtro_dialog.dart';

void main() {
  testWidgets('"Borrar filtros" deja todo en "Todos" y "Filtrar" devuelve el filtro vacío',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    InventarioFilter? resultado;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => resultado = await showDialog<InventarioFilter>(
              context: context,
              builder: (_) => const FiltroDialog(
                filtroActual: InventarioFilter(
                  sort: InventarioSort.stockMayor,
                  estado: EstadoStock.sinStock,
                ),
                insumos: <Insumo>[],
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Sin stock'), findsOneWidget);

    await tester.tap(find.text('Borrar filtros'));
    await tester.pumpAndSettle();
    expect(find.text('Sin stock'), findsNothing);

    await tester.tap(find.text('Filtrar'));
    await tester.pumpAndSettle();

    expect(resultado?.estado, isNull);
    expect(resultado?.sort, InventarioSort.nombre);
  });
}
