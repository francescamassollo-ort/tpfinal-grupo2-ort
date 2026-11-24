import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/core/app_shell.dart';
import 'package:tpfinal_grupo2/models/alerta.dart';
import 'package:tpfinal_grupo2/models/usuario.dart';
import 'package:tpfinal_grupo2/providers/alerta_provider.dart';
import 'package:tpfinal_grupo2/providers/role_provider.dart';
import 'package:tpfinal_grupo2/services/rol_de_sesion_service.dart';

const PersonaConSesion _persona = (
  uid: 'u1',
  nombre: 'Ana Pérez',
  email: 'ana@comunidadort.edu.ar',
);

Usuario _usuario({UserRole rol = UserRole.docente, bool activo = true}) => Usuario(
      id: 'u1',
      nombre: 'Ana Pérez',
      email: 'ana@comunidadort.edu.ar',
      rol: rol,
      activo: activo,
    );

/// Un Firestore de mentira: guarda los documentos en un mapa y avisa cuando
/// cambian, como el de verdad.
class _Falso {
  final documentos = <String, Usuario>{};
  final avisos = StreamController<void>.broadcast();
  final creados = <Usuario>[];
  Object? falloAlCrear;

  Future<void> crearSiNoExiste(Usuario nuevo) async {
    if (falloAlCrear != null) throw falloAlCrear!;
    if (documentos.containsKey(nuevo.id)) return;
    documentos[nuevo.id] = nuevo;
    creados.add(nuevo);
    avisos.add(null);
  }

  Stream<Usuario?> vigilar(String uid) async* {
    yield documentos[uid];
    await for (final _ in avisos.stream) {
      yield documentos[uid];
    }
  }

  void cambiar(Usuario usuario) {
    documentos[usuario.id] = usuario;
    avisos.add(null);
  }

  RolDeSesionService get servicio =>
      RolDeSesionService(crearSiNoExiste: crearSiNoExiste, vigilar: vigilar);
}

