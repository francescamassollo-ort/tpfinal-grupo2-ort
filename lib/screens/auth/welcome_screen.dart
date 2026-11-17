import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import './styles/handy_welcome_button_styles.dart';
import '../../core/app_colors.dart';

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
            Image(
              image: AssetImage('assets/images/imagenLogoOrt1.png'),
              height: 400,
            ),
            
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
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 150,
                  height: 52,
                  child: ElevatedButton(
                    style: HandyWelcomeButtonStyles(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.cardBackground,
                    ).getStyle(),
                    onPressed: (){
                      (context).push('/login');
                    }, 
                    child: Text('Ingresar')
                  ),
                ),
                SizedBox(
                  width: 150,
                  height: 52,
                  child: ElevatedButton(
                    style: HandyWelcomeButtonStyles(
                      backgroundColor: AppColors.cardBackground,
                      foregroundColor: Color.fromARGB(255, 1, 1, 1),
                    ).getStyle(),
                    onPressed: (){
                      (context).push('/register');
                    },
                    child: Text('Registrarse')
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
