import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'validaciones_auth.dart';

/// Revisa lo escrito en el formulario de ingreso y, si está bien, inicia sesión.
///
/// Si Firebase rechaza el ingreso, `AuthService` ya muestra el motivo en un
/// cartel: acá no se repite. Al entrar bien, el router lleva solo a Inventario.
Future<void> loginCheck(
  BuildContext context, {
  required String email,
  required String password,
}) async {
  final avisos = ScaffoldMessenger.of(context);

  final problema = ValidacionesAuth.ingreso(email: email, password: password);
  if (problema != null) {
    avisos.showSnackBar(SnackBar(content: Text(problema)));
    return;
  }

  final usuario = await AuthService().signInWithEmailAndPassword(
    email.trim(),
    password,
  );
  if (usuario != null) {
    avisos.showSnackBar(const SnackBar(content: Text('Ingreso exitoso.')));
  }
}
