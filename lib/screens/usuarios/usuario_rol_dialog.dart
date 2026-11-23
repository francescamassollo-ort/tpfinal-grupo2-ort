import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../models/usuario.dart';

/// Panel para cambiar el rol de un usuario. Mismo estilo que los otros paneles
/// de la app (un Dialog con StatefulWidget común, sin Riverpod).
///
/// El rol elegido se guarda acá con setState y recién al tocar "Guardar" el
/// panel se cierra y devuelve el [UserRole] nuevo. Si se cierra tocando afuera o
/// con "Cancelar" devuelve null y no se cambia nada. "Guardar" queda apagado
/// mientras el rol elegido sea el que el usuario ya tiene.
class UsuarioRolDialog extends StatefulWidget {
  const UsuarioRolDialog({required this.usuario, super.key});

  final Usuario usuario;

  @override
  State<UsuarioRolDialog> createState() => _UsuarioRolDialogState();
}

class _UsuarioRolDialogState extends State<UsuarioRolDialog> {
  late UserRole _rol = widget.usuario.rol;

  @override
  Widget build(BuildContext context) {
    final hayCambio = _rol != widget.usuario.rol;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.usuariosRolDe(widget.usuario.nombre),
              style: AppTextStyles.listItemTitle,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserRole>(
              initialValue: _rol,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: AppStrings.usuariosCampoRol,
              ),
              items: [
                for (final rol in UserRole.values)
                  DropdownMenuItem(
                    value: rol,
                    child: Text(AppStrings.usuariosRol(rol)),
                  ),
              ],
              onChanged: (rol) {
                if (rol != null) setState(() => _rol = rol);
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(AppStrings.cancelar),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        hayCambio ? () => Navigator.of(context).pop(_rol) : null,
                    child: const Text(AppStrings.usuariosGuardarRol),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}