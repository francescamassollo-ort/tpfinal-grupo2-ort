import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'validaciones_auth.dart';

/// Revisa lo escrito en el formulario de ingreso y, si está bien, inicia sesión.
///
/// Si Firebase rechaza el ingreso, `AuthService` ya muestra el motivo en un
/// cartel: acá no se repite. Al entrar bien, el router lleva solo a Inventario
/// (o a pedir que se verifique el mail).
Future<void> loginCheck(
  BuildContext context, {
  required AuthService auth,
  required String email,
  required String password,
}) async {
  final avisos = ScaffoldMessenger.of(context);

  final problema = ValidacionesAuth.ingreso(email: email, password: password);
  if (problema != null) {
    avisos.showSnackBar(SnackBar(content: Text(problema)));
    return;
  }

  final entro = await auth.signInWithEmailAndPassword(email.trim(), password);
  if (entro) {
    avisos.showSnackBar(const SnackBar(content: Text('Ingreso exitoso.')));
  }
}
