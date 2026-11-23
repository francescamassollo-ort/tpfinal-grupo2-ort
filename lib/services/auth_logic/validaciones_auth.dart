/// Lo que tiene que cumplir una contraseña nueva. Cada uno se muestra como una
/// casilla que se tilda mientras la persona escribe.
enum RequisitoContrasena {
  largo('Al menos 8 caracteres'),
  mayuscula('Una letra mayúscula'),
  minuscula('Una letra minúscula'),
  numero('Un número'),
  simbolo('Un símbolo (por ejemplo ! ? # \$ %)');

  const RequisitoContrasena(this.etiqueta);

  /// El texto que ve la persona.
  final String etiqueta;
}

/// Las comprobaciones de los formularios de ingreso y de registro, antes de
/// hablar con Firebase. Son funciones puras (no tocan la red) para poder
/// probarlas solas.
///
/// Devuelven el aviso para mostrar, o null si todo está bien. Lo que depende de
/// Firebase (mail mal escrito, cuenta repetida) no se revisa acá: lo explica
/// `AuthService` con el motivo exacto.
class ValidacionesAuth {
  ValidacionesAuth._();

  static const String avisoEmailVacio = 'No dejar espacio vacio en campo Email!!!';
  static const String avisoContrasenaVacia =
      'No dejar espacio vacio en contraseñas!!!';
  static const String avisoNoCoinciden = 'Contraseñas no coinciden!!!';
  static const String avisoMailNoInstitucional =
      'Usá tu mail institucional de ORT (@comunidadort.edu.ar o @ort.edu.ar)';
  static const String avisoContrasenaDebil =
      'La contraseña tiene que tener al menos 8 caracteres, una mayúscula, '
      'una minúscula, un número y un símbolo';

  /// Los dominios de mail que cuentan como institucionales de ORT (requisito
  /// R14: ingreso con mail institucional).
  static const List<String> dominiosInstitucionales = [
    'comunidadort.edu.ar',
    'ort.edu.ar',
  ];

  /// El largo mínimo de una contraseña nueva.
  static const int largoMinimoContrasena = 8;

  /// Ingreso: el mail y la contraseña no pueden estar vacíos. Los espacios de
  /// los extremos del mail no cuentan (el teclado del celular suele agregar uno
  /// al autocompletar).
  ///
  /// El ingreso **no** exige mail institucional ni contraseña fuerte: es para
  /// cuentas que ya existen, y esas se crearon antes de estas reglas.
  static String? ingreso({required String email, required String password}) {
    if (email.trim().isEmpty) return avisoEmailVacio;
    if (password.isEmpty) return avisoContrasenaVacia;
    return null;
  }

  /// Registro: el mail no puede estar vacío y tiene que ser institucional, las
  /// dos contraseñas tienen que ser iguales y la contraseña tiene que ser
  /// segura (ver [requisitosFaltantes]).
  ///
  /// No se limita el largo del mail: los institucionales
  /// (`usuario@comunidadort.edu.ar`) tienen más de 20 caracteres.
  static String? registro({
    required String email,
    required String password,
    required String confirmacion,
  }) {
    if (email.trim().isEmpty) return avisoEmailVacio;
    if (!esMailInstitucional(email)) return avisoMailNoInstitucional;
    if (password.isEmpty || confirmacion.isEmpty) return avisoContrasenaVacia;
    if (password != confirmacion) return avisoNoCoinciden;
    if (requisitosFaltantes(password).isNotEmpty) return avisoContrasenaDebil;
    return null;
  }

  /// Si el mail es de un dominio institucional de ORT. No distingue mayúsculas y
  /// no cuenta los espacios de los extremos. El dominio tiene que ser
  /// exactamente uno de [dominiosInstitucionales]: "ana@ort.edu.ar.falso.com" y
  /// "ana@miort.edu.ar" no valen.
  static bool esMailInstitucional(String email) {
    final partes = email.trim().toLowerCase().split('@');
    if (partes.length != 2) return false;
    return partes[0].isNotEmpty && dominiosInstitucionales.contains(partes[1]);
  }

  /// Los requisitos de contraseña que todavía no cumple [contrasena].
  static List<RequisitoContrasena> requisitosFaltantes(String contrasena) => [
        for (final requisito in RequisitoContrasena.values)
          if (!cumple(requisito, contrasena)) requisito,
      ];

  /// Si [contrasena] cumple un requisito. Reconoce las letras con tilde y la ñ
  /// (`\p{Lu}` y `\p{Ll}`); es símbolo cualquier carácter que no sea letra,
  /// número ni espacio.
  static bool cumple(RequisitoContrasena requisito, String contrasena) {
    switch (requisito) {
      case RequisitoContrasena.largo:
        return contrasena.length >= largoMinimoContrasena;
      case RequisitoContrasena.mayuscula:
        return RegExp(r'\p{Lu}', unicode: true).hasMatch(contrasena);
      case RequisitoContrasena.minuscula:
        return RegExp(r'\p{Ll}', unicode: true).hasMatch(contrasena);
      case RequisitoContrasena.numero:
        return RegExp(r'\p{N}', unicode: true).hasMatch(contrasena);
      case RequisitoContrasena.simbolo:
        return RegExp(r'[^\p{L}\p{N}\s]', unicode: true).hasMatch(contrasena);
    }
  }
}
