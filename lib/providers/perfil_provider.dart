import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/usuario.dart';
import '../services/auth_logic/validaciones_auth.dart';
import 'auth_provider.dart';
import 'role_provider.dart';
import 'usuarios_provider.dart';

// El documento de la persona que inició sesión (colección "usuarios"), y cada
// vez que cambia. De ahí salen el nombre y el rol que muestra Perfil. Sin
// sesión no hay documento: emite null.
final perfilUsuarioProvider = StreamProvider<Usuario?>((ref) async* {
  final persona = await ref.watch(sesionProvider.future);
  // Si mientras tanto cambió la sesión, este cálculo ya no vale.
  if (!ref.mounted || persona == null) {
    yield null;
    return;
  }

  yield* ref.watch(userServiceProvider).watchById(persona.uid);
});

/// Por qué no se pudo cambiar el nombre.
enum MotivoNombreRechazado {
  /// El nombre no pasa la validación (vacío, sin letras o demasiado largo).
  invalido,

  /// No hay una sesión iniciada.
  sinSesion,

  /// Firebase Authentication no lo guardó. El motivo ya se mostró en un cartel.
  noSeGuardoEnLaCuenta,
}

/// Se lanza cuando no se puede cambiar el nombre por una regla de negocio.
/// Cualquier otro error es de Firestore.
class NombreRechazadoException implements Exception {
  const NombreRechazadoException(this.motivo);

  final MotivoNombreRechazado motivo;

  @override
  String toString() => 'NombreRechazadoException($motivo)';
}

/// Acciones de la pantalla de Perfil. Validan y escriben en los dos lugares donde
/// vive el nombre: la cuenta de Firebase (de ahí sale el que se ve en el
/// Historial y en los TPs) y el documento de la colección "usuarios" (el que se
/// ve en Usuarios).
class PerfilAcciones {
  PerfilAcciones(this._ref);

  final Ref _ref;

  /// Cambia el nombre de la persona que inició sesión. Devuelve el nombre ya
  /// limpio (sin espacios en los extremos), que es el que quedó guardado.
  ///
  /// Primero se guarda en la cuenta: si eso falla no se toca el documento, así
  /// los dos lugares no quedan con nombres distintos.
  Future<String> cambiarNombre(String nombre) async {
    if (!ValidacionesAuth.esNombreValido(nombre)) {
      throw const NombreRechazadoException(MotivoNombreRechazado.invalido);
    }
    // El uid sale de la cuenta en el momento de guardar, no de un stream.
    final auth = _ref.read(authServiceProvider);
    final uid = auth.uidActual;
    if (uid == null) {
      throw const NombreRechazadoException(MotivoNombreRechazado.sinSesion);
    }

    final limpio = nombre.trim();
    final guardado = await auth.updateNombre(limpio);
    if (!guardado) {
      throw const NombreRechazadoException(
        MotivoNombreRechazado.noSeGuardoEnLaCuenta,
      );
    }
    await _ref.read(userServiceProvider).updateNombre(uid, limpio);
    return limpio;
  }
}

final perfilAccionesProvider = Provider((ref) => PerfilAcciones(ref));
