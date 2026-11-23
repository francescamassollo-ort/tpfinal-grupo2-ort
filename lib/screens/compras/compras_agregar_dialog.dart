import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../models/insumo.dart';
import '../../models/lista_compra.dart';
import '../../services/lista_compra_service.dart';
import '../../widgets/insumo_etiquetas.dart';
import '../../widgets/quantity_stepper.dart';

/// Lo que se eligió en el panel: qué insumo agregar y cuánto pedir.
typedef NuevoItemCompra = ({String productoId, int cantidad});

/// Panel para agregar a mano un insumo a la lista de compras. Mismo estilo que
/// los paneles de filtros (un Dialog con StatefulWidget común, sin Riverpod).
///
/// Lo elegido se guarda acá con setState y recién al tocar "Agregar" el panel
/// se cierra y devuelve un [NuevoItemCompra]. Si se cierra tocando afuera o con
/// "Cancelar" devuelve null y no se agrega nada.
class ComprasAgregarDialog extends StatefulWidget {
  const ComprasAgregarDialog({required this.insumos, super.key});

  /// Los insumos que se pueden agregar: la pantalla manda solo los que todavía
  /// no están en la lista.
  final List<Insumo> insumos;

  @override
  State<ComprasAgregarDialog> createState() => _ComprasAgregarDialogState();
}

class _ComprasAgregarDialogState extends State<ComprasAgregarDialog> {
  Insumo? _insumo;
  int _cantidad = ListaCompra.cantidadMinima;

  @override
  Widget build(BuildContext context) {
    final insumos = [...widget.insumos]
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    final etiquetas = etiquetasDeInsumos(insumos);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.comprasAgregarTitulo,
              style: AppTextStyles.listItemTitle,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _insumo?.id,
              // Los nombres de insumo pueden ser largos: que no desborden.
              isExpanded: true,
              decoration: InputDecoration(
                labelText: AppStrings.comprasCampoInsumo,
                helperText: _insumo == null
                    ? null
                    : AppStrings.comprasStockActual(_insumo!.stock),
              ),
              items: [
                for (final insumo in insumos)
                  DropdownMenuItem(
                    value: insumo.id,
                    child: Text(
                      etiquetas[insumo.id]!,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _elegirInsumo,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.comprasCampoCantidad,
                    style: AppTextStyles.listItemSubtitle,
                  ),
                ),
                QuantityStepper(
                  value: _cantidad,
                  // El control se vuelve a mirar al tocar, no solo al dibujar: así
                  // dos toques seguidos nunca bajan de la cantidad mínima.
                  onDecrement: () => setState(() {
                    if (_cantidad > ListaCompra.cantidadMinima) _cantidad--;
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
                    child: const Text(AppStrings.tpCancelar),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    // Sin un insumo elegido no hay nada que agregar.
                    onPressed: _insumo == null
                        ? null
                        : () => Navigator.of(context).pop((
                              productoId: _insumo!.id,
                              cantidad: _cantidad,
                            )),
                    child: const Text(AppStrings.agregar),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Al elegir un insumo, la cantidad arranca en lo que propone el sistema para
  // volver a un nivel cómodo de stock; después se puede cambiar.
  void _elegirInsumo(String? id) {
    final insumo = widget.insumos.where((i) => i.id == id).firstOrNull;
    setState(() {
      _insumo = insumo;
      if (insumo != null) {
        _cantidad = ListaCompraService.cantidadSugeridaPara(insumo);
      }
    });
  }
}
