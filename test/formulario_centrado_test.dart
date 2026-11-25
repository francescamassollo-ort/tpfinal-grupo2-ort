import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/core/breakpoints.dart';
import 'package:tpfinal_grupo2/widgets/formulario_centrado.dart';

const _contenido = Key('contenido');

// Monta un contenido de [alto] px dentro del formulario, con una ventana de
// [ancho] x [altoVentana] (sin escala, para que los números sean exactos).
Future<void> _mostrar(
  WidgetTester tester, {
  required double ancho,
  required double altoVentana,
  required double alto,
  double? maxWidth,
}) async {
  tester.view.physicalSize = Size(ancho, altoVentana);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: maxWidth == null
              ? FormularioCentrado(
                  child: SizedBox(key: _contenido, height: alto),
                )
              : FormularioCentrado(
                  maxWidth: maxWidth,
                  child: SizedBox(key: _contenido, height: alto),
                ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('en una ventana ancha se limita y queda en el centro',
      (tester) async {
    await _mostrar(tester, ancho: 1400, altoVentana: 900, alto: 200);

    final caja = tester.getRect(find.byKey(_contenido));
    expect(caja.width, Breakpoints.maxFormWidth);
    expect(caja.center.dx, 700); // centro horizontal de la ventana
    expect(caja.center.dy, 450); // centro vertical de la ventana
  });

  testWidgets('en un celular ocupa todo el ancho', (tester) async {
    await _mostrar(tester, ancho: 360, altoVentana: 800, alto: 200);

    expect(tester.getSize(find.byKey(_contenido)).width, 360);
  });

  testWidgets('acepta un ancho máximo propio', (tester) async {
    await _mostrar(
      tester,
      ancho: 1400,
      altoVentana: 900,
      alto: 200,
      maxWidth: 300,
    );

    expect(tester.getSize(find.byKey(_contenido)).width, 300);
  });

  testWidgets('si el contenido no entra, arranca arriba y se desliza',
      (tester) async {
    await _mostrar(tester, ancho: 1400, altoVentana: 600, alto: 2000);

    expect(tester.takeException(), isNull);
    final caja = tester.getRect(find.byKey(_contenido));
    expect(caja.top, 0);
    expect(caja.height, 2000);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pump();

    expect(tester.getRect(find.byKey(_contenido)).top, -500);
  });
}