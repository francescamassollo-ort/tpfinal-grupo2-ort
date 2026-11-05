import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/material.dart';

class HandyWelcomeButtonStyles {

  final Color backgroundColor;
  final Color foregroundColor;

  const HandyWelcomeButtonStyles({required this.backgroundColor, required this.foregroundColor});

  ButtonStyle getStyle(){
    return ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(backgroundColor),
      foregroundColor: WidgetStatePropertyAll(foregroundColor),
      elevation: WidgetStatePropertyAll(2),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(9))),
      textStyle: WidgetStatePropertyAll(
        GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight(600),
        )
      ), // a verificar estilo!!
    );
  }
}
