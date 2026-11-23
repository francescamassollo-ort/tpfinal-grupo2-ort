import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../models/usuario.dart';
import '../../providers/role_provider.dart';
import '../../providers/usuario_provider.dart';
import '../../providers/usuarios_provider.dart';
import '../../widgets/app_decorative_background.dart';
import '../../widgets/app_screen_header.dart';
import 'usuario_rol_dialog.dart';
import 'usuario_tile.dart';

/// Gestión de usuarios: lista de usuarios con su rol, cambio de rol y baja.
/// Solo para administradores. Va dentro del AppShell: conserva la barra
/// inferior pero, como Alertas, sin botón flotante (ver `_rutaBotonAgregar`).
///
/// El menú lateral ya oculta esta opción a los demás roles; la pantalla además
/// se protege sola por si se llega por la ruta directa.
class UsuariosScreen extends ConsumerWidget {
  const UsuariosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rol = ref.watch(roleProvider);

    return ColoredBox(
      color: AppColors.screenBackground,
      child: AppDecorativeBackground(
        // La barra inferior es la del shell, por eso el área segura es solo
        // la de arriba.
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppScreenHeader(
                title: AppStrings.usuariosTitulo,
                onBack: () => _volver(context),
              ),
              Expanded(
                child: rol == UserRole.administrador
                    ? const _ListaUsuarios()
                    : const _Mensaje(AppStrings.usuariosSinPermiso),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Si se llegó desde otra pantalla vuelve atrás; si no (por ejemplo desde el
  // menú lateral), vuelve a Inventario.
  void _volver(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/inventario');
    }
  }
}

class _ListaUsuarios extends ConsumerWidget {
  const _ListaUsuarios();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuarios = ref.watch(usuariosProvider);
    final miId = ref.watch(usuarioActualIdProvider);

    return usuarios.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const _Mensaje(AppStrings.usuariosError),
      data: (lista) => lista.isEmpty
          ? const _Mensaje(AppStrings.usuariosVacio)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 20),
              itemCount: lista.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final usuario = lista[index];
                return UsuarioTile(
                  usuario: usuario,
                  esPropio: usuario.id == miId,
                  onEditarRol: () => _cambiarRol(context, ref, usuario),
                  onEliminar: () => _eliminar(context, ref, usuario),
                );
              },
            ),
    );
  }

  // Abre el panel de rol y espera a que se cierre. Si se tocó "Guardar"
  // devuelve el rol nuevo; si se cerró de otra forma devuelve null y no cambia
  // nada.
  Future<void> _cambiarRol(
    BuildContext context,
    WidgetRef ref,
    Usuario usuario,
  ) async {
    final nuevoRol = await showDialog<UserRole>(
      context: context,
      builder: (_) => UsuarioRolDialog(usuario: usuario),
    );
    if (nuevoRol == null || !context.mounted) return;

    await _ejecutar(
      context,
      () => ref.read(usuariosAccionesProvider).cambiarRol(usuario, nuevoRol),
      exito: AppStrings.usuariosRolActualizado(usuario.nombre, nuevoRol),
      errorGenerico: AppStrings.usuariosErrorRol,
    );
  }

  Future<void> _eliminar(
    BuildContext context,
    WidgetRef ref,
    Usuario usuario,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.usuariosEliminarTitulo),
        content: Text(AppStrings.usuariosEliminarMensaje(usuario.nombre)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.usuariosEliminarConfirmar),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;

    await _ejecutar(
      context,
      () => ref.read(usuariosAccionesProvider).eliminar(usuario),
      exito: AppStrings.usuariosEliminado(usuario.nombre),
      errorGenerico: AppStrings.usuariosErrorEliminar,
    );
  }

  // Corre la acción y avisa el resultado. Si una regla de negocio la rechaza
  // se muestra el motivo; cualquier otro error (Firestore, sin conexión) usa el
  // mensaje genérico de la acción.
  Future<void> _ejecutar(
    BuildContext context,
    Future<void> Function() accion, {
    required String exito,
    required String errorGenerico,
  }) async {
    // Se toma antes del await: después la pantalla podría ya no estar.
    final avisos = ScaffoldMessenger.of(context);
    try {
      await accion();
      avisos.showSnackBar(SnackBar(content: Text(exito)));
    } on UsuarioRechazadoException catch (rechazo) {
      avisos.showSnackBar(SnackBar(content: Text(_mensajeDe(rechazo.motivo))));
    } catch (_) {
      avisos.showSnackBar(SnackBar(content: Text(errorGenerico)));
    }
  }

  String _mensajeDe(MotivoUsuarioRechazado motivo) => switch (motivo) {
        MotivoUsuarioRechazado.propioUsuario => AppStrings.usuariosErrorPropio,
        MotivoUsuarioRechazado.ultimoAdministrador =>
          AppStrings.usuariosErrorUltimoAdmin,
      };
}

/// Texto centrado para los estados sin lista: vacío, error o sin permiso.
class _Mensaje extends StatelessWidget {
  const _Mensaje(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: AppTextStyles.itemDetail,
        ),
      ),
    );
  }
}
