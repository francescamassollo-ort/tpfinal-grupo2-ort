import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_strings.dart';
import '../core/app_text_styles.dart';

/// Selector de cantidad del diseño de Figma: signo menos, cantidad y signo
/// más, sin círculos ni fondos. Los callbacks son opcionales: si es null, el
/// signo se ve igual pero no responde al toque.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    required this.value,
    this.onDecrement,
    this.onIncrement,
    super.key,
  });

  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  // El icono de 24 dibuja el signo de 14 de ancho que pide el diseño. La zona
  // táctil es más grande que lo que se ve.
  static const double _iconSize = 24;
  static const double _touchWidth = 40;
  static const double _touchHeight = 48;
  static const double _valueMinWidth = 32;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperSign(
          icon: Icons.remove,
          tooltip: AppStrings.disminuirCantidad,
          onPressed: onDecrement,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: _valueMinWidth),
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppTextStyles.amount,
          ),
        ),
        _StepperSign(
          icon: Icons.add,
          tooltip: AppStrings.aumentarCantidad,
          onPressed: onIncrement,
        ),
      ],
    );
  }
}

class _StepperSign extends StatelessWidget {
  const _StepperSign({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: QuantityStepper._touchWidth,
        minHeight: QuantityStepper._touchHeight,
      ),
      icon: Icon(
        icon,
        size: QuantityStepper._iconSize,
        color: AppColors.bodyColor,
      ),
    );
  }
}
