import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/usuario.dart';
import '../services/user_service.dart';
import 'usuario_provider.dart';

final userServiceProvider =
    Provider((ref) => UserService(FirebaseFirestore.instance));

// Los usuarios activos, en tiempo real y ordenados por nombre. Se redibuja solo
// ante cualquier cambio en Firestore, también los que hace esta misma pantalla.
final usuariosProvider = StreamProvider<List<Usuario>>(
  (ref) => ref.watch(userServiceProvider).watchAll(),
);

// Todos los usuarios, también los dados de baja, para poder reactivarlos.
final usuariosConBajasProvider = StreamProvider<List<Usuario>>(
  (ref) => ref.watch(userServiceProvider).watchTodos(),
);

/// Por qué no se dejó hacer un cambio sobre un usuario.
enum MotivoUsuarioRechazado {
  /// El administrador intentó cambiarse el rol o darse de baja a sí mismo.
  propioUsuario,

  /// El cambio dejaría al sistema sin ningún administrador.
  ultimoAdministrador,
}

/// Se lanza cuando una regla de negocio impide el cambio. La pantalla la
/// atrapa y muestra el motivo; cualquier otro error es de Firestore.
class UsuarioRechazadoException implements Exception {
  const UsuarioRechazadoException(this.motivo);

  final MotivoUsuarioRechazado motivo;

  @override
  String toString() => 'UsuarioRechazadoException($motivo)';
}

/// Acciones de la pantalla de Gestión de usuarios. Validan las reglas de
/// negocio y escriben en Firestore; la pantalla se actualiza sola a través de
/// [usuariosProvider].
class UsuariosAcciones {
  UsuariosAcciones(this._ref);

  final Ref _ref;

  /// Deshace la baja de [usuario]: vuelve a poder usar la app.
  Future<void> reactivar(Usuario usuario) {
    return _ref.read(userServiceProvider).reactivar(usuario.id);
  }

  /// Cambia el rol de [usuario]. Si ya tiene ese rol no escribe nada.
  Future<void> cambiarRol(Usuario usuario, UserRole nuevoRol) {
    if (usuario.rol == nuevoRol) return Future.value();

    _validarQueSePuedaModificar(usuario);
    return _ref.read(userServiceProvider).updateRol(usuario.id, nuevoRol);
  }

  /// Da de baja a [usuario] (baja lógica: el documento queda con
  /// `activo = false`).
  Future<void> eliminar(Usuario usuario) {
    _validarQueSePuedaModificar(usuario);
    return _ref.read(userServiceProvider).delete(usuario.id);
  }

  // Las dos acciones (cambiar rol y dar de baja) le quitan el acceso de
  // administrador a quien lo tenga, así que comparten las mismas reglas.
  void _validarQueSePuedaModificar(Usuario usuario) {
    if (usuario.id == _ref.read(usuarioActualIdProvider)) {
      throw const UsuarioRechazadoException(
        MotivoUsuarioRechazado.propioUsuario,
      );
    }
    if (_esUltimoAdministrador(usuario)) {
      throw const UsuarioRechazadoException(
        MotivoUsuarioRechazado.ultimoAdministrador,
      );
    }
  }

  // Si la lista todavía no cargó se asume que sí: ante la duda, no se toca el
  // único acceso total del sistema.
  bool _esUltimoAdministrador(Usuario usuario) {
    if (usuario.rol != UserRole.administrador) return false;
    final usuarios = _ref.read(usuariosProvider).value ?? const <Usuario>[];
    final administradores =
        usuarios.where((u) => u.rol == UserRole.administrador).length;
    return administradores <= 1;
  }
}

final usuariosAccionesProvider = Provider((ref) => UsuariosAcciones(ref));