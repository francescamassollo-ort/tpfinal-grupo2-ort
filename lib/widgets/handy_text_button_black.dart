import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class HandyTextButtonBlack extends StatelessWidget {

  final String textPhrase;
  final String direction;

  const HandyTextButtonBlack({super.key, required this.textPhrase, required this.direction});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: (){
        (context).push(direction);
      }, 
      child: Text(
        textPhrase,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight(500),
          color: Color.fromARGB(255, 0, 0, 0),
          fontSize: 13,
        ),
      )
    );
  }
}

