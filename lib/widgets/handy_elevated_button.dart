import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';

class HandyElevatedButton extends StatelessWidget {
  final String textPhrase;
  const HandyElevatedButton({super.key, required this.textPhrase});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.primary),
        foregroundColor: WidgetStatePropertyAll(AppColors.cardBackground),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10))),
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.poppins(
            fontSize: 19,
            fontWeight: FontWeight(600),
            letterSpacing: 2,
          ),
        ),
      ),
      onPressed: (){
        debugPrint('HandyElevatedButton working!!');
      }, 
      child: Text(
        textPhrase,
      ),
    );
  }
}

