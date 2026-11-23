import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'validaciones_auth.dart';

/// Revisa lo escrito en el formulario de registro y, si está bien, crea la
/// cuenta.
///
/// Si Firebase rechaza el registro (mail mal escrito, contraseña corta, cuenta
/// repetida), `AuthService` ya muestra el motivo en un cartel: acá no se
/// repite.
Future<void> registrationCheck(
  BuildContext context, {
  required String email,
  required String password,
  required String confirmPassword,
}) async {
  final avisos = ScaffoldMessenger.of(context);

  final problema = ValidacionesAuth.registro(
    email: email,
    password: password,
    confirmacion: confirmPassword,
  );
  if (problema != null) {
    avisos.showSnackBar(SnackBar(content: Text(problema)));
    return;
  }

  final usuario = await AuthService().registerWithEmailAndPassword(
    email.trim(),
    password,
  );
  if (usuario != null) {
    avisos.showSnackBar(const SnackBar(content: Text('Registro exitoso.')));
  }
}
