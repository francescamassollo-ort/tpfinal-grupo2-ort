import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tpfinal_grupo2/core/app_strings.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/usuario.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/role_provider.dart';
import 'package:tpfinal_grupo2/providers/usuario_provider.dart';
import 'package:tpfinal_grupo2/providers/usuarios_provider.dart';
import 'package:tpfinal_grupo2/screens/inventario/insumos_de_baja_screen.dart';
import 'package:tpfinal_grupo2/screens/usuarios/usuarios_screen.dart';
import 'package:tpfinal_grupo2/services/insumo_service.dart';
import 'package:tpfinal_grupo2/services/rol_de_sesion_service.dart';
import 'package:tpfinal_grupo2/services/user_service.dart';
import 'package:tpfinal_grupo2/widgets/cierre_por_inactividad.dart';

Usuario _usuario(String id, String nombre, {bool activo = true}) => Usuario(
      id: id,
      nombre: nombre,
      email: '$id@comunidadort.edu.ar',
      rol: UserRole.docente,
      activo: activo,
    );

Insumo _insumo(String id, String nombre, {bool activo = true}) => Insumo(
      id: id,
      nombre: nombre,
      tipo: InsumoTipo.comprado,
      stock: 3,
      ubicacion: 'Armario 1',
      umbralMinimo: 1,
      activo: activo,
    );

class _UserServiceFalso extends Fake implements UserService {
  final reactivados = <String>[];
  bool falla = false;

  @override
  Future<void> reactivar(String usuarioId) async {
    if (falla) throw Exception('sin conexión');
    reactivados.add(usuarioId);
  }
}

class _InsumoServiceFalso extends Fake implements InsumoService {
  final reactivados = <String>[];
  bool falla = false;

  @override
  Future<void> reactivar(String insumoId) async {
    if (falla) throw Exception('sin conexión');
    reactivados.add(insumoId);
  }
}

