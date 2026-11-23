import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../providers/auth_provider.dart';

/// "Continuar con Google": inicia sesión con una cuenta de Google institucional
/// de ORT. Sirve igual para ingresar y para crear la cuenta la primera vez.
///
/// Si sale bien, el router lleva solo a Inventario. Si no, `AuthService` ya
/// muestra el motivo en un cartel (o no dice nada si la persona canceló), así que
/// acá solo se evita tocar el botón dos veces mientras se espera.
class BotonGoogle extends ConsumerStatefulWidget {
  const BotonGoogle({super.key});

  @override
  ConsumerState<BotonGoogle> createState() => _BotonGoogleState();
}

class _BotonGoogleState extends ConsumerState<BotonGoogle> {
  bool _ocupado = false;

  Future<void> _continuar() async {
    setState(() => _ocupado = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } finally {
      // Si entró, el router ya cambió de pantalla y este botón no existe más.
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _ocupado ? null : _continuar,
        icon: _ocupado
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.account_circle_outlined),
        label: Text(
          'Continuar con Google',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.primary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
