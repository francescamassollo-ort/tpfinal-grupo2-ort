import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Arma el ThemeData de la app a partir de los colores de [AppColors].
/// Se usa una sola vez, en MaterialApp(theme: appTheme).
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
  ),

  // Tarjetas: fondo blanco, borde suave, esquinas redondeadas (radio 10).
  cardTheme: CardThemeData(
    color: AppColors.cardBackground,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: AppColors.cardBorder),
    ),
  ),

  // Inputs (buscador, formularios): fondo celeste clarito, sin borde marcado.
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.inputBackground,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  ),

  // Botones principales: fondo azul oscuro, esquinas redondeadas,
  // altura mínima 44 como pide el diseño.
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
  ),
);
