import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/insumo.dart';
import '../../providers/insumo_providers.dart';
import '../../providers/inventario_filter_provider.dart';
import '../../widgets/insumo_card.dart';
import 'filtro_dialog.dart';

// ConsumerStatefulWidget: ref.watch() para escuchar los insumos y un estado
// propio para el controlador del buscador.
class InventarioScreen extends ConsumerStatefulWidget {
  const InventarioScreen({super.key});

  @override
  ConsumerState<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends ConsumerState<InventarioScreen> {
  // La pantalla se vuelve a crear al ir a otra y volver, pero el filtro vive
  // en el provider: el buscador arranca con el texto que ya estaba aplicado,
  // así lo que se ve escrito siempre coincide con lo que se está filtrando.
  late final TextEditingController _busqueda = TextEditingController(
    text: ref.read(inventarioFilterProvider).searchText,
  );

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              controller: _busqueda,
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
                    itemBuilder: (context, index) => InsumoCard(
                      insumo: insumos[index],
                      // push (no go): apila el Detalle, así "volver"
                      // regresa a Inventario. Solo viaja el id en la ruta.
                      onTap: () =>
                          context.push('/insumo/${insumos[index].id}'),
                    ),
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
          estado: elegido.estado,
        );
  }
}
