import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_strings.dart';
import '../core/app_text_styles.dart';

/// Encabezado de las pantallas del diseño: flecha de volver y título.
class AppScreenHeader extends StatelessWidget {
  const AppScreenHeader({
    required this.title,
    required this.onBack,
    super.key,
  });

  final String title;
  final VoidCallback onBack;

  // Separación entre la flecha y el título, según Figma.
  static const double _titleGap = 9;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: AppStrings.volver,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 24,
              color: AppColors.backIconColor,
            ),
          ),
          const SizedBox(width: _titleGap),
          Expanded(
            child: Text(title, style: AppTextStyles.screenTitle),
          ),
        ],
      ),
    );
  }
}
