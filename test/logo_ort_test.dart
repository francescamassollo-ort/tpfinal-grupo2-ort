import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/widgets/logo_ort.dart';

Future<void> _mostrar(WidgetTester tester, String ruta) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PantallaConLogo(ruta: ruta, child: const Text('CONTENIDO')),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('PantallaConLogo', () {
    testWidgets('pone el logo arriba y deja el contenido', (tester) async {
      await _mostrar(tester, '/inventario');

      expect(find.byType(LogoOrt), findsOneWidget);
      expect(find.text('CONTENIDO'), findsOneWidget);
      // Arriba del contenido y centrado.
      final logo = tester.getCenter(find.byType(LogoOrt));
      final contenido = tester.getCenter(find.text('CONTENIDO'));
      final ancho = tester.getSize(find.byType(MaterialApp)).width;
      expect(logo.dy, lessThan(contenido.dy));
      expect(logo.dx, closeTo(ancho / 2, 1));
    });

    testWidgets('lo muestra en las pantallas internas y de acceso', (tester) async {
      for (final ruta in ['/inventario', '/historial', '/usuarios', '/register', '/verificar-email']) {
        await _mostrar(tester, ruta);
        expect(find.byType(LogoOrt), findsOneWidget, reason: ruta);
      }
    });

    testWidgets('no lo repite donde ya hay un logo grande ni en la cámara', (tester) async {
      for (final ruta in ['/welcome', '/login', '/scanner']) {
        await _mostrar(tester, ruta);
        expect(find.byType(LogoOrt), findsNothing, reason: ruta);
        expect(find.text('CONTENIDO'), findsOneWidget, reason: ruta);
      }
    });

    testWidgets('el logo tiene el alto pedido y una descripción para lectores de pantalla',
        (tester) async {
      await _mostrar(tester, '/inventario');

      expect(tester.getSize(find.byType(LogoOrt)).height, PantallaConLogo.altoLogo);
      expect(
        find.bySemanticsLabel('ORT Argentina, Educando para la vida'),
        findsOneWidget,
      );
    });
  });

  testWidgets('el archivo del logo existe y se puede dibujar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: LogoOrt(ancho: 200)))),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(LogoOrt)).width, 200);
  });
}
