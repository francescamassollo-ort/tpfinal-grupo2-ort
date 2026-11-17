import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/widgets/outlined_list_card.dart';

Widget _envuelto(Widget hijo) => MaterialApp(home: Scaffold(body: hijo));

void main() {
  testWidgets('con onTap, al tocar la tarjeta se llama al callback', (tester) async {
    var toques = 0;
    await tester.pumpWidget(
      _envuelto(
        OutlinedListCard(onTap: () => toques++, child: const Text('Etanol')),
      ),
    );

    await tester.tap(find.text('Etanol'));

    expect(toques, 1);
  });

  testWidgets('con onTap, toda la tarjeta responde, no solo el texto', (tester) async {
    var toques = 0;
    await tester.pumpWidget(
      _envuelto(
        OutlinedListCard(onTap: () => toques++, child: const Text('Etanol')),
      ),
    );

    // Un punto de la tarjeta lejos del texto, cerca del borde izquierdo.
    final esquina = tester.getTopLeft(find.byType(OutlinedListCard));
    await tester.tapAt(esquina + const Offset(6, 30));

    expect(toques, 1);
  });

  testWidgets('sin onTap no se puede tocar', (tester) async {
    await tester.pumpWidget(
      _envuelto(const OutlinedListCard(child: Text('Etanol'))),
    );

    expect(
      find.descendant(
        of: find.byType(OutlinedListCard),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
  });

  testWidgets('con y sin onTap el contenido queda en el mismo lugar', (tester) async {
    await tester.pumpWidget(
      _envuelto(const OutlinedListCard(child: Text('Etanol'))),
    );
    final sinToque = tester.getTopLeft(find.text('Etanol'));

    await tester.pumpWidget(
      _envuelto(OutlinedListCard(onTap: () {}, child: const Text('Etanol'))),
    );
    final conToque = tester.getTopLeft(find.text('Etanol'));

    expect(conToque, sinToque);
  });

  testWidgets('con y sin onTap la tarjeta mide lo mismo', (tester) async {
    await tester.pumpWidget(
      _envuelto(const OutlinedListCard(child: Text('Etanol'))),
    );
    final sinToque = tester.getSize(find.byType(OutlinedListCard));

    await tester.pumpWidget(
      _envuelto(OutlinedListCard(onTap: () {}, child: const Text('Etanol'))),
    );
    final conToque = tester.getSize(find.byType(OutlinedListCard));

    expect(conToque, sinToque);
    expect(sinToque.height, greaterThanOrEqualTo(72));
  });
}
