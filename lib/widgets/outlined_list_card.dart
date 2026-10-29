import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Tarjeta con contorno suave para las filas de los listados de Figma
/// (movimientos del historial, ítems de compras, etc.).
class OutlinedListCard extends StatelessWidget {
  const OutlinedListCard({
    required this.child,
    this.color = AppColors.cardBackground,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    super.key,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: padding,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineColor, width: 2),
      ),
      child: child,
    );
  }
}
