
import 'package:firebase_auth/firebase_auth.dart';
import './auth_service.dart';
import 'package:flutter/material.dart';

void registrationCheck(BuildContext context, {String? email, String? password, String? confirmPassword}) async {
  final AuthService auth = AuthService();
  final contextVariable = ScaffoldMessenger.of(context);
  if (email!.isEmpty) {
    contextVariable.showSnackBar(const SnackBar(content: Text('No dejar espacio vacio en campo Email!!!')));
  } else if (email.length > 20) {
    contextVariable.showSnackBar(const SnackBar(content: Text('Contraseña no debe ser mayor a 20 caracteres!!')));
  } else if (password!.isEmpty || confirmPassword!.isEmpty){
    contextVariable.showSnackBar(const SnackBar(content: Text('No dejar espacio vacio en contraseñas!!!')));
  } else if (password != confirmPassword){
    // throw alert
    contextVariable.showSnackBar(const SnackBar(content: Text('Contraseñas no coinciden!!!')));
  } else {
    debugPrint('registro tal');
    User? user = await auth.registerWithEmailAndPassword(email, password);
    if (user != null) {
      contextVariable.showSnackBar(const SnackBar(content: Text('Registro exitoso.')));
    } else {
      contextVariable.showSnackBar(const SnackBar(content: Text('Registro Fallido.')));
    }
  }
}
