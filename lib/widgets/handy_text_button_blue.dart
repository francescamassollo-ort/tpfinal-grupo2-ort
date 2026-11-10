import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';

class HandyTextButtonBlue extends StatelessWidget {

  final String textPhrase;

  const HandyTextButtonBlue({super.key, required this.textPhrase});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: (){

      }, 
      child: Text(
        textPhrase,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight(600),
          fontSize: 13,
          color: AppColors.primary,
        ),
      )
    );
  }
}
