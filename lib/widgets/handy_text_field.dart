import 'package:flutter/material.dart';
import '../core/app_colors.dart';


class HandyTextField extends StatelessWidget{
  final String textForHint;

  const HandyTextField({super.key, required this.textForHint});

  @override
  Widget build(BuildContext context){ 
    return TextField(
      decoration: InputDecoration( // move la decoracion para usar textField normalmente
        hintText: textForHint,
        hintStyle: TextStyle(
        //background: ,
        ),
        fillColor: Color.fromARGB(255, 241, 244, 245),
        filled: true,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(
            width: 2,
            color: AppColors.primary,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            //width: 0,
            color:Color.fromARGB(0, 0, 0, 0),
          ),
        ),
      ),
    );
  }
}
