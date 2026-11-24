import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    // Ruta vacía: el router todavía no resolvió a dónde va (pasa en el primer
    // cuadro al abrir la app, antes de la redirección a Bienvenida o a
    // Inventario). Mejor no mostrar el logo un instante que mostrarlo de más.
    if (ruta.isEmpty || sinLogoChico.contains(ruta)) return child;

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

/// Sigue la ruta del [router] y le pasa a [PantallaConLogo] la que se está
/// mostrando, para saber cuándo poner el logo chico y cuándo no.
///
/// El router avisa que cambió la ruta **en medio de su propia construcción** (la
/// redirección del arranque es inmediata), y en ese momento no se puede pedir
/// que otro widget se vuelva a dibujar. Por eso el aviso se atiende un instante
/// después, cuando el cuadro ya terminó.
class LogoSegunRuta extends StatefulWidget {
  const LogoSegunRuta({required this.router, required this.child, super.key});

  final GoRouter router;
  final Widget child;

  @override
  State<LogoSegunRuta> createState() => _LogoSegunRutaState();
}

class _LogoSegunRutaState extends State<LogoSegunRuta> {
  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_cambioLaRuta);
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_cambioLaRuta);
    super.dispose();
  }

  void _cambioLaRuta() {
    Future.microtask(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final configuracion = widget.router.routerDelegate.currentConfiguration;
    return PantallaConLogo(
      ruta: configuracion.isEmpty ? '' : configuracion.uri.path,
      child: widget.child,
    );
  }
}
