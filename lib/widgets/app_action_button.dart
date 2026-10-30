import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';

enum AppActionButtonVariant { primary, secondary }

/// Botón de acción del diseño de Figma. El primario es azul y el secundario
/// es blanco con contorno. Si [onPressed] es null el botón no hace nada, que
/// es lo que se usa mientras la acción real no está implementada.
class AppActionButton extends StatelessWidget {
  const AppActionButton({
    required this.label,
    required this.onPressed,
    this.variant = AppActionButtonVariant.primary,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppActionButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == AppActionButtonVariant.primary;
    final radius = BorderRadius.circular(10);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primary : AppColors.cardBackground,
        borderRadius: radius,
        border: isPrimary ? null : Border.all(color: AppColors.outlineColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: isPrimary ? 1 : 0.2),
            offset: const Offset(0, 10),
            blurRadius: isPrimary ? 20 : 19,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.button(
                isPrimary ? Colors.white : AppColors.titleColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
