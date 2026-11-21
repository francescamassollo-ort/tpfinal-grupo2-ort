import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_colors.dart';
import '../core/app_strings.dart';
import '../core/app_text_styles.dart';
import '../models/trabajo_practico.dart';
import '../providers/trabajopractico_provider.dart';
import '../services/trabajopractico_service.dart';

// Tarjeta de un TP en la lista. ConsumerWidget porque cada tarjeta observa
// SU propia disponibilidad: si cambia el stock, solo se redibujan las
// tarjetas afectadas y no toda la lista.
class TpCard extends ConsumerWidget {
  const TpCard({
    super.key,
    required this.tp,
    required this.onTap,
    this.onEditar,
    this.modoSeleccion = false,
    this.seleccionado = false,
  });

  final TrabajoPractico tp;

  /// Qué pasa al tocar la tarjeta (abrir detalle o marcar/desmarcar).
  final VoidCallback onTap;

  /// Si es null no se muestra el lápiz (roles sin permiso de edición).
  final VoidCallback? onEditar;

  /// En modo selección el lápiz se reemplaza por un checkbox.
  final bool modoSeleccion;
  final bool seleccionado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La regla "alcanza / no alcanza" vive en TpService; acá solo se muestra.
    final disponibilidad = ref.watch(disponibilidadTpProvider(tp));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: seleccionado ? AppColors.primary : AppColors.outlineColor,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tp.nombre, style: AppTextStyles.listItemTitle),
                    if (tp.docente.isNotEmpty)
                      Text(
                        AppStrings.tpDocente(tp.docente),
                        style: AppTextStyles.listItemSubtitle,
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _formatearFecha(tp.fecha),
                          style: AppTextStyles.itemDetail,
                        ),
                        _IndicadorDisponibilidad(
                          disponibilidad: disponibilidad,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (modoSeleccion)
                Checkbox(value: seleccionado, onChanged: (_) => onTap())
              else if (onEditar != null)
                IconButton(
                  icon: const Icon(Icons.edit),
                  color: AppColors.titleColor,
                  tooltip: AppStrings.tpEditar,
                  onPressed: onEditar,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Verde si el stock alcanza para todo el TP, rojo si falta algún insumo.
// El color siempre va acompañado de texto (no depende solo del color).
class _IndicadorDisponibilidad extends StatelessWidget {
  const _IndicadorDisponibilidad({required this.disponibilidad});

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

// dd/MM/yyyy sin sumar la dependencia intl solo para esto.
String _formatearFecha(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}