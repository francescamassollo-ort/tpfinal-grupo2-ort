import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tpfinal_grupo2/providers/auth_provider.dart';
import 'package:tpfinal_grupo2/screens/auth/register_screen.dart';

import 'helpers/auth_falso.dart';

// Monta el registro dentro de un router (el enlace "Ya tengo una cuenta" lo
// necesita). Los botones de abajo permiten forzar que se vuelva a dibujar.
Future<void> _abrir(WidgetTester tester, [AuthFalso? auth]) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/register',
    routes: [
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(body: Text('PANTALLA LOGIN')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authServiceProvider.overrideWithValue(auth ?? AuthFalso())],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _campo(String pista) => find.widgetWithText(TextField, pista);

bool _oculto(WidgetTester tester, String pista) =>
    tester.widget<TextField>(_campo(pista)).obscureText;

void main() {
  testWidgets('muestra los tres campos y el botón', (tester) async {
    await _abrir(tester);

    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(_campo('Email'), findsOneWidget);
    expect(_campo('Contraseña'), findsOneWidget);
    expect(_campo('Confirmar contraseña'), findsOneWidget);
    expect(find.text('Registrarse'), findsOneWidget);
  });

  testWidgets('las contraseñas arrancan ocultas y el mail no', (tester) async {
    await _abrir(tester);

    expect(_oculto(tester, 'Contraseña'), isTrue);
    expect(_oculto(tester, 'Confirmar contraseña'), isTrue);
    expect(_oculto(tester, 'Email'), isFalse);
  });

  testWidgets('el ojo muestra y vuelve a ocultar cada contraseña por separado',
      (tester) async {
    await _abrir(tester);

    // Hay dos ojos, uno por campo de contraseña.
    expect(find.byTooltip('Mostrar contraseña'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Mostrar contraseña').first);
    await tester.pump();

    expect(_oculto(tester, 'Contraseña'), isFalse);
    expect(_oculto(tester, 'Confirmar contraseña'), isTrue);

    await tester.tap(find.byTooltip('Ocultar contraseña'));
    await tester.pump();
    expect(_oculto(tester, 'Contraseña'), isTrue);
  });

  testWidgets('lo escrito no se pierde cuando la pantalla se vuelve a dibujar',
      (tester) async {
    await _abrir(tester);
    await tester.enterText(_campo('Email'), 'ana@comunidadort.edu.ar');
    await tester.enterText(_campo('Contraseña'), 'abc123');

    // Mostrar la contraseña vuelve a dibujar la pantalla.
    await tester.tap(find.byTooltip('Mostrar contraseña').first);
    await tester.pump();

    expect(find.text('ana@comunidadort.edu.ar'), findsOneWidget);
    expect(find.text('abc123'), findsOneWidget);
  });

  testWidgets('sin mail avisa y no intenta registrar', (tester) async {
    await _abrir(tester);

    await tester.tap(find.text('Registrarse'));
    await tester.pump();

    expect(find.text('No dejar espacio vacio en campo Email!!!'), findsOneWidget);
  });

  testWidgets('con contraseñas distintas avisa', (tester) async {
    await _abrir(tester);
    await tester.enterText(_campo('Email'), 'ana@comunidadort.edu.ar');
    await tester.enterText(_campo('Contraseña'), 'abc123');
    await tester.enterText(_campo('Confirmar contraseña'), 'abc124');

    await tester.tap(find.text('Registrarse'));
    await tester.pump();

    expect(find.text('Contraseñas no coinciden!!!'), findsOneWidget);
  });

  testWidgets('un mail institucional largo no se rechaza por su largo',
      (tester) async {
    await _abrir(tester);
    await tester.enterText(_campo('Email'), 'prueba@comunidadort.edu.ar');
    await tester.enterText(_campo('Contraseña'), 'abc123');
    await tester.enterText(_campo('Confirmar contraseña'), 'abc124');

    await tester.tap(find.text('Registrarse'));
    await tester.pump();

    // Llega hasta comparar las contraseñas: antes frenaba en el largo del mail.
    expect(find.textContaining('mayor a 20'), findsNothing);
    expect(find.text('Contraseñas no coinciden!!!'), findsOneWidget);
  });

  testWidgets('con un mail que no es institucional avisa', (tester) async {
    await _abrir(tester);
    await tester.enterText(_campo('Email'), 'ana@gmail.com');
    await tester.enterText(_campo('Contraseña'), 'Abcdef1!');
    await tester.enterText(_campo('Confirmar contraseña'), 'Abcdef1!');

    await tester.tap(find.text('Registrarse'));
    await tester.pump();

    expect(
      find.text('Usá tu mail institucional de ORT (@comunidadort.edu.ar o @ort.edu.ar)'),
      findsOneWidget,
    );
  });

  testWidgets('con una contraseña débil avisa aunque coincida', (tester) async {
    await _abrir(tester);
    await tester.enterText(_campo('Email'), 'ana@comunidadort.edu.ar');
    await tester.enterText(_campo('Contraseña'), 'abc123');
    await tester.enterText(_campo('Confirmar contraseña'), 'abc123');

    await tester.tap(find.text('Registrarse'));
    await tester.pump();

    expect(find.textContaining('al menos 8 caracteres, una mayúscula'), findsOneWidget);
  });

  testWidgets('la lista de requisitos se tilda mientras se escribe', (tester) async {
    await _abrir(tester);

    // Al empezar no se cumple ninguno.
    expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(5));
    expect(find.byIcon(Icons.check_circle), findsNothing);

    // Solo minúsculas: se cumple uno.
    await tester.enterText(_campo('Contraseña'), 'abc');
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    // Una contraseña completa los cumple todos.
    await tester.enterText(_campo('Contraseña'), 'Abcdef1!');
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsNWidgets(5));
    expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
  });

  testWidgets('con todo bien crea la cuenta y manda el correo de verificación',
      (tester) async {
    final auth = AuthFalso();
    await _abrir(tester, auth);
    await tester.enterText(_campo('Email'), ' ana@comunidadort.edu.ar ');
    await tester.enterText(_campo('Contraseña'), 'Abcdef1!');
    await tester.enterText(_campo('Confirmar contraseña'), 'Abcdef1!');

    await tester.tap(find.text('Registrarse'));
    await tester.pump();

    expect(auth.registros, ['ana@comunidadort.edu.ar|Abcdef1!']);
    expect(auth.verificacionesEnviadas, 1);
    expect(find.text('Registro exitoso.'), findsOneWidget);
  });

  testWidgets('si Firebase rechaza el registro no manda ningún correo',
      (tester) async {
    final auth = AuthFalso()..registrar = false;
    await _abrir(tester, auth);
    await tester.enterText(_campo('Email'), 'ana@comunidadort.edu.ar');
    await tester.enterText(_campo('Contraseña'), 'Abcdef1!');
    await tester.enterText(_campo('Confirmar contraseña'), 'Abcdef1!');

    await tester.tap(find.text('Registrarse'));
    await tester.pump();

    expect(auth.registros, hasLength(1));
    expect(auth.verificacionesEnviadas, 0);
    expect(find.text('Registro exitoso.'), findsNothing);
  });

  testWidgets('con datos inválidos no llega a Firebase', (tester) async {
    final auth = AuthFalso();
    await _abrir(tester, auth);
    await tester.enterText(_campo('Email'), 'ana@gmail.com');
    await tester.enterText(_campo('Contraseña'), 'abc');
    await tester.enterText(_campo('Confirmar contraseña'), 'abc');

    await tester.tap(find.text('Registrarse'));
    await tester.pump();

    expect(auth.registros, isEmpty);
    expect(auth.verificacionesEnviadas, 0);
  });

  testWidgets('"Ya tengo una cuenta" lleva al ingreso', (tester) async {
    await _abrir(tester);

    await tester.tap(find.text('Ya tengo una cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('PANTALLA LOGIN'), findsOneWidget);
  });
}
