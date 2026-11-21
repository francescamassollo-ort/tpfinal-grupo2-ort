import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/screens/consumo/consumo_screen.dart';

Insumo _insumo(String id, String nombre, int stock) => Insumo(
      id: id,
      nombre: nombre,
      tipo: InsumoTipo.comprado,
      stock: stock,
      ubicacion: 'Estante 1',
      umbralMinimo: 2,
    );

final _insumos = [
  _insumo('p1', 'Etanol', 12),
  _insumo('p2', 'Agar LB', 7),
];

// Monta la pantalla con insumos de mentira, sin Firebase.
Future<void> _abrir(WidgetTester tester, {String? insumoId}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        insumosProvider.overrideWith((ref) => Stream.value(_insumos)),
      ],
      child: MaterialApp(
        home: Scaffold(body: ConsumoScreen(insumoId: insumoId)),
      ),
    ),
  );
  // Deja que llegue el stream de los insumos.
  await tester.pump();
}

void main() {
  testWidgets('sin insumo elegido no muestra el stock de ninguno', (tester) async {
    await _abrir(tester);

    expect(find.textContaining('Stock actual'), findsNothing);
  });

  testWidgets('con un insumo elegido aparece ya seleccionado', (tester) async {
    await _abrir(tester, insumoId: 'p2');

    expect(find.text('Agar LB'), findsOneWidget);
    expect(find.text('Stock actual: 7 unidades'), findsOneWidget);
  });

  testWidgets('un id que no existe se ignora y no rompe la pantalla', (tester) async {
    await _abrir(tester, insumoId: 'no-existe');

    expect(tester.takeException(), isNull);
    expect(find.text('Registrar consumo'), findsWidgets);
    expect(find.textContaining('Stock actual'), findsNothing);
  });

  testWidgets('el insumo elegido se puede cambiar por otro', (tester) async {
    await _abrir(tester, insumoId: 'p1');
    expect(find.text('Stock actual: 12 unidades'), findsOneWidget);

    await tester.tap(find.text('Etanol'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agar LB').last);
    await tester.pumpAndSettle();

    expect(find.text('Stock actual: 7 unidades'), findsOneWidget);
  });
}
