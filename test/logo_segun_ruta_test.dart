import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tpfinal_grupo2/widgets/logo_ort.dart';

/// Un router como el de la app: se arranca en "inventario" y, sin sesión, una
/// redirección inmediata manda a Bienvenida.
GoRouter _router({bool conSesion = false}) => GoRouter(
      initialLocation: 'inventario',
      redirect: (context, state) {
        final ruta = state.uri.path;
        if (!conSesion && ruta == '/inventario') return '/welcome';
        return null;
      },
      routes: [
        GoRoute(path: '/welcome', builder: (c, s) => const Text('BIENVENIDA')),
        GoRoute(path: '/login', builder: (c, s) => const Text('INGRESO')),
        GoRoute(path: '/inventario', builder: (c, s) => const Text('INVENTARIO')),
        GoRoute(path: '/alertas', builder: (c, s) => const Text('ALERTAS')),
      ],
    );

Future<GoRouter> _abrir(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => Scaffold(
        body: LogoSegunRuta(router: router, child: child!),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('al abrir sin sesión, en Bienvenida no se repite el logo chico', (tester) async {
    await _abrir(tester, _router());

    expect(find.text('BIENVENIDA'), findsOneWidget);
    expect(find.byType(LogoOrt), findsNothing);
  });

  testWidgets('al abrir con sesión, Inventario sí lleva el logo chico', (tester) async {
    await _abrir(tester, _router(conSesion: true));

    expect(find.text('INVENTARIO'), findsOneWidget);
    expect(find.byType(LogoOrt), findsOneWidget);
  });

  testWidgets('al navegar, el logo aparece y desaparece según la pantalla', (tester) async {
    final router = await _abrir(tester, _router(conSesion: true));
    expect(find.byType(LogoOrt), findsOneWidget);

    router.go('/login');
    await tester.pumpAndSettle();
    expect(find.text('INGRESO'), findsOneWidget);
    expect(find.byType(LogoOrt), findsNothing);

    router.go('/alertas');
    await tester.pumpAndSettle();
    expect(find.text('ALERTAS'), findsOneWidget);
    expect(find.byType(LogoOrt), findsOneWidget);
  });

  testWidgets('con la ruta todavía sin resolver no muestra el logo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PantallaConLogo(ruta: '', child: Text('CONTENIDO'))),
      ),
    );

    expect(find.byType(LogoOrt), findsNothing);
    expect(find.text('CONTENIDO'), findsOneWidget);
  });
}
