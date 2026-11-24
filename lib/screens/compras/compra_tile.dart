import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../models/lista_compra.dart';
import '../../widgets/outlined_list_card.dart';
import '../../widgets/quantity_stepper.dart';
import 'item_compra.dart';

/// Una fila de la lista de compras: nombre, stock actual y el selector de
/// cantidad a pedir. Si se pasa [onCambiarEstado], suma un menú para marcar el
/// ítem como comprado o descartarlo.
class CompraTile extends StatelessWidget {
  const CompraTile({
    required this.item,
    this.onDecrement,
    this.onIncrement,
    this.onCambiarEstado,
    this.seleccionando = false,
    this.seleccionado = false,
    this.onSeleccion,
    super.key,
  });

  final ItemCompra item;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  /// Se llama con el estado elegido en el menú. Si es null, no hay menú.
  final ValueChanged<EstadoCompra>? onCambiarEstado;

  /// Modo "eliminar": la fila muestra una casilla en vez del menú y el selector
  /// de cantidad, y tocarla la marca o desmarca con [onSeleccion].
  final bool seleccionando;
  final bool seleccionado;
  final VoidCallback? onSeleccion;

  @override
  Widget build(BuildContext context) {
    return OutlinedListCard(
      onTap: seleccionando ? onSeleccion : null,
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
          if (seleccionando)
            Checkbox(
              value: seleccionado,
              onChanged: (_) => onSeleccion?.call(),
            )
          else ...[
          if (onCambiarEstado != null)
            PopupMenuButton<EstadoCompra>(
              tooltip: AppStrings.comprasCambiarEstado,
              icon: const Icon(
                Icons.more_vert,
                size: 22,
                color: AppColors.titleColor,
              ),
              onSelected: onCambiarEstado,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: EstadoCompra.comprado,
                  child: Text(AppStrings.comprasMarcarComprado),
                ),
                PopupMenuItem(
                  value: EstadoCompra.descartado,
                  child: Text(AppStrings.comprasDescartar),
                ),
              ],
            ),
          QuantityStepper(
            value: item.cantidadSolicitada,
            onDecrement: onDecrement,
            onIncrement: onIncrement,
          ),
          ],
        ],
      ),
    );
  }
}
