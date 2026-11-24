import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_strings.dart';
import '../providers/role_provider.dart';
import '../services/auth_logic/auth_service.dart';

/// Cierra la sesión de quien fue dado de baja, esté en la pantalla que esté, y le
/// avisa por qué. Va envolviendo toda la app.
///
/// La baja de un usuario (`activo: false`) no borra nada, porque el Historial
/// guarda quién hizo cada movimiento. Lo que hace es que esa cuenta ya no pueda
/// usar la app: si estaba adentro la saca en el momento, y si intenta volver a
/// ingresar se le cierra de nuevo.
///
/// Esto lo hace cumplir la app; que lo haga cumplir también la base es parte de
/// las reglas de Firestore por rol (ver el README).
class GuardiaDeCuenta extends ConsumerWidget {
  const GuardiaDeCuenta({required this.child, this.cerrarSesion, super.key});

  final Widget child;

  /// Cómo se cierra la sesión. Se reemplaza en las pruebas (sin Firebase).
  final Future<void> Function()? cerrarSesion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<bool>>(cuentaActivaProvider, (anterior, actual) {
      // Solo cuando el dato ya llegó: mientras se vuelve a calcular puede quedar
      // el valor anterior, y no hay que actuar dos veces por la misma baja.
      if (actual is! AsyncData<bool> || actual.value != false) return;

      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text(AppStrings.cuentaDadaDeBaja)),
      );
      (cerrarSesion ?? AuthService().signOut)();
    });

    return child;
  }
}
