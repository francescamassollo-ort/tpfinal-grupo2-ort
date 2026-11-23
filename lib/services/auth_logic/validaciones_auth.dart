/// Las comprobaciones de los formularios de ingreso y de registro, antes de
/// hablar con Firebase. Son funciones puras (no tocan la red) para poder
/// probarlas solas.
///
/// Devuelven el aviso para mostrar, o null si todo está bien. Lo que depende de
/// Firebase (mail mal escrito, contraseña de menos de 6 caracteres, cuenta
/// repetida) no se revisa acá: lo explica `AuthService` con el motivo exacto.
class ValidacionesAuth {
  ValidacionesAuth._();

  static const String avisoEmailVacio = 'No dejar espacio vacio en campo Email!!!';
  static const String avisoContrasenaVacia =
      'No dejar espacio vacio en contraseñas!!!';
  static const String avisoNoCoinciden = 'Contraseñas no coinciden!!!';

  /// Ingreso: el mail y la contraseña no pueden estar vacíos. Los espacios de
  /// los extremos del mail no cuentan (el teclado del celular suele agregar uno
  /// al autocompletar).
  static String? ingreso({required String email, required String password}) {
    if (email.trim().isEmpty) return avisoEmailVacio;
    if (password.isEmpty) return avisoContrasenaVacia;
    return null;
  }

  /// Registro: lo mismo que el ingreso, y las dos contraseñas tienen que ser
  /// iguales.
  ///
  /// No se limita el largo del mail: los institucionales
  /// (`usuario@comunidadort.edu.ar`) tienen más de 20 caracteres.
  static String? registro({
    required String email,
    required String password,
    required String confirmacion,
  }) {
    if (email.trim().isEmpty) return avisoEmailVacio;
    if (password.isEmpty || confirmacion.isEmpty) return avisoContrasenaVacia;
    if (password != confirmacion) return avisoNoCoinciden;
    return null;
  }
}
