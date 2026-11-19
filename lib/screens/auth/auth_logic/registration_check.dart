import 'package:firebase_auth/firebase_auth.dart';
import './auth_service.dart';
import 'package:flutter/material.dart';

void registrationCheck(BuildContext context, {String? email, String? password, String? confirmPassword}) async {
  final AuthService auth = AuthService();
  if (email!.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No dejar espacio vacio en campo Email!!!')));
  }  else if (password == '' || confirmPassword == ''){
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No dejar espacio vacio en contraseñas!!!')));
  } else if (password != confirmPassword){
    // throw alert
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseñas no coinciden!!!')));
  } else {
    debugPrint('registro tal');
    // send to auth so it checks what to do
    /*
    User? user = await auth.registerWithEmailAndPassword(email, password!);
      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registered Successfully!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration Failed.')));
      }
      */
  }
}

/*
 User? user = await _auth.registerWithEmailAndPassword(_emailController.text, _passwordController.text);
                if (user != null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registered Successfully!')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration Failed.')));
                }
*/