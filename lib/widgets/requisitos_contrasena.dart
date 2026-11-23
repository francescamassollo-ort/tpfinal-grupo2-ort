import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/auth_logic/validaciones_auth.dart';

/// La lista de lo que tiene que cumplir una contraseña nueva, con una casilla
/// que se tilda a medida que se escribe. Así la persona ve qué le falta antes de
/// tocar "Registrarse", en vez de enterarse con un cartel.
class RequisitosContrasena extends StatelessWidget {
  const RequisitosContrasena({required this.contrasena, super.key});

  final String contrasena;

  @override
  Widget build(BuildContext context) {
    // Todo el ancho disponible, para que los textos largos hagan salto de línea
    // en vez de salirse de la pantalla (letra grande, celulares angostos).
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final requisito in RequisitoContrasena.values)
            _Requisito(
              requisito: requisito,
              cumplido: ValidacionesAuth.cumple(requisito, contrasena),
            ),
        ],
      ),
    );
  }
}

class _Requisito extends StatelessWidget {
  const _Requisito({required this.requisito, required this.cumplido});

  final RequisitoContrasena requisito;
  final bool cumplido;

  @override
  Widget build(BuildContext context) {
    final color = cumplido ? AppColors.stockOk : AppColors.bodyColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      // El estado va en el texto además del ícono, para lectores de pantalla.
      child: Semantics(
        label: '${requisito.etiqueta}: ${cumplido ? 'cumplido' : 'falta'}',
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              cumplido ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                requisito.etiqueta,
                style: TextStyle(fontSize: 13, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
