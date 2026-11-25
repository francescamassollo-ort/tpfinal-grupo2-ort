import 'package:flutter/material.dart';

import '../core/breakpoints.dart';

/// Para pantallas de formulario sueltas (ingreso, registro): centra el
/// contenido en la pantalla, a lo ancho y a lo alto, y no lo deja estirarse más
/// de [maxWidth] cuando la ventana es ancha.
///
/// Mantiene el desplazamiento: si el contenido no entra (teclado abierto,
/// ventana baja), en vez de desbordar se puede deslizar.
///
/// Reemplaza al `SingleChildScrollView` que usaban esas pantallas. Como
/// [ContenidoCentrado] pero con centrado vertical; las pantallas de lista
/// siguen usando [ContenidoCentrado] arriba.
class FormularioCentrado extends StatelessWidget {
  const FormularioCentrado({
    required this.child,
    this.maxWidth = Breakpoints.maxFormWidth,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ancho fijo (el menor entre el disponible y el máximo): en un celular
        // el contenido ocupa todo el ancho, igual que antes.
        final ancho =
            constraints.maxWidth < maxWidth ? constraints.maxWidth : maxWidth;

        return SingleChildScrollView(
          child: ConstrainedBox(
            // Alto mínimo = el de la pantalla: así el Center tiene de dónde
            // centrar. Si el contenido es más alto, la caja crece y se desliza.
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: SizedBox(width: ancho, child: child)),
          ),
        );
      },
    );
  }
}