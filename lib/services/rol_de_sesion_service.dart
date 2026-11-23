import '../models/usuario.dart';

/// Quién inició sesión, según Firebase Authentication.
typedef PersonaConSesion = ({String uid, String? nombre, String? email});

/// Averigua qué rol tiene la persona que inició sesión, a partir de su
/// documento en la colección "usuarios".
///
/// - **Cuenta nueva** (o cuenta que existía antes de que hubiera documentos):
///   no tiene documento todavía, así que se le crea uno con el rol de menos
///   permisos, [rolPorDefecto]. Nunca se le da un rol más alto sin que alguien
///   lo decida: el primer administrador se cambia a mano en la consola de
///   Firebase y los demás los cambia ese administrador.
/// - **Cuenta con documento:** se usa su rol, y se avisa cuando cambia (por
///   ejemplo, si un administrador se lo cambia mientras la persona usa la app).
///
/// Las funciones que hablan con Firestore se reciben de afuera para poder
/// probar esto sin base de datos.
class RolDeSesionService {
  RolDeSesionService({
    required Future<void> Function(Usuario nuevo) crearSiNoExiste,
    required Stream<Usuario?> Function(String uid) vigilar,
  })  : _crearSiNoExiste = crearSiNoExiste,
        _vigilar = vigilar;

  final Future<void> Function(Usuario nuevo) _crearSiNoExiste;
  final Stream<Usuario?> Function(String uid) _vigilar;

  /// El rol de una cuenta que nadie asignó: el que menos puede hacer.
  static const UserRole rolPorDefecto = UserRole.docente;

  /// El rol de la persona, y cada vez que cambia.
  ///
  /// Si no se puede crear el documento (sin conexión o sin permiso) igual se
  /// sigue con lo que haya: no poder escribir no tiene que dejar a la persona
  /// sin pantalla. Si tampoco se puede leer, el error le llega a quien escucha,
  /// que se queda con [rolPorDefecto].
  Stream<UserRole> rolDe(PersonaConSesion persona) async* {
    try {
      await _crearSiNoExiste(usuarioNuevo(persona));
    } catch (_) {
      // Se sigue: puede que el documento ya exista y solo falle la escritura.
    }
    yield* _vigilar(persona.uid).map(rolDelUsuario);
  }

  /// Si la cuenta de la persona sigue activa, y cada vez que cambia. Una cuenta
  /// dada de baja (`activo: false`) queda bloqueada: la app no la deja usar. No
  /// crea el documento (eso lo hace [rolDe]); sin documento la cuenta cuenta como
  /// activa, porque todavía nadie la dio de baja.
  Stream<bool> activaDe(PersonaConSesion persona) =>
      _vigilar(persona.uid).map(estaActiva);

  /// Si un documento corresponde a una cuenta activa. Sin documento, sí.
  static bool estaActiva(Usuario? usuario) => usuario?.activo ?? true;

  /// El documento que se crea la primera vez que una persona entra.
  static Usuario usuarioNuevo(PersonaConSesion persona) => Usuario(
        id: persona.uid,
        nombre: nombreInicial(nombre: persona.nombre, email: persona.email),
        email: persona.email ?? '',
        rol: rolPorDefecto,
      );

  /// El nombre con el que arranca una cuenta: el de Firebase si lo tiene, si
  /// no lo que va antes de la @ del mail, y si tampoco hay mail "Sin nombre".
  /// Un nombre vacío o de solo espacios no cuenta.
  static String nombreInicial({String? nombre, String? email}) {
    final propio = nombre?.trim() ?? '';
    if (propio.isNotEmpty) return propio;

    final antesDeLaArroba = (email ?? '').split('@').first.trim();
    return antesDeLaArroba.isNotEmpty ? antesDeLaArroba : 'Sin nombre';
  }

  /// El rol que vale para un documento: sin documento, o dado de baja, es
  /// [rolPorDefecto].
  static UserRole rolDelUsuario(Usuario? usuario) {
    if (usuario == null || !usuario.activo) return rolPorDefecto;
    return usuario.rol;
  }
}
