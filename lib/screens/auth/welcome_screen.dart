import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import './styles/handy_welcome_button_styles.dart';
import '../../core/app_colors.dart';
import '../../widgets/logo_ort.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
// verificar const!!!
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const LogoOrt(ancho: 300),
            
            Column(
              children: [
                Text(
                  'Bio Tecnologia',
                  style:  GoogleFonts.poppins(
                    fontSize: 35,
                    fontWeight: FontWeight(600),
                    color: AppColors.primary,
                  ),
                ),                
                Text(
                  'Gestor de insumos',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight(500),
                    color: AppColors.primary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            
            // Los botones llenan el ancho disponible hasta un máximo: en el
            // celular ocupan casi toda la fila y en la web no quedan perdidos
            // en los extremos de una pantalla ancha.
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: ElevatedButton(
                            style: HandyWelcomeButtonStyles(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.cardBackground,
                            ).getStyle(),
                            onPressed: () => context.push('/login'),
                            child: const Text('Ingresar'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: ElevatedButton(
                            style: HandyWelcomeButtonStyles(
                              backgroundColor: AppColors.cardBackground,
                              foregroundColor: const Color.fromARGB(255, 1, 1, 1),
                            ).getStyle(),
                            onPressed: () => context.push('/register'),
                            child: const Text('Registrarse'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
