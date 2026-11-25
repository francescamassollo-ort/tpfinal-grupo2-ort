import 'package:flutter/material.dart';

import '../core/breakpoints.dart';

/// Limita el ancho de su [child] y lo centra arriba. En un celular no cambia
/// nada (el contenido sigue ocupando todo el ancho); en una ventana de
/// escritorio evita que las listas y los formularios se estiren de borde a
/// borde.
///
/// Se usa alrededor del contenido de la pantalla (la lista, el formulario) y no
/// del fondo decorativo, que sigue ocupando todo el ancho.
class ContenidoCentrado extends StatelessWidget {
  const ContenidoCentrado({
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    // Ancho fijo (el menor entre el disponible y el máximo) y no un simple
    // ConstrainedBox: así el contenido recibe el mismo ancho exacto que tenía
    // antes en un celular, y no se encoge a lo que miden sus hijos.
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho =
            constraints.maxWidth < maxWidth ? constraints.maxWidth : maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: ancho, child: child),
        );
      },
    );
  }
}