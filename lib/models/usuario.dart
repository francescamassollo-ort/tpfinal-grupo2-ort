import 'package:cloud_firestore/cloud_firestore.dart';
 
enum UserRole { administrador, ayudante, docente }
 
class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.puedeVerSedronar = false,
    this.activo = true,
  });
 
  final String id;
  final String nombre;
  final String email;
  final UserRole rol;
  final bool puedeVerSedronar;
 
  // Baja lógica: UserService.delete lo pone en false en vez de borrar.
  final bool activo;
 
  // El id no va dentro del JSON: es el id del documento en Firestore, por
  // eso se recibe aparte (igual que Insumo.fromMap).
  factory Usuario.fromJson(String id, Map<String, dynamic> json) {
    return Usuario(
      id: id,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      rol: UserRole.values.byName(json['rol'] as String),
      puedeVerSedronar: (json['puedeVerSedronar'] as bool?) ?? false,
      activo: (json['activo'] as bool?) ?? true,
    );
  }
 
  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'email': email,
        'rol': rol.name,
        'puedeVerSedronar': puedeVerSedronar,
        'activo': activo,
      };
 
  // Para usar el modelo con withConverter en UserService.
  factory Usuario.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) =>
      Usuario.fromJson(snapshot.id, snapshot.data()!);
 
  Map<String, dynamic> toFirestore() => toJson();
 
  Usuario copyWith({
    String? nombre,
    String? email,
    UserRole? rol,
    bool? puedeVerSedronar,
    bool? activo,
  }) =>
      Usuario(
        id: id,
        nombre: nombre ?? this.nombre,
        email: email ?? this.email,
        rol: rol ?? this.rol,
        puedeVerSedronar: puedeVerSedronar ?? this.puedeVerSedronar,
        activo: activo ?? this.activo,
      );
 
  @override
  bool operator ==(Object other) =>
      other is Usuario &&
      other.id == id &&
      other.nombre == nombre &&
      other.email == email &&
      other.rol == rol &&
      other.puedeVerSedronar == puedeVerSedronar &&
      other.activo == activo;
 
  @override
  int get hashCode =>
      Object.hash(id, nombre, email, rol, puedeVerSedronar, activo);
}