import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_strings.dart';
import '../core/app_text_styles.dart';
import '../providers/insumo_providers.dart';

// Panel inferior para elegir un insumo del inventario. Devuelve el Insumo
// elegido con Navigator.pop (o null si se cierra sin elegir).
// ConsumerStatefulWidget: lee insumosProvider y guarda el texto del buscador,
// que es estado transitorio de este panel y no se comparte con nadie.
class InsumoSelectorSheet extends ConsumerStatefulWidget {
  const InsumoSelectorSheet({super.key, required this.excluidos});

  /// ids que ya están en el TP: no se vuelven a ofrecer.
  final Set<String> excluidos;

  @override
  ConsumerState<InsumoSelectorSheet> createState() =>
      _InsumoSelectorSheetState();
}

class _InsumoSelectorSheetState extends ConsumerState<InsumoSelectorSheet> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final insumosAsync = ref.watch(insumosProvider);

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Padding(
        // Sube el panel cuando aparece el teclado.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                AppStrings.tpSeleccionarInsumo,
                style: AppTextStyles.screenTitle,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: AppStrings.tpBuscarInsumoHint,
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (texto) =>
                    setState(() => _busqueda = texto.trim().toLowerCase()),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: insumosAsync.when(
                data: (insumos) {
                  final disponibles = insumos
                      .where(
                        (i) =>
                            !widget.excluidos.contains(i.id) &&
                            i.nombre.toLowerCase().contains(_busqueda),
                      )
                      .toList()
                    ..sort((a, b) => a.nombre.compareTo(b.nombre));

                  if (disponibles.isEmpty) {
                    return const Center(
                      child: Text(AppStrings.tpSinInsumosDisponibles),
                    );
                  }
                  return ListView.builder(
                    itemCount: disponibles.length,
                    itemBuilder: (context, index) {
                      final insumo = disponibles[index];
                      return ListTile(
                        title: Text(insumo.nombre, style: AppTextStyles.itemName),
                        subtitle: Text(
                          '${AppStrings.tpStockUnidades(insumo.stock)} · '
                          '${insumo.ubicacion}',
                          style: AppTextStyles.itemDetail,
                        ),
                        onTap: () => Navigator.of(context).pop(insumo),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    const Center(child: Text(AppStrings.tpErrorDisponibilidad)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}