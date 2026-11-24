import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_logic/login_check.dart';
import '../../services/auth_logic/recovery_check.dart';
import '../../widgets/boton_google.dart';
import '../../widgets/handy_input_decoration.dart';
import '../../widgets/handy_button_style_one.dart';
import '../../widgets/handy_text_button_black.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool obscurePassword = true;
  
  @override
  void dispose(){
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {  
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                      obscureText: obscurePassword,
                      decoration: getInputDecoration('Contraseña').copyWith(
                        suffixIcon: IconButton(onPressed: (){
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        }, icon: Icon(
                          obscurePassword ? Icons.visibility_off : Icons.visibility
                        ))
                      )
                    ),
                    // Pide el correo para elegir una contraseña nueva, con el mail
                    // que ya se escribió arriba.
                    TextButton(
                      onPressed: () => recoveryCheck(
                        context,
                        auth: ref.read(authServiceProvider),
                        email: email.text,
                      ),
                      child: Text(
                        'Olvidé mi contraseña',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight(500),
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: getButtonStyleOne(),
                        onPressed: (){
                          loginCheck(
                            context,
                            auth: ref.read(authServiceProvider),
                            email: email.text,
                            password: password.text,
                          );
                        }, 
                        child: Text(
                          'Ingresar',
                        ),
                      ) 
                    ),
                    const BotonGoogle(),
                  ],
                ),
              ),
              HandyTextButtonBlack(textPhrase: 'Crear una nueva cuenta', direction: '/register'),
            ],
          ),
        ),
      ),
    );
  }
}
