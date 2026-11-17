import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/handy_elevated_button.dart';
import '../../widgets/handy_text_button_black.dart';
import '../../widgets/handy_text_field.dart';
import '../../widgets/handy_text_button_blue.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
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
                  HandyTextField(textForHint: 'Email Institucional'),
                  HandyTextField(textForHint: 'Contraseña'),
                  HandyTextButtonBlue(textPhrase: 'Olvidé mi contraseña',),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: HandyElevatedButton(textPhrase: 'Ingresar'),
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
