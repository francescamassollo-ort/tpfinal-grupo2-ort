import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_colors.dart';
import '../core/app_strings.dart';
import '../core/app_text_styles.dart';
import '../models/usuario.dart';
import '../providers/role_provider.dart';
import 'app_decorative_background.dart';
import 'app_screen_header.dart';

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

    // Mismo marco que el resto de las pantallas: fondo, encabezado con la flecha
    // de volver y el mensaje. Se usa Material y no Scaffold porque a veces va
    // dentro del Scaffold del shell (barra inferior y menú) y a veces solo.
    return Material(
      color: AppColors.screenBackground,
      child: AppDecorativeBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppScreenHeader(
                title: '',
                onBack: () =>
                    context.canPop() ? context.pop() : context.go('/inventario'),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      AppStrings.sinPermiso,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.itemDetail,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
