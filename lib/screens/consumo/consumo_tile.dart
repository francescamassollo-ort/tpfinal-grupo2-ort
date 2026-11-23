import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../widgets/outlined_list_card.dart';
import '../../widgets/quantity_stepper.dart';

/// Una fila de Registro de consumo: nombre del insumo, cuánto hay disponible y
/// el selector de cuánto retirar. Los signos del selector solo responden
/// mientras la cantidad pueda subir o bajar: nunca menos de 1 ni más de lo
/// disponible.
class ConsumoTile extends StatelessWidget {
  const ConsumoTile({
    required this.nombre,
    required this.disponible,
    required this.unidad,
    required this.cantidad,
    required this.onCambiar,
    super.key,
  });

  final String nombre;

  /// Cuánto hay en stock.
  final int disponible;
  final String unidad;

  /// Cuánto se va a retirar.
  final int cantidad;

  /// Se llama con la cantidad nueva al tocar un signo.
  final ValueChanged<int> onCambiar;

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
                  nombre,
                  style: AppTextStyles.listItemTitle,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppStrings.consumoDisponible(disponible, unidad),
                  style: AppTextStyles.listItemSubtitle,
                ),
              ],
            ),
          ),
          QuantityStepper(
            value: cantidad,
            onDecrement: cantidad > 1 ? () => onCambiar(cantidad - 1) : null,
            onIncrement:
                cantidad < disponible ? () => onCambiar(cantidad + 1) : null,
          ),
        ],
      ),
    );
  }
}
