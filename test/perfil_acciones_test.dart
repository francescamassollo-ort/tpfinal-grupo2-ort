import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/providers/auth_provider.dart';
import 'package:tpfinal_grupo2/providers/perfil_provider.dart';
import 'package:tpfinal_grupo2/providers/usuarios_provider.dart';
import 'package:tpfinal_grupo2/services/user_service.dart';

import 'helpers/auth_falso.dart';

/// El servicio de usuarios sin Firestore: anota los nombres que se le piden.
class _UserServiceFalso extends Fake implements UserService {
  final nombres = <(String, String)>[];
  Object? falla;

  @override
  Future<void> updateNombre(String usuarioId, String nuevoNombre) async {
    if (falla != null) throw falla!;
    nombres.add((usuarioId, nuevoNombre));
  }
}

PerfilAcciones _acciones(
  AuthFalso auth,
  _UserServiceFalso usuarios, {
  bool conSesion = true,
}) {
  if (!conSesion) auth.uid = null;
  final c = ProviderContainer(
    overrides: [
      authServiceProvider.overrideWithValue(auth),
      userServiceProvider.overrideWithValue(usuarios),
    ],
  );
  addTearDown(c.dispose);
  return c.read(perfilAccionesProvider);
}

Future<MotivoNombreRechazado?> _motivo(Future<Object?> accion) async {
  try {
    await accion;
    return null;
  } on NombreRechazadoException catch (e) {
    return e.motivo;
  }
}

void main() {
  group('PerfilAcciones.cambiarNombre', () {
    test('guarda el nombre sin espacios en la cuenta y en el documento', () async {
      final auth = AuthFalso();
      final usuarios = _UserServiceFalso();
      final acciones = _acciones(auth, usuarios);

      final guardado = await acciones.cambiarNombre('  Ana Pérez ');

      expect(guardado, 'Ana Pérez');
      expect(auth.nombresActualizados, ['Ana Pérez']);
      expect(usuarios.nombres, [('u1', 'Ana Pérez')]);
    });

    test('un nombre vacío o sin letras se rechaza y no escribe nada', () async {
      final auth = AuthFalso();
      final usuarios = _UserServiceFalso();
      final acciones = _acciones(auth, usuarios);

      for (final nombre in ['', '   ', '1234']) {
        expect(
          await _motivo(acciones.cambiarNombre(nombre)),
          MotivoNombreRechazado.invalido,
        );
      }
      expect(auth.nombresActualizados, isEmpty);
      expect(usuarios.nombres, isEmpty);
    });

    test('si la cuenta no lo guarda, no toca el documento', () async {
      final auth = AuthFalso()..cambiarNombre = false;
      final usuarios = _UserServiceFalso();
      final acciones = _acciones(auth, usuarios);

      expect(
        await _motivo(acciones.cambiarNombre('Ana')),
        MotivoNombreRechazado.noSeGuardoEnLaCuenta,
      );
      expect(usuarios.nombres, isEmpty);
    });

    test('sin sesión se rechaza', () async {
      final auth = AuthFalso();
      final usuarios = _UserServiceFalso();
      final acciones = _acciones(auth, usuarios, conSesion: false);

      expect(
        await _motivo(acciones.cambiarNombre('Ana')),
        MotivoNombreRechazado.sinSesion,
      );
      expect(auth.nombresActualizados, isEmpty);
    });

    test('si falla Firestore el error le llega a quien llama', () async {
      final auth = AuthFalso();
      final usuarios = _UserServiceFalso()..falla = StateError('sin permiso');
      final acciones = _acciones(auth, usuarios);

      expect(acciones.cambiarNombre('Ana'), throwsStateError);
    });
  });
}
