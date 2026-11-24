import 'package:flutter/material.dart';

import '../core/app_strings.dart';

/// El logo de ORT Argentina, con fondo transparente. Se usa a distintos tamaños:
/// chico arriba de cada pantalla (ver [PantallaConLogo]) y grande en la
/// bienvenida y el ingreso.
class LogoOrt extends StatelessWidget {
  const LogoOrt({this.alto, this.ancho, super.key});

  /// Si se da solo uno de los dos, el otro se calcula manteniendo la proporción.
  final double? alto;
  final double? ancho;

  /// Ruta del archivo. El logo original es más chico que lo que se muestra en
  /// la bienvenida: si se consigue una versión más grande, se reemplaza este
  /// archivo con el mismo nombre y no hay que tocar nada más.
  static const String archivo = 'assets/images/logo_ort.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      archivo,
      height: alto,
      width: ancho,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: AppStrings.logoOrt,
    );
  }
}

/// Pone el logo arriba al centro de la pantalla que envuelve, como pidió el
/// profesor. Se usa una sola vez, alrededor de toda la app, así el logo está en
/// todas las pantallas sin repetirlo en cada una.
///
/// No se muestra donde ya hay un logo grande (bienvenida e ingreso) ni en la
/// cámara a pantalla completa del escáner.
class PantallaConLogo extends StatelessWidget {
  const PantallaConLogo({required this.ruta, required this.child, super.key});

  /// La ruta que se está mostrando, por ejemplo `/inventario`.
  final String ruta;
  final Widget child;

  /// Las pantallas que no llevan el logo chico.
  static const Set<String> sinLogoChico = {'/welcome', '/login', '/scanner'};

  /// El alto del logo chico.
  static const double altoLogo = 40;

  @override
  Widget build(BuildContext context) {
    if (sinLogoChico.contains(ruta)) return child;

    return Column(
      children: [
        // El logo respeta la barra de estado del celular.
        Container(
          width: double.infinity,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            bottom: false,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: LogoOrt(alto: altoLogo),
            ),
          ),
        ),
        // Las pantallas de abajo ya no dejan lugar para la barra de estado:
        // el logo se lo comió.
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}
