import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';

/// Botón flotante de la lista de compras: círculo azul de 69 con un signo más
/// blanco. No usa el botón flotante por defecto porque ese es un cuadrado
/// redondeado y el diseño pide un círculo.
class ComprasFab extends StatelessWidget {
  const ComprasFab({this.onPressed, super.key});

  final VoidCallback? onPressed;

  static const double _size = 69;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppStrings.agregar,
      child: Material(
        color: AppColors.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const SizedBox(
            width: _size,
            height: _size,
            child: Icon(Icons.add, size: 32, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
