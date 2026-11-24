import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/insumo.dart';

// Tarjeta de un insumo en una lista: punto de color, nombre, ubicación,
// stock y (si corresponde) la etiqueta "Stock bajo" o "Por vencer".
// Es un StatelessWidget común: recibe el insumo y lo dibuja, nada más.
class InsumoCard extends StatelessWidget {
  const InsumoCard({required this.insumo, this.onTap, super.key});

  final Insumo insumo;
  // Qué hacer al tocar la tarjeta. Lo decide quien la usa (por ej.
  // Inventario abre el Detalle), así la tarjeta sirve en otras pantallas.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Elegimos color y etiqueta. El orden importa: si tiene stock bajo
    // y además está por vencer, gana el rojo porque es más urgente.
    Color color = AppColors.stockOk;
    String? etiqueta;
    final agotado = insumo.stock <= 0;
    if (agotado) {
      color = AppColors.stockAgotado;
      etiqueta = 'Sin stock';
    } else if (insumo.stockBajo) {
      color = AppColors.stockDanger;
      etiqueta = 'Stock bajo';
    } else if (insumo.porVencer) {
      color = AppColors.stockWarning;
      etiqueta = 'Por vencer';
    }

    // Un insumo agotado se ve apagado: tarjeta gris y textos atenuados.
    const apagado = TextStyle(color: AppColors.stockAgotado);

    return Card(
      color: agotado ? const Color(0xFFF1F2F4) : null,
      margin: const EdgeInsets.only(bottom: 8),
      // Recorta el efecto de "toque" para que respete las esquinas redondeadas.
      clipBehavior: Clip.antiAlias,
      // InkWell: hace que la tarjeta se pueda tocar y muestra el efecto.
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Punto de color.
              CircleAvatar(radius: 5, backgroundColor: color),
              const SizedBox(width: 12),
              // Nombre y ubicación. Expanded ocupa todo el ancho que sobra,
              // así el stock queda pegado a la derecha.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insumo.nombre,
                      style: agotado
                          ? apagado.copyWith(fontWeight: FontWeight.bold)
                          : const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(insumo.ubicacion, style: agotado ? apagado : null),
                  ],
                ),
              ),
              // Stock y, debajo, la etiqueta si hay una.
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${insumo.stock} u.',
                    style: agotado
                        ? apagado.copyWith(fontWeight: FontWeight.bold)
                        : const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (etiqueta != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.error, size: 12, color: color),
                        const SizedBox(width: 4),
                        Text(
                          etiqueta,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: agotado ? AppColors.stockAgotado : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
