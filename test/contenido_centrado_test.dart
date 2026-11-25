import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/core/breakpoints.dart';
import 'package:tpfinal_grupo2/widgets/contenido_centrado.dart';

Future<void> _mostrar(WidgetTester tester, {required double ancho}) async {
  tester.view.physicalSize = Size(ancho, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: ContenidoCentrado(child: SizedBox.expand(key: Key('contenido'))),
      ),
    ),
  );
}

void main() {
  testWidgets('en una ventana ancha el contenido se limita y se centra',
      (tester) async {
    await _mostrar(tester, ancho: 1400);

    final caja = tester.getRect(find.byKey(const Key('contenido')));
    expect(caja.width, Breakpoints.maxContentWidth);
    expect(caja.center.dx, 700);
  });

  testWidgets('en un celular ocupa todo el ancho', (tester) async {
    await _mostrar(tester, ancho: 400);

    expect(tester.getSize(find.byKey(const Key('contenido'))).width, 400);
  });

  testWidgets('acepta un ancho máximo propio', (tester) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContenidoCentrado(
            maxWidth: 300,
            child: SizedBox.expand(key: Key('contenido')),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const Key('contenido'))).width, 300);
  });

  test('esAncho separa celular de escritorio en el breakpoint', () {
    expect(Breakpoints.esAncho(Breakpoints.compact - 1), isFalse);
    expect(Breakpoints.esAncho(Breakpoints.compact), isTrue);
  });
}