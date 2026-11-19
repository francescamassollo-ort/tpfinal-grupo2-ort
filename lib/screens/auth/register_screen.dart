import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './auth_logic/registration_check.dart';
import '../../widgets/handy_input_decoration.dart';
import '../../widgets/handy_button_style_one.dart';
import '../../widgets/handy_text_button_black.dart';
import '../../core/app_colors.dart';


class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final TextEditingController email = TextEditingController();
    final TextEditingController password = TextEditingController();
    final TextEditingController confirmPassword = TextEditingController();
    
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
              TextField(
                controller: email,
                decoration: getInputDecoration('Email')
              ),
              TextField(
                controller: password,
                decoration: getInputDecoration('Contraseña')
              ),
              TextField(
                controller: confirmPassword,
                decoration: getInputDecoration('Confirmar contraseña')
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: getButtonStyleOne(),
                  onPressed: (){
                    //debugPrint('HandyElevatedButton working!!');
                    registrationCheck(context, email: email.text, password:  password.text, confirmPassword:  confirmPassword.text);
                  }, 
                  child: Text(
                    'Registrarse',
                  ),
                ) 
              ),
              HandyTextButtonBlack(textPhrase: 'Ya tengo una cuenta', direction: '/login',),
            ],
          ),
        ),
      ),
    );
  }
}
