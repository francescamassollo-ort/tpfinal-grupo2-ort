import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './auth_logic/login_check.dart';
import '../../widgets/handy_input_decoration.dart';
import '../../widgets/handy_button_style_one.dart';
import '../../widgets/handy_text_button_black.dart';
import '../../widgets/handy_text_button_blue.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final TextEditingController email = TextEditingController();
    final TextEditingController password = TextEditingController();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Image(
              image: AssetImage('assets/images/imagenLogoOrt1.png'),
              height: 200,
            ),
            Text(
              'Bio Tecnología - Gestor de insumos',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight(600),
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(
              height: 22,
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 25,
                children: [
                  TextField(
                    controller: email,
                    decoration: getInputDecoration('Email Institucional')
                  ),
                  TextField(
                    controller: password,
                    decoration: getInputDecoration('Contraseña')
                  ),
                  HandyTextButtonBlue(textPhrase: 'Olvidé mi contraseña',), //modificar
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: getButtonStyleOne(),
                      onPressed: (){
                       loginCheck(context, email: email.text, password: password.text);
                      }, 
                      child: Text(
                        'Ingresar',
                      ),
                    ) 
                  ),
                ],
              ),
            ),
            HandyTextButtonBlack(textPhrase: 'Crear una nueva cuenta', direction: '/register'),
          ],
        ),
      ),
    );
  }
}
