import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'validaciones_auth.dart';

/// Pide el correo para elegir una contraseña nueva, con el mail escrito en el
/// formulario de ingreso.
///
/// El aviso de éxito es el mismo exista o no una cuenta con ese mail: así no se
/// puede usar esta pantalla para averiguar qué mails están registrados.
Future<void> recoveryCheck(
  BuildContext context, {
  required AuthService auth,
  required String email,
}) async {
  final avisos = ScaffoldMessenger.of(context);

  final problema = ValidacionesAuth.recuperacion(email: email);
  if (problema != null) {
    avisos.showSnackBar(SnackBar(content: Text(problema)));
    return;
  }

  final seMando = await auth.sendPasswordReset(email.trim());
  if (seMando) {
    avisos.showSnackBar(
      const SnackBar(content: Text(ValidacionesAuth.avisoRecuperacionEnviada)),
    );
  }
}
