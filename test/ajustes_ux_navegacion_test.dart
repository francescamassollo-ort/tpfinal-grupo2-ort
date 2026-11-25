import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tpfinal_grupo2/core/app_shell.dart';
import 'package:tpfinal_grupo2/core/app_strings.dart';
import 'package:tpfinal_grupo2/core/permisos.dart';
import 'package:tpfinal_grupo2/models/alerta.dart';
import 'package:tpfinal_grupo2/models/usuario.dart';
import 'package:tpfinal_grupo2/providers/alerta_provider.dart';
import 'package:tpfinal_grupo2/providers/perfil_provider.dart';
import 'package:tpfinal_grupo2/providers/role_provider.dart';
import 'package:tpfinal_grupo2/widgets/solo_con_permiso.dart';

import 'helpers/pantalla_celular.dart';

/// Un router como el de la app: algunas pantallas dentro del shell (barra
/// inferior y menú) y otras afuera, como Historial.
GoRouter _router({String inicio = '/inventario'}) => GoRouter(
      initialLocation: inicio,
      routes: [
        GoRoute(path: '/historial', builder: (c, s) => const Scaffold(body: Text('HISTORIAL'))),
        GoRoute(
          path: '/usuarios-protegido',
          builder: (c, s) => const SoloConPermiso(
            permitido: Permisos.puedeGestionarUsuarios,
            child: Text('USUARIOS'),
          ),
        ),
        ShellRoute(
          builder: (c, s, child) => AppShell(location: s.uri.path, child: child),
          routes: [
            GoRoute(path: '/inventario', builder: (c, s) => const Text('INVENTARIO')),
            GoRoute(path: '/alertas', builder: (c, s) => const Text('ALERTAS')),
            GoRoute(path: '/perfil', builder: (c, s) => const Text('PERFIL')),
            GoRoute(path: '/tp', builder: (c, s) => const Text('TPS')),
          ],
        ),
      ],
    );

