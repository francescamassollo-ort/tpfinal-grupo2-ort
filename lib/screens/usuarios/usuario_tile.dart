import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../models/usuario.dart';
import '../../widgets/outlined_list_card.dart';

/// Una fila de la lista de usuarios: avatar con la inicial, nombre, email y rol,
/// y a la derecha el lápiz (cambiar rol) y el tacho (eliminar).
///
/// Si [esPropio] es true (la fila de quien está usando la app), los dos botones
/// quedan deshabilitados: un administrador no se saca el acceso a sí mismo.
class UsuarioTile extends StatelessWidget {
  const UsuarioTile({
    required this.usuario,
    required this.onEditarRol,
    required this.onEliminar,
    this.esPropio = false,
    super.key,
  });

  final Usuario usuario;
  final bool esPropio;
  final VoidCallback onEditarRol;
  final VoidCallback onEliminar;

  // Medidas del avatar y de los botones, según Figma.
  static const double _avatarSize = 40;
  static const double _avatarGap = 12;
  static const double _iconSize = 22;

  @override
  Widget build(BuildContext context) {
    return OutlinedListCard(
      padding: const EdgeInsets.fromLTRB(10, 12, 4, 12),
      child: Row(
        children: [
          _Avatar(nombre: usuario.nombre),
          const SizedBox(width: _avatarGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  usuario.nombre,
                  style: AppTextStyles.itemName,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  usuario.email,
                  style: AppTextStyles.itemDetail,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppStrings.usuariosRol(usuario.rol),
                  style: AppTextStyles.itemDetail.copyWith(
                    color: AppColors.movementBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _AccionIcono(
            icono: Icons.edit,
            tooltip: esPropio
                ? AppStrings.usuariosTuCuenta
                : AppStrings.usuariosCambiarRol,
            onPressed: esPropio ? null : onEditarRol,
          ),
          _AccionIcono(
            icono: Icons.delete,
            tooltip: esPropio
                ? AppStrings.usuariosTuCuenta
                : AppStrings.usuariosEliminar,
            onPressed: esPropio ? null : onEliminar,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.nombre});

  final String nombre;

  @override
  Widget build(BuildContext context) {
    final inicial = nombre.trim().isEmpty ? '?' : nombre.trim()[0].toUpperCase();

    return Container(
      width: UsuarioTile._avatarSize,
      height: UsuarioTile._avatarSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.subtleSurface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.movementBlue, width: 2),
      ),
      // La inicial es decorativa: el nombre ya está escrito al lado.
      child: ExcludeSemantics(
        child: Text(
          inicial,
          style: AppTextStyles.itemName.copyWith(color: AppColors.movementBlue),
        ),
      ),
    );
  }
}

class _AccionIcono extends StatelessWidget {
  const _AccionIcono({
    required this.icono,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icono;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Icon(
        icono,
        size: UsuarioTile._iconSize,
        // Negro como en Figma; deshabilitado se ve atenuado.
        color: onPressed == null ? Colors.black26 : Colors.black,
      ),
    );
  }
}