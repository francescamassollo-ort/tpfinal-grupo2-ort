import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/handy_elevated_button.dart';
import '../../widgets/handy_text_button_black.dart';
import '../../widgets/handy_text_field.dart';
import '../../core/app_colors.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            spacing: 22,
            children: [
              SizedBox(height: 20,),
              Text(
                'Crear cuenta',
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontSize: 26,
                  fontWeight: FontWeight(700),
                ),
              ),
              SizedBox(height: 26,),
              HandyTextField(textForHint: 'Email'),
              HandyTextField(textForHint: 'Contraseña'),
              HandyTextField(textForHint: 'Confirmar contraseña'),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: HandyElevatedButton(textPhrase: 'Registrarse')
              ),
              HandyTextButtonBlack(textPhrase: 'Ya tengo una cuenta', direction: '/login',),
            ],
          ),
        ),
      ),
    );
  }
}
