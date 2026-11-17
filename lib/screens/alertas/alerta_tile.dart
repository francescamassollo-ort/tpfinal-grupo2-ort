import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../models/alerta.dart';
import '../../widgets/outlined_list_card.dart';

/// Una fila de Alertas: círculo con signo de exclamación del color de la
/// severidad, nombre del insumo y el motivo de la alerta debajo.
class AlertaTile extends StatelessWidget {
  const AlertaTile({required this.alerta, super.key});

  final Alerta alerta;

  // Tamaño del círculo y espacio hasta el texto, según Figma.
  static const double _circleSize = 37;
  static const double _iconGap = 16;

  @override
  Widget build(BuildContext context) {
    final critica = alerta.severidad == SeveridadAlerta.critica;

    return OutlinedListCard(
      padding: const EdgeInsets.fromLTRB(17, 12, 20, 12),
      child: Row(
        children: [
          Container(
            width: _circleSize,
            height: _circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: critica ? AppColors.stockDanger : AppColors.stockWarning,
            ),
            child: Icon(
              Icons.priority_high_rounded,
              size: 22,
              color: Colors.white,
              semanticLabel: critica
                  ? AppStrings.alertaCritica
                  : AppStrings.alertaAdvertencia,
            ),
          ),
          const SizedBox(width: _iconGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  alerta.productoNombre,
                  style: AppTextStyles.itemName,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _descripcion(alerta.tipo),
                  style: AppTextStyles.listItemSubtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _descripcion(TipoAlerta tipo) {
    return switch (tipo) {
      TipoAlerta.sinStock => AppStrings.alertaSinStock,
      TipoAlerta.stockBajo => AppStrings.alertaStockBajo,
      TipoAlerta.vencimientoCercano => AppStrings.alertaVencimientoCercano,
      TipoAlerta.vencido => AppStrings.alertaVencido,
    };
  }
}
