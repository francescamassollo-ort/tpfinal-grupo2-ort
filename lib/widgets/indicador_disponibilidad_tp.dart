import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_colors.dart';
import '../core/app_strings.dart';
import '../core/app_text_styles.dart';
import '../services/trabajopractico_service.dart';

// Verde si el stock alcanza para todo el TP, rojo si falta algún insumo.
// El color siempre va acompañado de texto (no depende solo del color).
// Lo usan la tarjeta de la lista y el detalle del TP.
class IndicadorDisponibilidadTp extends StatelessWidget {
  const IndicadorDisponibilidadTp({super.key, required this.disponibilidad});

  final AsyncValue<DisponibilidadTP> disponibilidad;

  @override
  Widget build(BuildContext context) {
    return disponibilidad.when(
      data: (d) {
        final color = d.completo ? AppColors.stockOk : AppColors.stockDanger;
        final texto = d.completo
            ? AppStrings.tpInsumosCompletos
            : AppStrings.tpInsumosFaltantes(d.faltantes.length);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 10, color: color),
            const SizedBox(width: 6),
            Text(texto, style: AppTextStyles.itemDetail.copyWith(color: color)),
          ],
        );
      },
      loading: () => const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stack) => Text(
        AppStrings.tpErrorDisponibilidad,
        style: AppTextStyles.itemDetail,
      ),
    );
  }
}