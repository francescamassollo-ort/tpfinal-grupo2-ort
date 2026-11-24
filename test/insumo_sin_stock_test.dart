import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/widgets/insumo_card.dart';

Insumo _insumo(int stock) => Insumo(
      id: 'i1',
      nombre: 'Etanol',
      tipo: InsumoTipo.comprado,
      stock: stock,
      ubicacion: 'Armario 1',
      umbralMinimo: 2,
    );

Future<void> _mostrar(WidgetTester tester, Insumo insumo) => tester.pumpWidget(
      MaterialApp(home: Scaffold(body: InsumoCard(insumo: insumo))),
    );

void main() {
  testWidgets('con stock en cero dice "Sin stock", no "Stock bajo"', (tester) async {
    await _mostrar(tester, _insumo(0));

    expect(find.text('Sin stock'), findsOneWidget);
    expect(find.text('Stock bajo'), findsNothing);
  });

  testWidgets('la tarjeta sin stock es gris y la de stock bajo no', (tester) async {
    await _mostrar(tester, _insumo(0));
    expect(tester.widget<Card>(find.byType(Card)).color, isNotNull);

    await _mostrar(tester, _insumo(1));
    expect(find.text('Stock bajo'), findsOneWidget);
    expect(tester.widget<Card>(find.byType(Card)).color, isNull);
  });
}
