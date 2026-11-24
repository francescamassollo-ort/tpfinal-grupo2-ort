import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/role_provider.dart';
import '../../widgets/handy_button_style_one.dart';

/// Pide verificar el mail antes de usar la app. Se llega acá, solo, al
/// registrarse o al ingresar con una cuenta cuyo mail todavía no se verificó.
///
/// La app no se entera sola de que la persona tocó el enlace del correo, por eso
/// hay que tocar "Ya verifiqué" para que lo vuelva a comprobar.
class VerificarEmailScreen extends ConsumerStatefulWidget {
  const VerificarEmailScreen({super.key});

  @override
  ConsumerState<VerificarEmailScreen> createState() =>
      _VerificarEmailScreenState();
}

class _VerificarEmailScreenState extends ConsumerState<VerificarEmailScreen> {
  // Mientras se habla con Firebase los botones no se pueden volver a tocar.
  bool _ocupado = false;

  Future<void> _yaVerifique() async {
    final avisos = ScaffoldMessenger.of(context);
    final auth = ref.read(authServiceProvider);

    setState(() => _ocupado = true);
    final verificado = await auth.mailVerificado();
    if (!mounted) return;
    setState(() => _ocupado = false);

    if (!verificado) {
      avisos.showSnackBar(
        const SnackBar(
          content: Text(
            'Todavía no figura como verificado. Abrí el enlace del correo y '
            'volvé a probar.',
          ),
        ),
      );
      return;
    }

    // El rol se calcula solo para cuentas verificadas: se vuelve a pedir ahora.
    ref.invalidate(sesionProvider);
    context.go('/home');
  }

  Future<void> _reenviar() async {
    final avisos = ScaffoldMessenger.of(context);

    setState(() => _ocupado = true);
    final seMando = await ref.read(authServiceProvider).sendEmailVerification();
    if (!mounted) return;
    setState(() => _ocupado = false);

    if (seMando) {
      avisos.showSnackBar(
        const SnackBar(
          content: Text(
            'Te mandamos el correo de nuevo. Revisá también la carpeta de spam.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authServiceProvider).emailActual;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 18,
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 72,
                color: AppColors.primary,
              ),
              Text(
                'Verificá tu mail',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                email == null
                    ? 'Te mandamos un correo con un enlace. Abrilo para '
                        'confirmar que el mail es tuyo y volvé acá.'
                    : 'Te mandamos un correo a $email con un enlace. Abrilo '
                        'para confirmar que el mail es tuyo y volvé acá.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.bodyColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: getButtonStyleOne(),
                  onPressed: _ocupado ? null : _yaVerifique,
                  child: const Text('Ya verifiqué'),
                ),
              ),
              TextButton(
                onPressed: _ocupado ? null : _reenviar,
                child: const Text('Reenviar el correo'),
              ),
              TextButton(
                // Para quien se registró con un mail equivocado.
                onPressed: _ocupado
                    ? null
                    : () => ref.read(authServiceProvider).signOut(),
                child: const Text('Usar otra cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
