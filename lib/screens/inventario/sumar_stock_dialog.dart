import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../models/insumo.dart';
import '../../widgets/quantity_stepper.dart';

/// Panel para elegir cuántas unidades sumarle al stock de un insumo que ya
/// existe (por ejemplo, cuando llega una compra y se escanea su código).
///
/// Al tocar "Sumar" se cierra y devuelve la cantidad (1 como mínimo). Si se
/// cierra tocando afuera o con "Cancelar" devuelve null y no se suma nada.
class SumarStockDialog extends StatefulWidget {
  const SumarStockDialog({required this.insumo, super.key});

  final Insumo insumo;

  /// Abre el panel y espera la cantidad elegida.
  static Future<int?> mostrar(BuildContext context, Insumo insumo) {
    return showDialog<int>(
      context: context,
      builder: (_) => SumarStockDialog(insumo: insumo),
    );
  }

  @override
  State<SumarStockDialog> createState() => _SumarStockDialogState();
}

class _SumarStockDialogState extends State<SumarStockDialog> {
  int _cantidad = 1;

  @override
  Widget build(BuildContext context) {
    final insumo = widget.insumo;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.sumarStockTitulo, style: AppTextStyles.listItemTitle),
            const SizedBox(height: 4),
            Text(
              '${insumo.nombre} · ${AppStrings.escanerStockActual(insumo.stock, insumo.unidad ?? AppStrings.escanerUnidadPorDefecto)}',
              style: AppTextStyles.listItemSubtitle,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.sumarStockCantidad,
                    style: AppTextStyles.listItemSubtitle,
                  ),
                ),
                QuantityStepper(
                  value: _cantidad,
                  // Se vuelve a mirar al tocar, no solo al dibujar: así dos
                  // toques seguidos nunca bajan de 1.
                  onDecrement: () => setState(() {
                    if (_cantidad > 1) _cantidad--;
                  }),
                  onIncrement: () => setState(() => _cantidad++),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(AppStrings.cancelar),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_cantidad),
                    child: const Text(AppStrings.sumarStockConfirmar),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