void main() {
  group('RolDeSesionService: las reglas', () {
    test('una cuenta nueva arranca con el rol de menos permisos', () {
      expect(RolDeSesionService.rolPorDefecto, UserRole.docente);
      expect(RolDeSesionService.usuarioNuevo(_persona).rol, UserRole.docente);
    });

    test('el documento nuevo lleva el uid, el nombre y el mail de la cuenta', () {
      final nuevo = RolDeSesionService.usuarioNuevo(_persona);

      expect(nuevo.id, 'u1');
      expect(nuevo.nombre, 'Ana Pérez');
      expect(nuevo.email, 'ana@comunidadort.edu.ar');
      expect(nuevo.activo, isTrue);
      expect(nuevo.puedeVerSedronar, isFalse);
    });

    test('sin nombre en la cuenta usa lo que va antes de la arroba', () {
      expect(
        RolDeSesionService.nombreInicial(nombre: null, email: 'ana@ort.edu.ar'),
        'ana',
      );
      expect(
        RolDeSesionService.nombreInicial(nombre: '   ', email: 'ana@ort.edu.ar'),
        'ana',
      );
    });

    test('sin nombre ni mail dice "Sin nombre"', () {
      expect(RolDeSesionService.nombreInicial(), 'Sin nombre');
      expect(RolDeSesionService.nombreInicial(email: ''), 'Sin nombre');
    });

    test('sin documento, o dado de baja, vale el rol de menos permisos', () {
      expect(RolDeSesionService.rolDelUsuario(null), UserRole.docente);
      expect(
        RolDeSesionService.rolDelUsuario(
          _usuario(rol: UserRole.administrador, activo: false),
        ),
        UserRole.docente,
      );
    });

    test('con documento activo vale su rol', () {
      for (final rol in UserRole.values) {
        expect(RolDeSesionService.rolDelUsuario(_usuario(rol: rol)), rol);
      }
    });
  });

  group('RolDeSesionService: con la base', () {
    test('la primera vez crea el documento y devuelve docente', () async {
      final base = _Falso();

      final primero = await base.servicio.rolDe(_persona).first;

      expect(primero, UserRole.docente);
      expect(base.creados, hasLength(1));
      expect(base.documentos['u1']!.rol, UserRole.docente);
    });

    test('si ya tiene documento no lo pisa y devuelve su rol', () async {
      final base = _Falso()..documentos['u1'] = _usuario(rol: UserRole.administrador);

      final primero = await base.servicio.rolDe(_persona).first;

      expect(primero, UserRole.administrador);
      expect(base.creados, isEmpty);
    });

    test('avisa cuando le cambian el rol', () async {
      final base = _Falso()..documentos['u1'] = _usuario();
      final roles = <UserRole>[];
      final suscripcion = base.servicio.rolDe(_persona).listen(roles.add);

      await Future<void>.delayed(Duration.zero);
      base.cambiar(_usuario(rol: UserRole.ayudante));
      await Future<void>.delayed(Duration.zero);
      unawaited(suscripcion.cancel());

      expect(roles, [UserRole.docente, UserRole.ayudante]);
    });

    test('si no se puede crear el documento, sigue con lo que haya', () async {
      final base = _Falso()
        ..falloAlCrear = Exception('permission-denied')
        ..documentos['u1'] = _usuario(rol: UserRole.ayudante);

      expect(await base.servicio.rolDe(_persona).first, UserRole.ayudante);
    });
  });

  group('roleProvider', () {
    ProviderContainer contenedor({
      required PersonaConSesion? persona,
      required _Falso base,
    }) {
      final c = ProviderContainer(
        overrides: [
          sesionProvider.overrideWith((ref) => Stream.value(persona)),
          rolDeSesionServiceProvider.overrideWithValue(base.servicio),
        ],
      );
      addTearDown(c.dispose);
      // Los stream providers necesitan que alguien escuche.
      c.listen(roleProvider, (_, _) {});
      return c;
    }

    // Deja que lleguen los valores de los streams.
    Future<void> esperar() => Future<void>.delayed(Duration.zero);

    test('mientras averigua, vale el rol de menos permisos', () {
      final c = contenedor(persona: _persona, base: _Falso());

      expect(c.read(roleProvider), UserRole.docente);
    });

    test('sin sesión vale el rol de menos permisos', () async {
      final c = contenedor(persona: null, base: _Falso());
      await esperar();

      expect(c.read(roleProvider), UserRole.docente);
    });

    test('con sesión vale el rol que figura en su documento', () async {
      final base = _Falso()..documentos['u1'] = _usuario(rol: UserRole.administrador);
      final c = contenedor(persona: _persona, base: base);
      await esperar();
      await esperar();

      expect(c.read(roleProvider), UserRole.administrador);
    });

    test('si le cambian el rol, la app lo toma sin reiniciarse', () async {
      final base = _Falso()..documentos['u1'] = _usuario();
      final c = contenedor(persona: _persona, base: base);
      await esperar();
      await esperar();
      expect(c.read(roleProvider), UserRole.docente);

      base.cambiar(_usuario(rol: UserRole.ayudante));
      await esperar();
      await esperar();

      expect(c.read(roleProvider), UserRole.ayudante);
    });
  });

  group('el menú según el rol', () {
    Future<void> mostrar(WidgetTester tester, UserRole rol) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            alertasProvider.overrideWithValue(const AsyncData(<Alerta>[])),
            alertasVistasProvider.overrideWith((ref) => Stream.value(<String>{})),
            rolDeSesionProvider.overrideWith((ref) => Stream.value(rol)),
          ],
          child: const MaterialApp(
            home: AppShell(location: '/inventario', child: SizedBox()),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.menu).first);
      await tester.pumpAndSettle();
    }

    testWidgets('el administrador ve Usuarios y Lista de compras', (tester) async {
      await mostrar(tester, UserRole.administrador);

      expect(find.text('Usuarios'), findsOneWidget);
      expect(find.text('Importar desde Excel'), findsOneWidget);
      expect(find.text('Insumos dados de baja'), findsOneWidget);
      expect(find.text('Lista de compras'), findsOneWidget);
    });

    testWidgets('el ayudante ve Lista de compras pero no Usuarios', (tester) async {
      await mostrar(tester, UserRole.ayudante);

      expect(find.text('Lista de compras'), findsOneWidget);
      expect(find.text('Usuarios'), findsNothing);
      expect(find.text('Importar desde Excel'), findsNothing);
      expect(find.text('Insumos dados de baja'), findsNothing);
    });

    testWidgets('el docente no ve ni Lista de compras ni Usuarios', (tester) async {
      await mostrar(tester, UserRole.docente);

      expect(find.text('Inventario'), findsOneWidget);
      expect(find.text('Lista de compras'), findsNothing);
      expect(find.text('Usuarios'), findsNothing);
    });
  });
}
