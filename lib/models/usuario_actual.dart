/// La persona que está usando la app, con lo mínimo que hace falta para dejar
/// constancia de lo que hace (por ejemplo, quién cambió el stock de un insumo).
class UsuarioActual {
  const UsuarioActual({required this.id, required this.nombre});

  /// Id de la persona: el de su cuenta de Firebase, que es también el id de su
  /// documento en la colección "usuarios".
  final String id;
  final String nombre;

  /// Mientras no haya login conectado, nadie tiene sesión y todos figuran con
  /// este id fijo. Es el mismo de `usuarioSinSesion` (usuario_provider.dart).
  static const UsuarioActual sinSesion = UsuarioActual(
    id: 'sin-sesion',
    nombre: 'Sin sesión',
  );

  /// Nombre para alguien con sesión pero sin nombre ni email que mostrar.
  static const String nombreSinDatos = 'Sin nombre';

  @override
  bool operator ==(Object other) =>
      other is UsuarioActual && other.id == id && other.nombre == nombre;

  @override
  int get hashCode => Object.hash(id, nombre);

  @override
  String toString() => 'UsuarioActual($id, $nombre)';
}
