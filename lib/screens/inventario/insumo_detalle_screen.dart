import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/insumo_providers.dart';

// Detalle de un insumo. Recibe solo el id (viene en la ruta /insumo/:id)
// y busca el insumo actualizado con insumoPorIdProvider.
// Versión mínima del paso 1: solo muestra el nombre, el diseño va en el paso 2.
class InsumoDetalleScreen extends ConsumerWidget {
  const InsumoDetalleScreen({required this.insumoId, super.key});

  final String insumoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insumoAsync = ref.watch(insumoPorIdProvider(insumoId));

    return insumoAsync.when(
      data: (insumo) {
        if (insumo == null) {
          return const Center(child: Text('El insumo no existe'));
        }
        return Center(child: Text(insumo.nombre));
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
