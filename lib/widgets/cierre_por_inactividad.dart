import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_strings.dart';
import '../providers/role_provider.dart';
import '../services/auth_logic/auth_service.dart';

/// Cierra la sesión si la persona deja la app sin tocar nada durante un rato, y
/// se lo avisa. Va envolviendo toda la app.
///
/// Es una de las medidas del plan de riesgos del SQAP contra el uso indebido de
/// una cuenta: un celular que queda desbloqueado sobre la mesada del laboratorio
/// no tiene que dejar la sesión abierta para siempre.
///
/// Cuenta como actividad cualquier toque o desplazamiento en la pantalla. Solo
/// corre mientras hay una sesión iniciada.
class CierrePorInactividad extends ConsumerStatefulWidget {
  const CierrePorInactividad({
    required this.child,
    this.duracion = tiempoSinActividad,
    this.cerrarSesion,
    super.key,
  });

  final Widget child;

  /// Cuánto tiempo sin actividad hasta cerrar la sesión.
  final Duration duracion;

  /// Cómo se cierra la sesión. Se reemplaza en las pruebas (sin Firebase).
  final Future<void> Function()? cerrarSesion;

  /// 30 minutos: alcanza para una pausa corta sin perder la sesión, y no deja
  /// una cuenta abierta indefinidamente.
  static const Duration tiempoSinActividad = Duration(minutes: 30);

  @override
  ConsumerState<CierrePorInactividad> createState() => _CierrePorInactividadState();
}

class _CierrePorInactividadState extends ConsumerState<CierrePorInactividad> {
  Timer? _reloj;
  bool _conSesion = false;

  @override
  void initState() {
    super.initState();
    // Arranca o frena el reloj según haya o no sesión, también al abrir la app.
    ref.listenManual<AsyncValue<Object?>>(sesionProvider, (anterior, actual) {
      _conSesion = actual.value != null;
      _reiniciar();
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  void _reiniciar() {
    _reloj?.cancel();
    _reloj = _conSesion ? Timer(widget.duracion, _vencio) : null;
  }

  void _vencio() {
    if (!mounted || !_conSesion) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text(AppStrings.sesionCerradaPorInactividad)),
    );
    (widget.cerrarSesion ?? AuthService().signOut)();
  }

  @override
  Widget build(BuildContext context) {
    // translucent: mira los toques sin impedir que lleguen a la pantalla.
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _reiniciar(),
      onPointerMove: (_) => _reiniciar(),
      child: widget.child,
    );
  }
}