void main() {
  group('reactivar un usuario', () {
    Future<_UserServiceFalso> abrir(
      WidgetTester tester, {
      List<Usuario>? todos,
      _UserServiceFalso? servicio,
    }) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final fake = servicio ?? _UserServiceFalso();
      final lista = todos ?? [_usuario('a', 'Ana'), _usuario('b', 'Beto', activo: false)];
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            userServiceProvider.overrideWithValue(fake),
            usuariosProvider.overrideWith(
              (ref) => Stream.value([for (final u in lista) if (u.activo) u]),
            ),
            usuariosConBajasProvider.overrideWith((ref) => Stream.value(lista)),
            usuarioActualIdProvider.overrideWithValue('yo'),
            rolDeSesionProvider.overrideWith((ref) => Stream.value(UserRole.administrador)),
          ],
          child: const MaterialApp(home: Scaffold(body: UsuariosScreen())),
        ),
      );
      await tester.pumpAndSettle();
      return fake;
    }

    testWidgets('por defecto se ven los activos, no los dados de baja', (tester) async {
      await abrir(tester);

      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Beto'), findsNothing);
    });

    testWidgets('con el interruptor se ven los dados de baja y se reactivan', (tester) async {
      final servicio = await abrir(tester);

      await tester.tap(find.text(AppStrings.usuariosVerBajas));
      await tester.pumpAndSettle();
      expect(find.text('Beto'), findsOneWidget);
      expect(find.text('Ana'), findsNothing);

      await tester.tap(find.text(AppStrings.usuariosReactivar));
      await tester.pumpAndSettle();

      expect(servicio.reactivados, ['b']);
      expect(find.text(AppStrings.usuariosReactivado('Beto')), findsOneWidget);
    });

    testWidgets('sin usuarios dados de baja lo dice', (tester) async {
      await abrir(tester, todos: [_usuario('a', 'Ana')]);

      await tester.tap(find.text(AppStrings.usuariosVerBajas));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.usuariosSinBajas), findsOneWidget);
    });

    testWidgets('si falla al reactivar lo dice', (tester) async {
      await abrir(tester, servicio: _UserServiceFalso()..falla = true);

      await tester.tap(find.text(AppStrings.usuariosVerBajas));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.usuariosReactivar));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.usuariosErrorReactivar), findsOneWidget);
    });
  });

  group('insumos dados de baja', () {
    Future<_InsumoServiceFalso> abrir(
      WidgetTester tester, {
      List<Insumo>? insumos,
      _InsumoServiceFalso? servicio,
    }) async {
      final fake = servicio ?? _InsumoServiceFalso();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: InsumosDeBajaScreen()),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            insumoServiceProvider.overrideWithValue(fake),
            insumosConBajasProvider.overrideWith(
              (ref) => Stream.value(
                insumos ?? [_insumo('i1', 'Etanol', activo: false), _insumo('i2', 'Acetona')],
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      return fake;
    }

    testWidgets('lista solo los dados de baja', (tester) async {
      await abrir(tester);

      expect(find.text('Etanol'), findsOneWidget);
      expect(find.text('Acetona'), findsNothing);
    });

    testWidgets('"Reactivar" lo vuelve al inventario y lo avisa', (tester) async {
      final servicio = await abrir(tester);

      await tester.tap(find.text(AppStrings.insumosReactivar));
      await tester.pumpAndSettle();

      expect(servicio.reactivados, ['i1']);
      expect(find.text(AppStrings.insumosReactivado('Etanol')), findsOneWidget);
    });

    testWidgets('si falla lo dice', (tester) async {
      await abrir(tester, servicio: _InsumoServiceFalso()..falla = true);

      await tester.tap(find.text(AppStrings.insumosReactivar));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.insumosReactivarError), findsOneWidget);
    });

    testWidgets('sin ninguno dado de baja lo dice', (tester) async {
      await abrir(tester, insumos: [_insumo('i2', 'Acetona')]);

      expect(find.text(AppStrings.insumosBajaVacio), findsOneWidget);
    });
  });

  group('cierre por inactividad', () {
    const persona = (uid: 'u1', nombre: 'Ana', email: 'ana@comunidadort.edu.ar');

    Future<List<int>> abrir(
      WidgetTester tester, {
      bool conSesion = true,
    }) async {
      final cierres = <int>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sesionProvider.overrideWith(
              (ref) => Stream<PersonaConSesion?>.value(conSesion ? persona : null),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CierrePorInactividad(
                duracion: const Duration(minutes: 10),
                cerrarSesion: () async => cierres.add(1),
                child: const Center(child: Text('Contenido')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return cierres;
    }

    testWidgets('sin tocar nada, al vencer el tiempo cierra la sesión y avisa', (tester) async {
      final cierres = await abrir(tester);

      await tester.pump(const Duration(minutes: 9));
      expect(cierres, isEmpty);
      await tester.pump(const Duration(minutes: 2));

      expect(cierres, hasLength(1));
      expect(find.text(AppStrings.sesionCerradaPorInactividad), findsOneWidget);
    });

    testWidgets('tocar la pantalla reinicia la cuenta', (tester) async {
      final cierres = await abrir(tester);

      await tester.pump(const Duration(minutes: 8));
      await tester.tap(find.text('Contenido'));
      await tester.pump(const Duration(minutes: 8));
      expect(cierres, isEmpty);

      await tester.pump(const Duration(minutes: 3));
      expect(cierres, hasLength(1));
    });

    testWidgets('sin sesión no hace nada', (tester) async {
      final cierres = await abrir(tester, conSesion: false);

      await tester.pump(const Duration(minutes: 30));

      expect(cierres, isEmpty);
      expect(find.text(AppStrings.sesionCerradaPorInactividad), findsNothing);
    });

    test('el tiempo por defecto es de 30 minutos', () {
      expect(CierrePorInactividad.tiempoSinActividad, const Duration(minutes: 30));
    });
  });
}
