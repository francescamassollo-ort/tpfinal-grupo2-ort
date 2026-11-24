import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_strings.dart';
import '../core/app_text_styles.dart';
import '../core/formatters.dart';
import '../models/insumo.dart';
import '../models/trabajo_practico.dart';

// Proporción de cada columna. Header y filas comparten estos valores para
// que "Nombre" y "Ubicación" queden alineados con su contenido.
const int _flexNombre = 5;
const int _flexUbicacion = 6;

// Franja azul con los títulos de columna del detalle.
class TpInsumoEncabezado extends StatelessWidget {
  const TpInsumoEncabezado({super.key});

  @override
  Widget build(BuildContext context) {
    final estilo = AppTextStyles.listItemTitle.copyWith(color: Colors.white);
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: _flexNombre,
            child: Text(AppStrings.tpColumnaNombre, style: estilo),
          ),
          Expanded(
            flex: _flexUbicacion,
            child: Text(AppStrings.tpColumnaUbicacion, style: estilo),
          ),
        ],
      ),
    );
  }
}

// Una fila de la tabla: nombre y ubicación del insumo, y debajo cuánto pide
// el TP contra el stock disponible (verde si alcanza, rojo si falta).
class TpInsumoFila extends StatelessWidget {
  const TpInsumoFila({
    super.key,
    required this.requerido,
    required this.insumo,
    required this.falta,
  });

  final InsumoRequerido requerido;

  /// null si el insumo ya no existe en el inventario.
  final Insumo? insumo;

  /// Resultado de TpService.verificarDisponibilidad para este insumo.
  final bool falta;

  @override
  Widget build(BuildContext context) {
    final color = falta ? AppColors.stockDanger : AppColors.stockOk;
    final cantidad = formatearCantidad(requerido.cantidad);
    final pedido =
        requerido.unidad.isEmpty ? cantidad : '$cantidad ${requerido.unidad}';
    final estiloTexto =
        AppTextStyles.itemName.copyWith(fontWeight: FontWeight.w400);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.outlineColor)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: _flexNombre,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insumo?.nombre ?? AppStrings.tpInsumoNoEncontrado,
                    style: estiloTexto,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.circle, size: 10, color: color),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          AppStrings.tpRequeridoStock(
                            pedido,
                            insumo?.stock ?? 0,
                          ),
                          style:
                              AppTextStyles.itemDetail.copyWith(color: color),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: _flexUbicacion,
              // Sirve de lista de ubicaciones para preparar el TP. Si el insumo
              // ya no existe no se inventa una: la columna queda vacía.
              child: insumo == null
                  ? const SizedBox.shrink()
                  : Text(insumo!.ubicacion, style: estiloTexto),
            ),
          ],
        ),
      ),
    );
  }
}