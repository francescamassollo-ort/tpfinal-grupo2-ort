import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../models/alerta.dart';
import '../../widgets/outlined_list_card.dart';

/// Una fila de Alertas: círculo con signo de exclamación del color de la
/// severidad, nombre del insumo y el motivo de la alerta debajo. Si se pasa
/// [onTap], la fila se puede tocar (por ejemplo para abrir el insumo).
///
/// Si se pasa [onToggleVista], suma a la derecha un botón para marcar la alerta
/// como vista o volver a marcarla como no vista. Una alerta [vista] se ve
/// atenuada, pero sigue en la lista.
class AlertaTile extends StatelessWidget {
  const AlertaTile({
    required this.alerta,
    this.onTap,
    this.vista = false,
    this.onToggleVista,
    super.key,
  });

  final Alerta alerta;
  final VoidCallback? onTap;

  /// Si la persona ya marcó esta alerta como vista.
  final bool vista;

  /// Se llama al tocar el botón de vista. Si es null, no hay botón.
  final VoidCallback? onToggleVista;

  // Cuánto se atenúa una alerta ya vista. Se sigue leyendo bien: solo deja de
  // llamar la atención.
  static const double _opacidadVista = 0.5;

  // Tamaño del círculo y espacio hasta el texto, según Figma.
  static const double _circleSize = 37;
  static const double _iconGap = 16;

  @override
  Widget build(BuildContext context) {
    final critica = alerta.severidad == SeveridadAlerta.critica;

    return OutlinedListCard(
      onTap: onTap,
      padding: EdgeInsets.fromLTRB(17, 12, onToggleVista == null ? 20 : 6, 12),
      child: Row(
        children: [
          Expanded(
            // Se atenúa la alerta, no el botón: el botón tiene que seguir
            // viéndose igual para poder deshacer la marca.
            child: Opacity(
              opacity: vista ? _opacidadVista : 1,
              child: _contenido(critica),
            ),
          ),
          if (onToggleVista != null)
            IconButton(
              onPressed: onToggleVista,
              tooltip: vista
                  ? AppStrings.alertaMarcarNoVista
                  : AppStrings.alertaMarcarVista,
              icon: Icon(
                vista ? Icons.visibility_off_outlined : Icons.check_circle_outline,
                size: 24,
                color: AppColors.titleColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _contenido(bool critica) {
    return Row(
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
