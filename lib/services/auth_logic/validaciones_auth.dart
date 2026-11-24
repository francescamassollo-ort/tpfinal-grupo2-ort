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
  static const String avisoNombre = 'Escribí tu nombre y apellido';
  static const String avisoMailNoInstitucional =
      'Usá tu mail institucional de ORT (@comunidadort.edu.ar o @ort.edu.ar)';
  static const String avisoRecuperacionVacia =
      'Escribí tu mail en el campo Email y volvé a tocar "Olvidé mi contraseña"';
  static const String avisoRecuperacionEnviada =
      'Si ese mail tiene una cuenta, te mandamos un correo para elegir una '
      'contraseña nueva';
  static const String avisoContrasenaDebil =
      'La contraseña tiene que tener al menos 8 caracteres, una mayúscula, '
      'una minúscula, un número y un símbolo';

  /// Los dominios de mail que cuentan como institucionales de ORT (requisito
  /// R14: ingreso con mail institucional).
  static const List<String> dominiosInstitucionales = [
    'comunidadort.edu.ar',
    'ort.edu.ar',
  ];

  /// El largo máximo del nombre: alcanza para nombres y apellidos compuestos y
  /// evita que un texto larguísimo desarme las listas donde se muestra.
  static const int largoMaximoNombre = 60;

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

  /// Recuperar la contraseña: hace falta el mail. No se exige que sea
  /// institucional: la cuenta puede ser anterior a esa regla.
  static String? recuperacion({required String email}) =>
      email.trim().isEmpty ? avisoRecuperacionVacia : null;

  /// Registro: hace falta el nombre, el mail no puede estar vacío y tiene que
  /// ser institucional, las dos contraseñas tienen que ser iguales y la
  /// contraseña tiene que ser segura (ver [requisitosFaltantes]).
  ///
  /// No se limita el largo del mail: los institucionales
  /// (`usuario@comunidadort.edu.ar`) tienen más de 20 caracteres.
  static String? registro({
    required String nombre,
    required String email,
    required String password,
    required String confirmacion,
  }) {
    if (!esNombreValido(nombre)) return avisoNombre;
    if (email.trim().isEmpty) return avisoEmailVacio;
    if (!esMailInstitucional(email)) return avisoMailNoInstitucional;
    if (password.isEmpty || confirmacion.isEmpty) return avisoContrasenaVacia;
    if (password != confirmacion) return avisoNoCoinciden;
    if (requisitosFaltantes(password).isNotEmpty) return avisoContrasenaDebil;
    return null;
  }

  /// Si [nombre] sirve como nombre de una persona: tiene alguna letra (no vale
  /// solo un número, que es lo que se ve cuando el nombre sale del mail de un
  /// alumno) y no pasa de [largoMaximoNombre] caracteres. Los espacios de los
  /// extremos no cuentan.
  static bool esNombreValido(String nombre) {
    final limpio = nombre.trim();
    return limpio.length <= largoMaximoNombre &&
        RegExp(r'\p{L}', unicode: true).hasMatch(limpio);
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
