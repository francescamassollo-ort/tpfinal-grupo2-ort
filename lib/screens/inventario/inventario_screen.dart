import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/insumo.dart';
import '../../providers/insumo_providers.dart';
import '../../providers/inventario_filter_provider.dart';
import '../../widgets/insumo_card.dart';
import 'filtro_dialog.dart';

// ConsumerWidget para poder usar ref.watch() y escuchar el provider de insumos.
class InventarioScreen extends ConsumerWidget {
  const InventarioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insumosAsync = ref.watch(insumosProvider);
    // La lista ya filtrada y ordenada: la pantalla solo la dibuja.
    final filtradosAsync = ref.watch(inventarioFiltradoProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inventario',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar insumo',
                prefixIcon: Icon(Icons.search),
              ),
              // ref.read (no watch): acá no queremos escuchar cambios,
              // solo llamar una vez al método del Notifier.
              onChanged: (text) => ref
                  .read(inventarioFilterProvider.notifier)
                  .setSearchText(text),
            ),
            // Botón de filtros, alineado a la derecha como en el Figma.
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Filtros',
                // .value: la lista si ya cargó, o null si todavía no.
                onPressed: () => _abrirFiltros(
                  context,
                  ref,
                  insumosAsync.value ?? [],
                ),
              ),
            ),
            Expanded(
              // AsyncValue.when(): un Stream puede estar "cargando" (todavía
              // no llegó el primer dato), con "error" (algo falló) o con
              // "data" (ya tenemos la lista). .when() te obliga a manejar
              // los 3 casos, así no te olvidás de ninguno.
              child: filtradosAsync.when(
                data: (insumos) {
                  if (insumosAsync.value?.isEmpty ?? true) {
                    return const Center(
                      child: Text('Todavía no hay insumos cargados'),
                    );
                  }
                  if (insumos.isEmpty) {
                    return const Center(
                      child: Text('No se encontraron insumos'),
                    );
                  }
                  return ListView.builder(
                    itemCount: insumos.length,
                    itemBuilder: (context, index) =>
                        InsumoCard(insumo: insumos[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Center(child: Text('Error al cargar insumos: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Abre el panel de filtros y espera (await) a que se cierre.
  // Si se tocó "Filtrar", showDialog devuelve el filtro elegido y se lo
  // pasamos al Notifier. Si se cerró tocando afuera, devuelve null.
  Future<void> _abrirFiltros(
    BuildContext context,
    WidgetRef ref,
    List<Insumo> insumos,
  ) async {
    final elegido = await showDialog<InventarioFilter>(
      context: context,
      builder: (context) => FiltroDialog(
        filtroActual: ref.read(inventarioFilterProvider),
        insumos: insumos,
      ),
    );
    if (elegido == null) return;
    ref.read(inventarioFilterProvider.notifier).applyFilters(
          sort: elegido.sort,
          categoria: elegido.categoria,
          tipo: elegido.tipo,
          ubicacion: elegido.ubicacion,
        );
  }
}
