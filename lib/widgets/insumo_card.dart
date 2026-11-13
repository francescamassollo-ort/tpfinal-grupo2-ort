import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/insumo.dart';

// Tarjeta de un insumo en una lista: punto de color, nombre, ubicación,
// stock y (si corresponde) la etiqueta "Stock bajo" o "Por vencer".
// Es un StatelessWidget común: recibe el insumo y lo dibuja, nada más.
class InsumoCard extends StatelessWidget {
  const InsumoCard({required this.insumo, super.key});

  final Insumo insumo;

  @override
  Widget build(BuildContext context) {
    // Elegimos color y etiqueta. El orden importa: si tiene stock bajo
    // y además está por vencer, gana el rojo porque es más urgente.
    Color color = AppColors.stockOk;
    String? etiqueta;
    if (insumo.stockBajo) {
      color = AppColors.stockDanger;
      etiqueta = 'Stock bajo';
    } else if (insumo.porVencer) {
      color = AppColors.stockWarning;
      etiqueta = 'Por vencer';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(insumo.ubicacion),
                ],
              ),
            ),
            // Stock y, debajo, la etiqueta si hay una.
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${insumo.stock} u.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (etiqueta != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.error, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        etiqueta,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
    );
  }
}
