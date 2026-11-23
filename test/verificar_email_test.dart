import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tpfinal_grupo2/core/redireccion_sesion.dart';
import 'package:tpfinal_grupo2/providers/auth_provider.dart';
import 'package:tpfinal_grupo2/providers/role_provider.dart';
import 'package:tpfinal_grupo2/screens/auth/verificar_email_screen.dart';
import 'package:tpfinal_grupo2/services/rol_de_sesion_service.dart';

import 'helpers/auth_falso.dart';

Future<void> _abrir(WidgetTester tester, AuthFalso auth) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: rutaVerificarMail,
    routes: [
      GoRoute(
        path: rutaVerificarMail,
        builder: (context, state) => const VerificarEmailScreen(),
      ),
      GoRoute(
        path: '/inventario',
        builder: (context, state) =>
            const Scaffold(body: Text('PANTALLA INVENTARIO')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        sesionProvider.overrideWith((ref) => Stream.value(null)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('redirigirSegunSesion', () {
    String? ir({
      required bool conSesion,
      required bool verificado,
      required String ruta,
    }) =>
        redirigirSegunSesion(
          conSesion: conSesion,
          mailVerificado: verificado,
          ruta: ruta,
        );

    test('sin sesión solo se ven las pantallas de acceso', () {
      for (final ruta in ['/welcome', '/login', '/register']) {
        expect(ir(conSesion: false, verificado: false, ruta: ruta), isNull);
      }
      expect(ir(conSesion: false, verificado: false, ruta: '/inventario'), '/welcome');
      expect(ir(conSesion: false, verificado: false, ruta: '/usuarios'), '/welcome');
    });

    test('sin sesión no se puede abrir la verificación', () {
      expect(
        ir(conSesion: false, verificado: false, ruta: rutaVerificarMail),
        '/welcome',
      );
    });

    test('con sesión y mail sin verificar solo se ve la verificación', () {
      expect(ir(conSesion: true, verificado: false, ruta: rutaVerificarMail), isNull);
      for (final ruta in ['/inventario', '/insumo/alta', '/login', '/welcome']) {
        expect(
          ir(conSesion: true, verificado: false, ruta: ruta),
          rutaVerificarMail,
          reason: ruta,
        );
      }
    });

    test('con sesión y mail verificado entra a la app', () {
      expect(ir(conSesion: true, verificado: true, ruta: '/inventario'), isNull);
      expect(ir(conSesion: true, verificado: true, ruta: '/insumo/alta'), isNull);
    });

    test('con el mail verificado, acceso y verificación mandan a Inventario', () {
      for (final ruta in ['/welcome', '/login', '/register', rutaVerificarMail]) {
        expect(
          ir(conSesion: true, verificado: true, ruta: ruta),
          '/inventario',
          reason: ruta,
        );
      }
    });
  });

  group('quién tiene rol', () {
    PersonaConSesion? persona({String? uid = 'u1', bool verificado = true}) =>
        RolDeSesionService.personaDeSesion(
          uid: uid,
          nombre: 'Ana',
          email: 'ana@comunidadort.edu.ar',
          mailVerificado: verificado,
        );

    test('con sesión y mail verificado sí', () {
      expect(persona()?.uid, 'u1');
      expect(persona()?.email, 'ana@comunidadort.edu.ar');
    });

    test('con el mail sin verificar no: no se crea su documento', () {
      expect(persona(verificado: false), isNull);
    });

    test('sin sesión no', () {
      expect(persona(uid: null), isNull);
    });
  });

  group('pantalla de verificación', () {
    testWidgets('dice a qué mail se mandó el correo', (tester) async {
      await _abrir(tester, AuthFalso());

      expect(find.text('Verificá tu mail'), findsOneWidget);
      expect(find.textContaining('ana@comunidadort.edu.ar'), findsOneWidget);
    });

    testWidgets('"Ya verifiqué" sin haber verificado avisa y se queda', (tester) async {
      final auth = AuthFalso()..mailYaVerificado = false;
      await _abrir(tester, auth);

      await tester.tap(find.text('Ya verifiqué'));
      await tester.pumpAndSettle();

      expect(auth.comprobaciones, 1);
      expect(find.textContaining('Todavía no figura como verificado'), findsOneWidget);
      expect(find.text('PANTALLA INVENTARIO'), findsNothing);
    });

    testWidgets('"Ya verifiqué" con el mail verificado entra a Inventario',
        (tester) async {
      final auth = AuthFalso()..mailYaVerificado = true;
      await _abrir(tester, auth);

      await tester.tap(find.text('Ya verifiqué'));
      await tester.pumpAndSettle();

      expect(find.text('PANTALLA INVENTARIO'), findsOneWidget);
    });

    testWidgets('"Reenviar el correo" lo manda de nuevo y lo avisa', (tester) async {
      final auth = AuthFalso();
      await _abrir(tester, auth);

      await tester.tap(find.text('Reenviar el correo'));
      await tester.pumpAndSettle();

      expect(auth.verificacionesEnviadas, 1);
      expect(find.textContaining('Te mandamos el correo de nuevo'), findsOneWidget);
    });

    testWidgets('si el correo no sale, no dice que se mandó', (tester) async {
      final auth = AuthFalso()..verificarMail = false;
      await _abrir(tester, auth);

      await tester.tap(find.text('Reenviar el correo'));
      await tester.pumpAndSettle();

      expect(auth.verificacionesEnviadas, 1);
      expect(find.textContaining('Te mandamos el correo de nuevo'), findsNothing);
    });

    testWidgets('"Usar otra cuenta" cierra la sesión', (tester) async {
      final auth = AuthFalso();
      await _abrir(tester, auth);

      await tester.tap(find.text('Usar otra cuenta'));
      await tester.pumpAndSettle();

      expect(auth.cierresDeSesion, 1);
    });
  });
}
