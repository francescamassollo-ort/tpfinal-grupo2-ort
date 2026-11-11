import 'package:flutter/material.dart';

import '../../core/app_text_styles.dart';
import '../../widgets/outlined_list_card.dart';
import '../../widgets/quantity_stepper.dart';
import 'item_compra.dart';

/// Una fila de la lista de compras: nombre, stock actual y el selector de
/// cantidad a pedir.
class CompraTile extends StatelessWidget {
  const CompraTile({
    required this.item,
    this.onDecrement,
    this.onIncrement,
    super.key,
  });

  final ItemCompra item;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    return OutlinedListCard(
      // El selector ya trae su propia zona táctil, por eso el margen derecho
      // es chico: el signo más queda a 19 del borde, como en Figma.
      padding: const EdgeInsets.fromLTRB(20, 12, 6, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.nombre,
                  style: AppTextStyles.listItemTitle,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(item.stockTexto, style: AppTextStyles.listItemSubtitle),
              ],
            ),
          ),
          QuantityStepper(
            value: item.cantidadSolicitada,
            onDecrement: onDecrement,
            onIncrement: onIncrement,
          ),
        ],
      ),
    );
  }
}
