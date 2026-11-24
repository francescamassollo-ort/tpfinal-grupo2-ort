import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_logic/registration_check.dart';
import '../../widgets/handy_button_style_one.dart';
import '../../widgets/handy_input_decoration.dart';
import '../../widgets/boton_google.dart';
import '../../widgets/handy_text_button_black.dart';
import '../../widgets/requisitos_contrasena.dart';

/// Crear una cuenta con mail y contraseña. Las contraseñas se escriben ocultas,
/// con un ojo para verlas, igual que en el ingreso.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // Los controles viven en el State, no en build(): si la pantalla se vuelve a
  // dibujar, lo escrito no se pierde, y se liberan al salir.
  final TextEditingController nombre = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();

  bool ocultarContrasena = true;
  bool ocultarConfirmacion = true;

  @override
  void dispose() {
    nombre.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // Con el teclado abierto la pantalla puede quedar chica: que se pueda
        // desplazar en vez de desbordar.
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              spacing: 22,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Crear cuenta',
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 26),
                TextField(
                  controller: nombre,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  // Con este nombre se ve a la persona en Usuarios, el Historial
                  // y los trabajos prácticos.
                  decoration: getInputDecoration('Nombre y apellido'),
                ),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: getInputDecoration('Email'),
                ),
                TextField(
                  controller: password,
                  obscureText: ocultarContrasena,
                  // Redibuja la lista de requisitos a medida que se escribe.
                  onChanged: (_) => setState(() {}),
                  decoration: getInputDecoration('Contraseña').copyWith(
                    suffixIcon: _Ojo(
                      oculto: ocultarContrasena,
                      onPressed: () => setState(
                        () => ocultarContrasena = !ocultarContrasena,
                      ),
                    ),
                  ),
                ),
                RequisitosContrasena(contrasena: password.text),
                TextField(
                  controller: confirmPassword,
                  obscureText: ocultarConfirmacion,
                  decoration: getInputDecoration('Confirmar contraseña').copyWith(
                    suffixIcon: _Ojo(
                      oculto: ocultarConfirmacion,
                      onPressed: () => setState(
                        () => ocultarConfirmacion = !ocultarConfirmacion,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: getButtonStyleOne(),
                    onPressed: () {
                      registrationCheck(
                        context,
                        auth: ref.read(authServiceProvider),
                        nombre: nombre.text,
                        email: email.text,
                        password: password.text,
                        confirmPassword: confirmPassword.text,
                      );
                    },
                    child: const Text('Registrarse'),
                  ),
                ),
                const BotonGoogle(),
                const HandyTextButtonBlack(
                  textPhrase: 'Ya tengo una cuenta',
                  direction: '/login',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El ojo que muestra u oculta lo escrito en un campo de contraseña.
class _Ojo extends StatelessWidget {
  const _Ojo({required this.oculto, required this.onPressed});

  final bool oculto;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: oculto ? 'Mostrar contraseña' : 'Ocultar contraseña',
      icon: Icon(oculto ? Icons.visibility_off : Icons.visibility),
    );
  }
}
