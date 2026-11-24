import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/core/app_strings.dart';
import 'package:tpfinal_grupo2/core/permisos.dart';
import 'package:tpfinal_grupo2/models/usuario.dart';
import 'package:tpfinal_grupo2/providers/role_provider.dart';
import 'package:tpfinal_grupo2/providers/usuario_provider.dart';
import 'package:tpfinal_grupo2/providers/usuarios_provider.dart';
import 'package:tpfinal_grupo2/screens/usuarios/usuarios_screen.dart';
import 'package:tpfinal_grupo2/services/user_service.dart';
import 'package:tpfinal_grupo2/widgets/solo_con_permiso.dart';

Usuario _usuario(String id, String nombre, UserRole rol) =>
    Usuario(id: id, nombre: nombre, email: '$id@comunidadort.edu.ar', rol: rol);

final _yo = _usuario('yo', 'Yo Admin', UserRole.administrador);
final _ana = _usuario('a1', 'Ana', UserRole.administrador);
final _beto = _usuario('b1', 'Beto', UserRole.docente);

/// El servicio de usuarios sin Firestore: anota los cambios que se le piden.
class _UserServiceFalso extends Fake implements UserService {
  final cambiosDeRol = <(String, UserRole)>[];
  final bajas = <String>[];
  Object? falla;

  @override
  Future<void> updateRol(String usuarioId, UserRole nuevoRol) async {
    if (falla != null) throw falla!;
    cambiosDeRol.add((usuarioId, nuevoRol));
  }

  @override
  Future<void> delete(String usuarioId) async {
    if (falla != null) throw falla!;
    bajas.add(usuarioId);
  }
}

List<Override> _overrides(
  _UserServiceFalso servicio,
  Stream<List<Usuario>> usuarios, {
  String miId = 'yo',
}) =>
    [
      userServiceProvider.overrideWithValue(servicio),
      usuariosProvider.overrideWith((ref) => usuarios),
      usuarioActualIdProvider.overrideWithValue(miId),
    ];

