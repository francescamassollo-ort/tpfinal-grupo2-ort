import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../models/alerta.dart';
import '../../widgets/outlined_list_card.dart';

/// Una fila de Alertas: círculo con signo de exclamación del color de la
/// severidad, nombre del insumo y el motivo de la alerta debajo. Si se pasa
/// [onTap], la fila se puede tocar (por ejemplo para abrir el insumo).
class AlertaTile extends StatelessWidget {
  const AlertaTile({required this.alerta, this.onTap, super.key});

  final Alerta alerta;
  final VoidCallback? onTap;

  // Tamaño del círculo y espacio hasta el texto, según Figma.
  static const double _circleSize = 37;
  static const double _iconGap = 16;

  @override
  Widget build(BuildContext context) {
    final critica = alerta.severidad == SeveridadAlerta.critica;

    return OutlinedListCard(
      onTap: onTap,
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
                  descripcion(alerta),
                  style: AppTextStyles.listItemSubtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// El motivo de la alerta, tal como se muestra debajo del nombre.
  static String descripcion(Alerta alerta) {
    final fecha = alerta.fecha;
    final tp = alerta.trabajoPractico;
    return switch (alerta.tipo) {
      TipoAlerta.sinStock => AppStrings.alertaSinStock,
      TipoAlerta.stockBajo => AppStrings.alertaStockBajo,
      TipoAlerta.vencimientoCercano => AppStrings.alertaVencimientoCercano,
      TipoAlerta.vencido => AppStrings.alertaVencido,
      TipoAlerta.agotamientoProximo => fecha == null
          ? AppStrings.alertaAgotamientoProximo
          : AppStrings.alertaAgotamientoConFecha(_diaYMes(fecha)),
      TipoAlerta.tpSinCobertura => tp == null || fecha == null
          ? AppStrings.alertaTpSinCobertura
          : AppStrings.alertaTpSinCoberturaConNombre(tp, _diaYMes(fecha)),
    };
  }

  // "12/12": día y mes con dos dígitos, sin año (son fechas de los próximos
  // meses).
  static String _diaYMes(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}';
}
