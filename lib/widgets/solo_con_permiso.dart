import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_strings.dart';
import '../models/usuario.dart';
import '../providers/role_provider.dart';

/// Muestra [child] solo si el rol de la persona lo permite. Si no, en vez de la
/// pantalla dice que no tiene permiso.
///
/// Los botones que llevan a una pantalla ya se esconden según el rol; esto
/// cubre el resto, por ejemplo si la ruta se abre desde otro lugar o el rol
/// cambia mientras la pantalla está abierta.
class SoloConPermiso extends ConsumerWidget {
  const SoloConPermiso({
    required this.permitido,
    required this.child,
    super.key,
  });

  /// Dice si un rol puede ver la pantalla (ver `Permisos`).
  final bool Function(UserRole rol) permitido;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (permitido(ref.watch(roleProvider))) return child;

    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            AppStrings.sinPermiso,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
