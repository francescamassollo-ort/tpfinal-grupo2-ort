import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tpfinal_grupo2/providers/auth_provider.dart';
import 'package:tpfinal_grupo2/screens/auth/login_screen.dart';

import 'helpers/auth_falso.dart';

Future<void> _abrir(WidgetTester tester, AuthFalso auth) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const Scaffold(body: Text('PANTALLA REGISTRO')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authServiceProvider.overrideWithValue(auth)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _campo(String pista) => find.widgetWithText(TextField, pista);

void main() {
  testWidgets('con mail y contraseña inicia sesión con el mail sin espacios',
      (tester) async {
    final auth = AuthFalso();
    await _abrir(tester, auth);
    await tester.enterText(_campo('Email Institucional'), ' ana@comunidadort.edu.ar ');
    await tester.enterText(_campo('Contraseña'), 'Abcdef1!');

    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    expect(auth.ingresos, ['ana@comunidadort.edu.ar|Abcdef1!']);
    expect(find.text('Ingreso exitoso.'), findsOneWidget);
  });

  testWidgets('con campos vacíos avisa y no va a Firebase', (tester) async {
    final auth = AuthFalso();
    await _abrir(tester, auth);

    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    expect(find.text('No dejar espacio vacio en campo Email!!!'), findsOneWidget);
    expect(auth.ingresos, isEmpty);
  });

  testWidgets('si Firebase rechaza el ingreso no dice "Ingreso exitoso"',
      (tester) async {
    final auth = AuthFalso()..ingresar = false;
    await _abrir(tester, auth);
    await tester.enterText(_campo('Email Institucional'), 'ana@comunidadort.edu.ar');
    await tester.enterText(_campo('Contraseña'), 'mala');

    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    expect(auth.ingresos, hasLength(1));
    expect(find.text('Ingreso exitoso.'), findsNothing);
  });

  group('Olvidé mi contraseña', () {
    testWidgets('pide el correo para el mail escrito', (tester) async {
      final auth = AuthFalso();
      await _abrir(tester, auth);
      await tester.enterText(_campo('Email Institucional'), ' ana@comunidadort.edu.ar ');

      await tester.tap(find.text('Olvidé mi contraseña'));
      await tester.pump();

      expect(auth.recuperaciones, ['ana@comunidadort.edu.ar']);
      expect(find.textContaining('Si ese mail tiene una cuenta'), findsOneWidget);
    });

    testWidgets('sin mail escrito explica qué hacer y no pide nada', (tester) async {
      final auth = AuthFalso();
      await _abrir(tester, auth);

      await tester.tap(find.text('Olvidé mi contraseña'));
      await tester.pump();

      expect(auth.recuperaciones, isEmpty);
      expect(find.textContaining('Escribí tu mail en el campo Email'), findsOneWidget);
    });

    testWidgets('si no se pudo mandar, no dice que se mandó', (tester) async {
      final auth = AuthFalso()..recuperar = false;
      await _abrir(tester, auth);
      await tester.enterText(_campo('Email Institucional'), 'ana@comunidadort.edu.ar');

      await tester.tap(find.text('Olvidé mi contraseña'));
      await tester.pump();

      expect(auth.recuperaciones, hasLength(1));
      expect(find.textContaining('Si ese mail tiene una cuenta'), findsNothing);
    });

    testWidgets('aunque el mail no sea institucional lo intenta: la cuenta puede ser vieja',
        (tester) async {
      final auth = AuthFalso();
      await _abrir(tester, auth);
      await tester.enterText(_campo('Email Institucional'), 'vieja@gmail.com');

      await tester.tap(find.text('Olvidé mi contraseña'));
      await tester.pump();

      expect(auth.recuperaciones, ['vieja@gmail.com']);
    });
  });

  testWidgets('"Crear una nueva cuenta" lleva al registro', (tester) async {
    await _abrir(tester, AuthFalso());

    await tester.tap(find.text('Crear una nueva cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('PANTALLA REGISTRO'), findsOneWidget);
  });
}
