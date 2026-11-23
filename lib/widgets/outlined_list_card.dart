import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Tarjeta con contorno suave para las filas de los listados de Figma
/// (movimientos del historial, ítems de compras, etc.).
///
/// Si se le pasa [onTap], toda la tarjeta se puede tocar y muestra el efecto
/// de toque; sin [onTap] se ve y se comporta como siempre.
class OutlinedListCard extends StatelessWidget {
  const OutlinedListCard({
    required this.child,
    this.color = AppColors.cardBackground,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.onTap,
    super.key,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  static const double _radio = 10;
  static const double _alturaMinima = 72;
  static const double _anchoDelContorno = 2;

  @override
  Widget build(BuildContext context) {
    final onTap = this.onTap;
    if (onTap == null) {
      return Container(
        constraints: const BoxConstraints(minHeight: _alturaMinima),
        padding: padding,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(_radio),
          border: Border.all(
            color: AppColors.outlineColor,
            width: _anchoDelContorno,
          ),
        ),
        child: child,
      );
    }

    // Con onTap, el fondo y el contorno los dibuja el Material: así el efecto
    // de toque se ve por encima del fondo y no queda tapado por él. El
    // contorno de la versión sin toque ocupa lugar dentro de la tarjeta; acá
    // se suma ese mismo espacio al padding para que el contenido quede igual.
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radio),
        side: const BorderSide(
          color: AppColors.outlineColor,
          width: _anchoDelContorno,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: _alturaMinima),
          padding: padding.add(const EdgeInsets.all(_anchoDelContorno)),
          alignment: Alignment.centerLeft,
          child: child,
        ),
      ),
    );
  }
}
