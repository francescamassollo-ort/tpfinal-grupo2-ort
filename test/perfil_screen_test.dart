import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/usuario.dart';
import 'package:tpfinal_grupo2/providers/auth_provider.dart';
import 'package:tpfinal_grupo2/providers/perfil_provider.dart';
import 'package:tpfinal_grupo2/providers/role_provider.dart';
import 'package:tpfinal_grupo2/providers/usuarios_provider.dart';
import 'package:tpfinal_grupo2/screens/perfil/perfil_screen.dart';
import 'package:tpfinal_grupo2/services/auth_logic/validaciones_auth.dart';
import 'package:tpfinal_grupo2/services/user_service.dart';

import 'helpers/auth_falso.dart';

const _ana = Usuario(
  id: 'u1',
  nombre: 'Ana Pérez',
  email: 'viejo@comunidadort.edu.ar',
  rol: UserRole.ayudante,
);

class _UserServiceFalso extends Fake implements UserService {
  final nombres = <(String, String)>[];

  @override
  Future<void> updateNombre(String usuarioId, String nuevoNombre) async {
    nombres.add((usuarioId, nuevoNombre));
  }
}

Future<void> _abrir(
  WidgetTester tester,
  AuthFalso auth,
  _UserServiceFalso usuarios, {
  UserRole rol = UserRole.ayudante,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        userServiceProvider.overrideWithValue(usuarios),
        perfilUsuarioProvider.overrideWith((ref) => Stream.value(_ana)),
        roleProvider.overrideWithValue(rol),
      ],
      child: const MaterialApp(home: Scaffold(body: PerfilScreen())),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _campoNombre => find.widgetWithText(TextField, 'Nombre');

void main() {
  testWidgets('muestra el nombre, el mail de la cuenta y el rol', (tester) async {
    await _abrir(tester, AuthFalso(), _UserServiceFalso());

    expect(find.widgetWithText(TextField, 'Ana Pérez'), findsOneWidget);
    // El mail sale de la cuenta, no del documento.
    expect(find.text('ana@comunidadort.edu.ar'), findsOneWidget);
    expect(find.text('viejo@comunidadort.edu.ar'), findsNothing);
    expect(find.text('Ayudante'), findsOneWidget);
  });

  testWidgets('con otro rol muestra ese rol', (tester) async {
    await _abrir(tester, AuthFalso(), _UserServiceFalso(), rol: UserRole.docente);

    expect(find.text('Docente'), findsOneWidget);
  });

  testWidgets('guarda el nombre nuevo en la cuenta y en el documento',
      (tester) async {
    final auth = AuthFalso();
    final usuarios = _UserServiceFalso();
    await _abrir(tester, auth, usuarios);

    await tester.enterText(_campoNombre, '  Ana María Pérez ');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(auth.nombresActualizados, ['Ana María Pérez']);
    expect(usuarios.nombres, [('u1', 'Ana María Pérez')]);
    expect(find.text('Nombre actualizado'), findsOneWidget);
  });

  testWidgets('un nombre inválido se avisa en el campo y no guarda nada',
      (tester) async {
    final auth = AuthFalso();
    final usuarios = _UserServiceFalso();
    await _abrir(tester, auth, usuarios);

    await tester.enterText(_campoNombre, '   ');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text(ValidacionesAuth.avisoNombre), findsOneWidget);
    expect(auth.nombresActualizados, isEmpty);
    expect(usuarios.nombres, isEmpty);
  });

  testWidgets('si la cuenta no lo guarda, no toca el documento ni dice que se guardó',
      (tester) async {
    final auth = AuthFalso()..cambiarNombre = false;
    final usuarios = _UserServiceFalso();
    await _abrir(tester, auth, usuarios);

    await tester.enterText(_campoNombre, 'Ana María');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(usuarios.nombres, isEmpty);
    expect(find.text('Nombre actualizado'), findsNothing);
  });

  testWidgets('"Cerrar sesión" cierra la sesión', (tester) async {
    final auth = AuthFalso();
    await _abrir(tester, auth, _UserServiceFalso());

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pump();

    expect(auth.cierresDeSesion, 1);
  });
}
