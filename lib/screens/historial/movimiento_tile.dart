import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../widgets/outlined_list_card.dart';
import 'movimiento_item.dart';

/// Una fila del historial: icono de entrada o salida, nombre, usuario con
/// fecha y la variación a la derecha.
class MovimientoTile extends StatelessWidget {
  const MovimientoTile({required this.item, super.key});

  final MovimientoItem item;

  // Tamaño del icono y espacio hasta el texto, según Figma.
  static const double _iconSize = 38;
  static const double _iconGap = 22;

  @override
  Widget build(BuildContext context) {
    return OutlinedListCard(
      color: item.destacado ? AppColors.subtleSurface : AppColors.cardBackground,
      padding: const EdgeInsets.fromLTRB(10, 12, 20, 12),
      child: Row(
        children: [
          Icon(
            item.esEntrada ? Icons.add_circle : Icons.remove_circle_outline,
            size: _iconSize,
            color: AppColors.movementBlue,
            semanticLabel: item.esEntrada
                ? AppStrings.movimientoEntrada
                : AppStrings.movimientoSalida,
          ),
          const SizedBox(width: _iconGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.elementoNombre,
                  style: AppTextStyles.itemName,
                  overflow: TextOverflow.ellipsis,
                ),
                // El espacio entre usuario y fecha es de layout, no de texto.
                Wrap(
                  spacing: 12,
                  children: [
                    Text(item.usuarioNombre, style: AppTextStyles.itemDetail),
                    Text(item.fechaEtiqueta, style: AppTextStyles.itemDetail),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(item.deltaTexto, style: AppTextStyles.amount),
        ],
      ),
    );
  }
}