Future<GoRouter> _abrir(
  WidgetTester tester, {
  String inicio = '/inventario',
  UserRole rol = UserRole.administrador,
}) async {
  usarPantallaDeCelular(tester);
  final router = _router(inicio: inicio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        alertasProvider.overrideWithValue(const AsyncData(<Alerta>[])),
        alertasVistasProvider.overrideWith((ref) => Stream.value(<String>{})),
        rolDeSesionProvider.overrideWith((ref) => Stream.value(rol)),
        perfilUsuarioProvider.overrideWith((ref) => Stream.value(null)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

String _ruta(GoRouter router) => router.routerDelegate.currentConfiguration.uri.path;

/// El "atrás" del sistema (el botón o el gesto de Android). Devuelve false si
/// nadie lo atendió, que es cuando la app se cierra.
Future<bool> _atrasDelSistema(WidgetTester tester) async {
  final atendido = await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  return atendido;
}

void main() {
  group('el "atrás" del sistema', () {
    testWidgets('desde Alertas vuelve a Inventario', (tester) async {
      final router = await _abrir(tester, inicio: '/alertas');
      expect(_ruta(router), '/alertas');

      await _atrasDelSistema(tester);

      expect(_ruta(router), '/inventario');
      expect(find.text('INVENTARIO'), findsOneWidget);
    });

    testWidgets('desde Perfil y desde la lista de TPs también', (tester) async {
      final router = await _abrir(tester, inicio: '/perfil');
      await _atrasDelSistema(tester);
      expect(_ruta(router), '/inventario');

      router.go('/tp');
      await tester.pumpAndSettle();
      await _atrasDelSistema(tester);
      expect(_ruta(router), '/inventario');
    });

    testWidgets('desde Inventario no hace nada: la app se cierra', (tester) async {
      final router = await _abrir(tester);

      final atendido = await _atrasDelSistema(tester);

      expect(atendido, isFalse);
      expect(_ruta(router), '/inventario');
    });

    testWidgets('Historial desde el menú se abre encima y "atrás" vuelve a donde se estaba',
        (tester) async {
      final router = await _abrir(tester);

      await tester.tap(find.byTooltip(AppStrings.menuAbrir));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.menuHistorial));
      await tester.pumpAndSettle();
      expect(find.text('HISTORIAL'), findsOneWidget);

      final atendido = await _atrasDelSistema(tester);

      expect(atendido, isTrue);
      expect(_ruta(router), '/inventario');
      expect(find.text('HISTORIAL'), findsNothing);
    });

    testWidgets('con el menú abierto, "atrás" solo lo cierra', (tester) async {
      final router = await _abrir(tester, inicio: '/alertas');

      await tester.tap(find.byTooltip(AppStrings.menuAbrir));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.menuCerrarSesion), findsOneWidget);

      await _atrasDelSistema(tester);

      expect(find.text(AppStrings.menuCerrarSesion), findsNothing);
      expect(_ruta(router), '/alertas');
    });
  });

  group('la barra inferior', () {
    bool activo(WidgetTester tester, String tooltip) => tester
        .widget<IconButton>(
          find.ancestor(of: find.byTooltip(tooltip), matching: find.byType(IconButton)),
        )
        .isSelected!;

    testWidgets('marca solo la pantalla en la que se está', (tester) async {
      await _abrir(tester, inicio: '/alertas');

      expect(activo(tester, AppStrings.alertasTitulo), isTrue);
      expect(activo(tester, AppStrings.menuInventario), isFalse);
      expect(activo(tester, AppStrings.perfilTitulo), isFalse);
    });

    testWidgets('al ir a Perfil, se marca Perfil', (tester) async {
      await _abrir(tester, inicio: '/perfil');

      expect(activo(tester, AppStrings.perfilTitulo), isTrue);
      expect(activo(tester, AppStrings.alertasTitulo), isFalse);
    });

    testWidgets('todos los botones tienen nombre para el lector de pantalla', (tester) async {
      await _abrir(tester);

      for (final nombre in [
        AppStrings.menuAbrir,
        AppStrings.homeTitulo,
        AppStrings.menuInventario,
        AppStrings.perfilTitulo,
        AppStrings.alertasTitulo,
      ]) {
        expect(find.byTooltip(nombre), findsOneWidget, reason: nombre);
      }
    });
  });

  group('el menú lateral', () {
    testWidgets('muestra el rol y marca la pantalla actual', (tester) async {
      await _abrir(tester, rol: UserRole.ayudante);

      await tester.tap(find.byTooltip(AppStrings.menuAbrir));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.usuariosRolAyudante), findsOneWidget);
      final inventario = tester.widget<ListTile>(
        find.widgetWithText(ListTile, AppStrings.menuInventario),
      );
      expect(inventario.selected, isTrue);
      final tps = tester.widget<ListTile>(find.widgetWithText(ListTile, AppStrings.menuTps));
      expect(tps.selected, isFalse);
    });

    testWidgets('cerrar sesión pide confirmar, y cancelar no cierra', (tester) async {
      await _abrir(tester);
      await tester.tap(find.byTooltip(AppStrings.menuAbrir));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.menuCerrarSesion));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.menuCerrarTitulo), findsOneWidget);

      await tester.tap(find.text(AppStrings.cancelar));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.menuCerrarTitulo), findsNothing);
    });
  });

  group('la pantalla sin permiso', () {
    testWidgets('tiene la flecha de volver y lleva a Inventario si no hay a dónde volver',
        (tester) async {
      final router = await _abrir(
        tester,
        inicio: '/usuarios-protegido',
        rol: UserRole.docente,
      );

      expect(find.text(AppStrings.sinPermiso), findsOneWidget);
      expect(find.text('USUARIOS'), findsNothing);

      await tester.tap(find.byTooltip(AppStrings.volver));
      await tester.pumpAndSettle();

      expect(_ruta(router), '/inventario');
    });

    testWidgets('el administrador sí entra', (tester) async {
      await _abrir(tester, inicio: '/usuarios-protegido');

      expect(find.text('USUARIOS'), findsOneWidget);
      expect(find.text(AppStrings.sinPermiso), findsNothing);
    });
  });
}
