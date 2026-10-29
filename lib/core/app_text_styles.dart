import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Estilos de texto del diseño de Figma. Todos usan Poppins.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _poppins(double size, FontWeight weight, Color color) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: 0,
    );
  }

  /// Título de pantalla, por ejemplo "Historial de movimientos".
  static TextStyle get screenTitle =>
      _poppins(20, FontWeight.w600, AppColors.titleColor);

  /// Texto de los botones de acción. El color cambia según la variante.
  static TextStyle button(Color color) =>
      _poppins(14, FontWeight.w600, color);
}
