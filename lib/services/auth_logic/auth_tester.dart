

import 'package:flutter/material.dart';
import 'package:tpfinal_grupo2/services/auth_logic/auth_service.dart';

class AuthTester extends StatelessWidget {
  const AuthTester({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService auth = AuthService();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Text('test area'),
              TextButton(
                onPressed: () async {
                  await auth.signOut();
                }, 
                child: Text('sign out'))
          
            ]
          ),
        )
      )
    );
  }
}

/*
Esto solo existe para probar y modificar auth cuando la base de datos no funciona.
Se puede borrar sin problemas.
*/