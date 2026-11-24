import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'validaciones_auth.dart';

/// Revisa lo escrito en el formulario de registro y, si está bien, crea la
/// cuenta y manda el correo para verificar el mail.
///
/// Si Firebase rechaza el registro (mail mal escrito, cuenta repetida),
/// `AuthService` ya muestra el motivo en un cartel: acá no se repite. Al
/// registrarse bien, el router lleva solo a la pantalla que pide verificar el
/// mail.
Future<void> registrationCheck(
  BuildContext context, {
  required AuthService auth,
  required String nombre,
  required String email,
  required String password,
  required String confirmPassword,
}) async {
  final avisos = ScaffoldMessenger.of(context);

  final problema = ValidacionesAuth.registro(
    nombre: nombre,
    email: email,
    password: password,
    confirmacion: confirmPassword,
  );
  if (problema != null) {
    avisos.showSnackBar(SnackBar(content: Text(problema)));
    return;
  }

  final seCreo = await auth.registerWithEmailAndPassword(
    email.trim(),
    password,
    nombre: nombre.trim(),
  );
  if (!seCreo) return;

  // Si el correo no sale, la cuenta igual quedó creada: la pantalla de
  // verificación permite reenviarlo.
  await auth.sendEmailVerification();
  avisos.showSnackBar(const SnackBar(content: Text('Registro exitoso.')));
}