void main() {
  group('UsuariosAcciones: las reglas', () {
    Future<UsuariosAcciones> acciones(
      _UserServiceFalso servicio,
      List<Usuario> lista, {
      String miId = 'yo',
    }) async {
      final c = ProviderContainer(
        overrides: _overrides(servicio, Stream.value(lista), miId: miId),
      );
      addTearDown(c.dispose);
      c.listen(usuariosProvider, (_, _) {});
      await c.read(usuariosProvider.future);
      return c.read(usuariosAccionesProvider);
    }

    Future<MotivoUsuarioRechazado?> motivoDe(Future<void> Function() accion) async {
      try {
        await accion();
        return null;
      } on UsuarioRechazadoException catch (e) {
        return e.motivo;
      }
    }

    test('cambiar el rol de otro usuario lo guarda', () async {
      final servicio = _UserServiceFalso();
      final a = await acciones(servicio, [_yo, _ana, _beto]);

      await a.cambiarRol(_beto, UserRole.ayudante);

      expect(servicio.cambiosDeRol, [('b1', UserRole.ayudante)]);
    });

    test('si ya tiene ese rol no escribe nada', () async {
      final servicio = _UserServiceFalso();
      final a = await acciones(servicio, [_yo, _ana, _beto]);

      await a.cambiarRol(_beto, UserRole.docente);

      expect(servicio.cambiosDeRol, isEmpty);
    });

    test('nadie se cambia el rol a sí mismo', () async {
      final servicio = _UserServiceFalso();
      final a = await acciones(servicio, [_yo, _ana, _beto]);

      final motivo = await motivoDe(() => a.cambiarRol(_yo, UserRole.docente));

      expect(motivo, MotivoUsuarioRechazado.propioUsuario);
      expect(servicio.cambiosDeRol, isEmpty);
    });

    test('nadie se da de baja a sí mismo', () async {
      final servicio = _UserServiceFalso();
      final a = await acciones(servicio, [_yo, _ana, _beto]);

      final motivo = await motivoDe(() => a.eliminar(_yo));

      expect(motivo, MotivoUsuarioRechazado.propioUsuario);
      expect(servicio.bajas, isEmpty);
    });

    test('no se le saca el rol al único administrador', () async {
      final servicio = _UserServiceFalso();
      // "yo" no figura en la lista (por ejemplo, ya no está activo).
      final a = await acciones(servicio, [_ana, _beto]);

      final motivo = await motivoDe(() => a.cambiarRol(_ana, UserRole.ayudante));

      expect(motivo, MotivoUsuarioRechazado.ultimoAdministrador);
      expect(servicio.cambiosDeRol, isEmpty);
    });

    test('tampoco se da de baja al único administrador', () async {
      final servicio = _UserServiceFalso();
      final a = await acciones(servicio, [_ana, _beto]);

      final motivo = await motivoDe(() => a.eliminar(_ana));

      expect(motivo, MotivoUsuarioRechazado.ultimoAdministrador);
      expect(servicio.bajas, isEmpty);
    });

    test('con dos administradores sí se puede cambiar a uno', () async {
      final servicio = _UserServiceFalso();
      final a = await acciones(servicio, [_yo, _ana, _beto]);

      await a.cambiarRol(_ana, UserRole.ayudante);

      expect(servicio.cambiosDeRol, [('a1', UserRole.ayudante)]);
    });

    test('dar de baja a otro usuario lo guarda', () async {
      final servicio = _UserServiceFalso();
      final a = await acciones(servicio, [_yo, _ana, _beto]);

      await a.eliminar(_beto);

      expect(servicio.bajas, ['b1']);
    });

    test('si la lista todavía no cargó, ante la duda no se toca a un administrador',
        () async {
      final servicio = _UserServiceFalso();
      final sinCargar = StreamController<List<Usuario>>();
      addTearDown(sinCargar.close);
      final c = ProviderContainer(
        overrides: _overrides(servicio, sinCargar.stream),
      );
      addTearDown(c.dispose);
      c.listen(usuariosProvider, (_, _) {});

      final motivo = await motivoDe(
        () => c.read(usuariosAccionesProvider).cambiarRol(_ana, UserRole.docente),
      );

      expect(motivo, MotivoUsuarioRechazado.ultimoAdministrador);
    });
  });

  group('pantalla de usuarios', () {
    Future<_UserServiceFalso> abrir(
      WidgetTester tester, {
      required UserRole rol,
      Stream<List<Usuario>>? usuarios,
      List<Usuario>? lista,
      _UserServiceFalso? servicio,
    }) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final fake = servicio ?? _UserServiceFalso();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._overrides(fake, usuarios ?? Stream.value(lista ?? [_yo, _ana, _beto])),
            rolDeSesionProvider.overrideWith((ref) => Stream.value(rol)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SoloConPermiso(
                permitido: Permisos.puedeGestionarUsuarios,
                child: UsuariosScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return fake;
    }

    // Los botones de una fila: el de Beto es el único docente.
    Finder boton(String tooltip, String nombre) => find.descendant(
          of: find.ancestor(of: find.text(nombre), matching: find.byType(Row)).first,
          matching: find.byTooltip(tooltip),
        );

    testWidgets('el administrador ve a todos con su rol', (tester) async {
      await abrir(tester, rol: UserRole.administrador);

      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Beto'), findsOneWidget);
      expect(find.text('Docente'), findsOneWidget);
      expect(find.text('Administrador'), findsNWidgets(2));
    });

    testWidgets('quien no es administrador ve que no tiene permiso', (tester) async {
      await abrir(tester, rol: UserRole.ayudante);

      expect(find.text(AppStrings.sinPermiso), findsOneWidget);
      expect(find.text('Ana'), findsNothing);
    });

    testWidgets('sin usuarios lo dice', (tester) async {
      await abrir(tester, rol: UserRole.administrador, lista: const []);

      expect(find.text(AppStrings.usuariosVacio), findsOneWidget);
    });

    testWidgets('si no se pueden cargar lo dice', (tester) async {
      await abrir(
        tester,
        rol: UserRole.administrador,
        usuarios: Stream.error(Exception('sin permiso')),
      );

      expect(find.text(AppStrings.usuariosError), findsOneWidget);
    });

    testWidgets('la fila propia no se puede modificar', (tester) async {
      await abrir(tester, rol: UserRole.administrador);

      // El administrador "yo" figura como "Yo Admin": sus dos botones dicen que
      // es su cuenta y están apagados.
      expect(find.byTooltip(AppStrings.usuariosTuCuenta), findsNWidgets(2));
      final botones = tester.widgetList<IconButton>(
        find.widgetWithIcon(IconButton, Icons.edit),
      );
      expect(botones.where((b) => b.onPressed == null), hasLength(1));
    });

    testWidgets('cambiar el rol guarda y lo avisa', (tester) async {
      final servicio = await abrir(tester, rol: UserRole.administrador);

      await tester.tap(boton(AppStrings.usuariosCambiarRol, 'Beto'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<UserRole>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ayudante').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.usuariosGuardarRol));
      await tester.pumpAndSettle();

      expect(servicio.cambiosDeRol, [('b1', UserRole.ayudante)]);
      expect(
        find.text(AppStrings.usuariosRolActualizado('Beto', UserRole.ayudante)),
        findsOneWidget,
      );
    });

    testWidgets('"Guardar" está apagado mientras no se elige otro rol',
        (tester) async {
      await abrir(tester, rol: UserRole.administrador);

      await tester.tap(boton(AppStrings.usuariosCambiarRol, 'Beto'));
      await tester.pumpAndSettle();

      final guardar = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(guardar.onPressed, isNull);
    });

    testWidgets('dar de baja pide confirmar y después lo hace', (tester) async {
      final servicio = await abrir(tester, rol: UserRole.administrador);

      await tester.tap(boton(AppStrings.usuariosEliminar, 'Beto'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.usuariosEliminarTitulo), findsOneWidget);
      expect(servicio.bajas, isEmpty);

      await tester.tap(find.widgetWithText(TextButton, AppStrings.usuariosEliminarConfirmar));
      await tester.pumpAndSettle();

      expect(servicio.bajas, ['b1']);
      expect(find.text(AppStrings.usuariosEliminado('Beto')), findsOneWidget);
    });

    testWidgets('cancelar la baja no hace nada', (tester) async {
      final servicio = await abrir(tester, rol: UserRole.administrador);

      await tester.tap(boton(AppStrings.usuariosEliminar, 'Beto'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, AppStrings.cancelar));
      await tester.pumpAndSettle();

      expect(servicio.bajas, isEmpty);
    });

    testWidgets('si falla Firestore dice que no se pudo', (tester) async {
      final servicio = _UserServiceFalso()..falla = Exception('sin conexión');
      await abrir(tester, rol: UserRole.administrador, servicio: servicio);

      await tester.tap(boton(AppStrings.usuariosEliminar, 'Beto'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, AppStrings.usuariosEliminarConfirmar));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.usuariosErrorEliminar), findsOneWidget);
    });

    testWidgets('explica por qué no se puede dar de baja al único administrador',
        (tester) async {
      // "yo" no está en la lista: Ana es la única administradora.
      final servicio = await abrir(
        tester,
        rol: UserRole.administrador,
        lista: [_ana, _beto],
      );

      await tester.tap(boton(AppStrings.usuariosEliminar, 'Ana'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, AppStrings.usuariosEliminarConfirmar));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.usuariosErrorUltimoAdmin), findsOneWidget);
      expect(servicio.bajas, isEmpty);
    });
  });
}
