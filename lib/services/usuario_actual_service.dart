import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/usuario.dart';
import '../models/usuario_actual.dart';
import 'user_service.dart';

/// Lo que se sabe de la sesión de Firebase de la persona.
typedef DatosDeSesion = ({String uid, String? nombre, String? email});

/// Averigua quién está usando la app y con qué nombre, para dejar constancia de
/// lo que hace (por ejemplo, en el historial de movimientos de stock).
///
/// El nombre sale, en este orden, de: el documento de la persona en la colección
/// "usuarios", el nombre de su cuenta de Firebase, su email, o "Sin nombre". Si
/// no hay sesión, es [UsuarioActual.sinSesion].
///
/// Nunca falla: si no se puede leer el documento (sin conexión, sin permiso,
/// todavía no existe), se usa lo que trae la sesión. Que no se pueda saber el
/// nombre no tiene que impedir registrar lo que la persona hizo.
class UsuarioActualService {
  UsuarioActualService({
    DatosDeSesion? Function()? sesion,
    Future<Usuario?> Function(String uid)? buscarUsuario,
  })  : _sesion = sesion ?? _sesionDeFirebase,
        _buscarUsuario = buscarUsuario ?? _usuarioDeFirestore;

  final DatosDeSesion? Function() _sesion;
  final Future<Usuario?> Function(String uid) _buscarUsuario;

  static DatosDeSesion? _sesionDeFirebase() {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return null;
    return (
      uid: usuario.uid,
      nombre: usuario.displayName,
      email: usuario.email,
    );
  }

  static Future<Usuario?> _usuarioDeFirestore(String uid) {
    return UserService(FirebaseFirestore.instance).getById(uid);
  }

  Future<UsuarioActual> obtener() async {
    final sesion = _sesion();
    if (sesion == null) return UsuarioActual.sinSesion;

    Usuario? usuario;
    try {
      usuario = await _buscarUsuario(sesion.uid);
    } catch (_) {
      // Sin permiso o sin conexión: se sigue con lo que trae la sesión.
    }
    return resolver(sesion: sesion, nombreDelDocumento: usuario?.nombre);
  }

  /// Elige el nombre a mostrar. Un nombre vacío o de solo espacios no cuenta.
  static UsuarioActual resolver({
    required DatosDeSesion sesion,
    String? nombreDelDocumento,
  }) {
    for (final candidato in [nombreDelDocumento, sesion.nombre, sesion.email]) {
      if (candidato != null && candidato.trim().isNotEmpty) {
        return UsuarioActual(id: sesion.uid, nombre: candidato.trim());
      }
    }
    return UsuarioActual(id: sesion.uid, nombre: UsuarioActual.nombreSinDatos);
  }
}
