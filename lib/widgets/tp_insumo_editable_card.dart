import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_strings.dart';
import '../core/app_text_styles.dart';
import '../core/formatters.dart';

// Tarjeta de un insumo dentro del formulario de TP: nombre, stock y un
// selector de cantidad (– 5 +). Solo presentación: recibe todo ya resuelto
// y avisa los cambios con callbacks.
class TpInsumoEditableCard extends StatelessWidget {
  const TpInsumoEditableCard({
    super.key,
    required this.nombre,
    required this.stock,
    required this.cantidad,
    required this.falta,
    required this.onDisminuir,
    required this.onAumentar,
  });

  final String nombre;
  final int stock;
  final double cantidad;

  /// true si el stock no alcanza para la cantidad pedida.
  final bool falta;

  final VoidCallback onDisminuir;
  final VoidCallback onAumentar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.outlineColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre, style: AppTextStyles.listItemTitle),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (falta) ...[
                        const Icon(
                          Icons.error,
                          size: 16,
                          color: AppColors.titleColor,
                          semanticLabel: AppStrings.tpStockInsuficiente,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        AppStrings.tpStockUnidades(stock),
                        style: AppTextStyles.listItemSubtitle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove),
              tooltip: AppStrings.disminuirCantidad,
              // Mínimo 1: para quitar el insumo se desliza la tarjeta.
              onPressed: cantidad > 1 ? onDisminuir : null,
            ),
            SizedBox(
              width: 28,
              child: Text(
                formatearCantidad(cantidad),
                textAlign: TextAlign.center,
                style: AppTextStyles.amount,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: AppStrings.aumentarCantidad,
              onPressed: onAumentar,
            ),
          ],
        ),
      ),
    );
  }
}