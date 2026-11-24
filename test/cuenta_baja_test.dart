import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/core/app_strings.dart';
import 'package:tpfinal_grupo2/models/usuario.dart';
import 'package:tpfinal_grupo2/providers/role_provider.dart';
import 'package:tpfinal_grupo2/providers/usuario_provider.dart';
import 'package:tpfinal_grupo2/services/rol_de_sesion_service.dart';
import 'package:tpfinal_grupo2/widgets/guardia_de_cuenta.dart';

const PersonaConSesion _ana = (uid: 'u1', nombre: 'Ana', email: 'ana@comunidadort.edu.ar');
const PersonaConSesion _beto = (uid: 'u2', nombre: 'Beto', email: 'beto@comunidadort.edu.ar');

Usuario _usuario({bool activo = true}) => Usuario(
      id: 'u1',
      nombre: 'Ana',
      email: 'ana@comunidadort.edu.ar',
      rol: UserRole.docente,
      activo: activo,
    );

void main() {
  group('cuenta activa', () {
    test('una cuenta sin documento todavía no fue dada de baja', () {
      expect(RolDeSesionService.estaActiva(null), isTrue);
    });

    test('con documento activo está activa, dada de baja no', () {
      expect(RolDeSesionService.estaActiva(_usuario()), isTrue);
      expect(RolDeSesionService.estaActiva(_usuario(activo: false)), isFalse);
    });

    test('avisa cuando le dan de baja', () async {
      final documentos = StreamController<Usuario?>();
      addTearDown(documentos.close);
      final servicio = RolDeSesionService(
        crearSiNoExiste: (_) async {},
        vigilar: (_) => documentos.stream,
      );
      final estados = <bool>[];
      final suscripcion = servicio.activaDe(_ana).listen(estados.add);

      documentos.add(_usuario());
      documentos.add(_usuario(activo: false));
      await Future<void>.delayed(Duration.zero);
      unawaited(suscripcion.cancel());

      expect(estados, [true, false]);
    });

    test('no crea el documento: eso lo hace el rol', () async {
      var creados = 0;
      final servicio = RolDeSesionService(
        crearSiNoExiste: (_) async => creados++,
        vigilar: (_) => Stream.value(null),
      );

      await servicio.activaDe(_ana).first;

      expect(creados, 0);
    });
  });

  group('GuardiaDeCuenta', () {
    Future<List<int>> abrir(
      WidgetTester tester,
      Stream<bool> cuentaActiva,
    ) async {
      final cierres = <int>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cuentaActivaProvider.overrideWith((ref) => cuentaActiva),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GuardiaDeCuenta(
                cerrarSesion: () async => cierres.add(1),
                child: const Text('Contenido de la app'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return cierres;
    }

    testWidgets('una cuenta dada de baja pierde la sesión y se le avisa', (tester) async {
      final cierres = await abrir(tester, Stream.value(false));

      expect(cierres, hasLength(1));
      expect(find.text(AppStrings.cuentaDadaDeBaja), findsOneWidget);
    });

    testWidgets('una cuenta activa no se toca', (tester) async {
      final cierres = await abrir(tester, Stream.value(true));

      expect(cierres, isEmpty);
      expect(find.text(AppStrings.cuentaDadaDeBaja), findsNothing);
      expect(find.text('Contenido de la app'), findsOneWidget);
    });

    testWidgets('mientras se averigua no se saca a nadie', (tester) async {
      final sinRespuesta = StreamController<bool>();
      addTearDown(sinRespuesta.close);

      final cierres = await abrir(tester, sinRespuesta.stream);

      expect(cierres, isEmpty);
    });

    testWidgets('si se la da de baja mientras usa la app, se la saca en el momento',
        (tester) async {
      final estados = StreamController<bool>();
      addTearDown(estados.close);
      final cierres = await abrir(tester, estados.stream);

      estados.add(true);
      await tester.pump();
      expect(cierres, isEmpty);

      estados.add(false);
      await tester.pump();
      await tester.pump();

      expect(cierres, hasLength(1));
    });

    testWidgets('si no se puede saber (error), no se bloquea a nadie', (tester) async {
      final cierres = await abrir(tester, Stream.error(Exception('sin conexión')));

      expect(cierres, isEmpty);
      expect(find.text('Contenido de la app'), findsOneWidget);
    });
  });

  group('usuarioActualIdProvider sigue a la sesión', () {
    test('cambia cuando entra otra persona sin cerrar la app', () async {
      final sesiones = StreamController<PersonaConSesion?>();
      addTearDown(sesiones.close);
      final c = ProviderContainer(
        overrides: [sesionProvider.overrideWith((ref) => sesiones.stream)],
      );
      addTearDown(c.dispose);
      final ids = <String>[];
      c.listen(usuarioActualIdProvider, (_, id) => ids.add(id), fireImmediately: true);

      sesiones.add(_ana);
      await pumpEventQueue();
      sesiones.add(null);
      await pumpEventQueue();
      sesiones.add(_beto);
      await pumpEventQueue();

      expect(ids, [usuarioSinSesion, 'u1', usuarioSinSesion, 'u2']);
    });

    test('mientras no se sabe quién es, vale el id fijo', () {
      final sesiones = StreamController<PersonaConSesion?>();
      addTearDown(sesiones.close);
      final c = ProviderContainer(
        overrides: [sesionProvider.overrideWith((ref) => sesiones.stream)],
      );
      addTearDown(c.dispose);
      c.listen(usuarioActualIdProvider, (_, _) {});

      expect(c.read(usuarioActualIdProvider), usuarioSinSesion);
    });
  });
}
