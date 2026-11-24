import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_strings.dart';
import '../../providers/insumo_providers.dart';
import 'insumo_alta_screen.dart';

/// Editar un insumo existente (R06). Espera a tener el insumo cargado y recién
/// ahí arma el formulario, así los campos nacen con sus valores y no hace falta
/// rellenarlos después. El formulario es el mismo del Alta.
class InsumoEditarScreen extends ConsumerWidget {
  const InsumoEditarScreen({required this.insumoId, super.key});

  final String insumoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(insumoPorIdProvider(insumoId)).when(
          data: (insumo) => insumo == null
              ? const Center(child: Text(AppStrings.editarInsumoNoExiste))
              : InsumoAltaScreen(key: ValueKey(insumo.id), insumo: insumo),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              const Center(child: Text(AppStrings.editarInsumoNoExiste)),
        );
  }
}
