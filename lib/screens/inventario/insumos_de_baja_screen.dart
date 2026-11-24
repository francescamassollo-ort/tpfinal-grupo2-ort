import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../models/insumo.dart';
import '../../providers/insumo_providers.dart';
import '../../widgets/app_screen_header.dart';

/// Los insumos dados de baja, para poder reactivarlos. Solo para el
/// administrador (el mismo permiso que editar y dar de baja).
///
/// Dar de baja un insumo no lo borra (su historial se conserva): lo saca del
/// inventario, y desde acá vuelve.
class InsumosDeBajaScreen extends ConsumerWidget {
  const InsumosDeBajaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insumos = ref.watch(insumosConBajasProvider);

    return Material(
      color: AppColors.screenBackground,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppScreenHeader(
              title: AppStrings.insumosBajaTitulo,
              onBack: () => context.canPop() ? context.pop() : context.go('/inventario'),
            ),
            Expanded(
              child: insumos.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    const _Mensaje(AppStrings.insumosBajaError),
                data: (todos) {
                  final bajas = [for (final i in todos) if (!i.activo) i]
                    ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
                  if (bajas.isEmpty) return const _Mensaje(AppStrings.insumosBajaVacio);

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                    itemCount: bajas.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) => _Fila(insumo: bajas[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fila extends ConsumerWidget {
  const _Fila({required this.insumo});

  final Insumo insumo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(insumo.nombre, style: AppTextStyles.itemName),
      subtitle: Text(insumo.ubicacion, style: AppTextStyles.itemDetail),
      trailing: TextButton(
        onPressed: () => _reactivar(context, ref),
        child: const Text(AppStrings.insumosReactivar),
      ),
    );
  }

  Future<void> _reactivar(BuildContext context, WidgetRef ref) async {
    // Se toma antes del await: después la pantalla puede ya no estar.
    final avisos = ScaffoldMessenger.of(context);
    try {
      await ref.read(insumoServiceProvider).reactivar(insumo.id);
      avisos.showSnackBar(
        SnackBar(content: Text(AppStrings.insumosReactivado(insumo.nombre))),
      );
    } catch (_) {
      avisos.showSnackBar(
        const SnackBar(content: Text(AppStrings.insumosReactivarError)),
      );
    }
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Text(texto, textAlign: TextAlign.center, style: AppTextStyles.itemDetail),
      ),
    );
  }
}
