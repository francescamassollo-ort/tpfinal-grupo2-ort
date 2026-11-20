import 'package:firebase_auth/firebase_auth.dart';
import './auth_service.dart';
import 'package:flutter/material.dart';

void loginCheck(BuildContext context, {String? email, String? password}) async {
  final AuthService auth = AuthService();
  final contextVariable = ScaffoldMessenger.of(context);
  if (email!.isEmpty) {
    contextVariable.showSnackBar(const SnackBar(content: Text('No dejar espacio vacio en campo Email!!!')));
  }  else if (password!.isEmpty){
    contextVariable.showSnackBar(const SnackBar(content: Text('No dejar espacio vacio en contraseñas!!!')));
  } else {
    debugPrint('registro tal');
    User? user = await auth.signInWithEmailAndPassword(email, password);
    if (user != null) {
      contextVariable.showSnackBar(const SnackBar(content: Text('Ingreso exitoso.')));
    } else {
      contextVariable.showSnackBar(const SnackBar(content: Text('Ingreso Fallido.')));
    }
  }
}