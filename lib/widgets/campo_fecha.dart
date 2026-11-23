import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/app_text_styles.dart';
import '../core/formatters.dart';

// Campo de solo lectura que muestra una fecha y avisa al tocarlo para que
// la pantalla abra el selector. No sabe nada del DatePicker ni del estado.
class CampoFecha extends StatelessWidget {
  const CampoFecha({super.key, required this.fecha, required this.onTap});

  final DateTime fecha;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: AppStrings.tpFechaLabel,
          suffixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(formatearFecha(fecha), style: AppTextStyles.itemName),
      ),
    );
  }
}