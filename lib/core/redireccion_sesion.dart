/// Las pantallas para entrar a la app: Bienvenida, Ingreso y Registro.
const Set<String> rutasDeAcceso = {'/welcome', '/login', '/register'};

/// La pantalla que pide verificar el mail antes de usar la app.
const String rutaVerificarMail = '/verificar-email';

/// A dónde hay que mandar a la persona según su sesión, o null si la pantalla a
/// la que quiere ir está bien.
///
/// - **Sin sesión:** solo las pantallas de acceso; todo lo demás va a Bienvenida.
/// - **Con sesión pero sin verificar el mail:** solo la pantalla de verificación.
///   Así nadie usa la app con un mail que no demostró que es suyo.
/// - **Con sesión y mail verificado:** las pantallas de acceso y la de
///   verificación ya no sirven, va a Inicio.
///
/// Es una función pura para poder probar todas las combinaciones sin Firebase.
String? redirigirSegunSesion({
  required bool conSesion,
  required bool mailVerificado,
  required String ruta,
}) {
  if (!conSesion) {
    return rutasDeAcceso.contains(ruta) ? null : '/welcome';
  }
  if (!mailVerificado) {
    return ruta == rutaVerificarMail ? null : rutaVerificarMail;
  }
  if (rutasDeAcceso.contains(ruta) || ruta == rutaVerificarMail) {
    return '/home';
  }
  return null;
}
