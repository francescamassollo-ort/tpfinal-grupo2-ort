import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_colors.dart';
import '../core/app_strings.dart';
import '../core/app_text_styles.dart';
import '../core/formatters.dart';
import '../models/trabajo_practico.dart';
import '../providers/trabajopractico_provider.dart';
import 'indicador_disponibilidad_tp.dart';

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
                          formatearFecha(tp.fecha),
                          style: AppTextStyles.itemDetail,
                        ),
                        IndicadorDisponibilidadTp(
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