import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';

/// Único lugar de la app que habla con la colección "usuarios" de Firestore.
/// Solo lo usa el administrador (pantalla de Gestión de usuarios).
///
/// Usa Firestore, no FirebaseAuth: no crea ni borra cuentas de login, solo
/// administra los datos y el rol de cada usuario.
class UserService {
  UserService(FirebaseFirestore db)
      : _ref = db.collection(coleccion).withConverter<Usuario>(
              fromFirestore: Usuario.fromFirestore,
              toFirestore: (usuario, _) => usuario.toFirestore(),
            );

  // Nombre de colección: usuarios.
  // Tiene que coincidir con las reglas de Firestore.
  static const String coleccion = 'usuarios';

  final CollectionReference<Usuario> _ref;

  // ---- Versión Future (una sola lectura) ---------------------------------

  /// Lista de usuarios activos, ordenada por nombre.
  Future<List<Usuario>> getAll() async {
    final snap = await _ref.orderBy('nombre').get();
    // Filtro en Dart para no exigir un índice compuesto en Firestore.
    return snap.docs.map((d) => d.data()).where((u) => u.activo).toList();
  }

  /// Un usuario por su id (el de su cuenta de Firebase), o null si todavía no
  /// tiene documento. Incluye a los dados de baja.
  Future<Usuario?> getById(String usuarioId) async {
    final doc = await _ref.doc(usuarioId).get();
    return doc.exists ? doc.data() : null;
  }

  // ---- Versión Stream (tiempo real) --------------------------------------

  /// Igual que [getAll], pero se actualiza sola ante cambios en Firestore.
  Stream<List<Usuario>> watchAll() {
    return _ref.orderBy('nombre').snapshots().map(
          (snap) =>
              snap.docs.map((d) => d.data()).where((u) => u.activo).toList(),
        );
  }

  // ---- Escrituras --------------------------------------------------------

  /// Cambia solo el rol del usuario, sin tocar el resto de sus campos.
  Future<void> updateRol(String usuarioId, UserRole nuevoRol) {
    return _ref.doc(usuarioId).update({'rol': nuevoRol.name});
  }

  /// Baja lógica: marca al usuario como inactivo y no borra el documento.
  Future<void> delete(String usuarioId) {
    return _ref.doc(usuarioId).update({'activo': false});
  }
}