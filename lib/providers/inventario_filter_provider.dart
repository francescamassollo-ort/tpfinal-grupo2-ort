import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/insumo.dart';
import 'insumo_providers.dart';

// Las 3 formas de ordenar la lista que ofrece el panel de filtros.
enum InventarioSort { nombre, stockMenor, stockMayor }

// es una foto de lo que el usuario eligió para filtrar el inventario.
class InventarioFilter {
  const InventarioFilter({
    this.searchText = '',
    this.sort = InventarioSort.nombre,
    this.categoria,
    this.tipo,
    this.ubicacion,
  });

  final String searchText;
  final InventarioSort sort;
  final String? categoria;
  final InsumoTipo? tipo;
  final String? ubicacion;
}

// NOTIFIER guarda un valor y tiene los metodos para cambiarlo 
class InventarioFilterNotifier extends Notifier<InventarioFilter> {
  // Valor inicial: sin texto, ordenado por nombre, sin filtros.
  @override
  InventarioFilter build() => const InventarioFilter();

  // Lo llama el buscador cada vez que se escribe una letra.
  void setSearchText(String text) {
    state = InventarioFilter(
      searchText: text,
      sort: state.sort,
      categoria: state.categoria,
      tipo: state.tipo,
      ubicacion: state.ubicacion,
    );
  }

  // Lo llama el botón "Filtrar" del panel. Conserva el texto del buscador
  void applyFilters({
    required InventarioSort sort,
    String? categoria,
    InsumoTipo? tipo,
    String? ubicacion,
  }) {
    state = InventarioFilter(
      searchText: state.searchText,
      sort: sort,
      categoria: categoria,
      tipo: tipo,
      ubicacion: ubicacion,
    );
  }
}

final inventarioFilterProvider =
    NotifierProvider<InventarioFilterNotifier, InventarioFilter>(
  InventarioFilterNotifier.new,
);

// La lista que muestra Inventario: ya filtrada y ordenada.
// Mira los insumos y el filtro, y se recalcula solo si cambia cualquiera.
final inventarioFiltradoProvider = Provider<AsyncValue<List<Insumo>>>((ref) {
  final insumosAsync = ref.watch(insumosProvider);
  final filter = ref.watch(inventarioFilterProvider);
  return insumosAsync.whenData((todos) => _filtrarYOrdenar(todos, filter));
});

// Aplica el buscador y los filtros del panel, y después ordena.
List<Insumo> _filtrarYOrdenar(List<Insumo> todos, InventarioFilter filter) {
  final texto = filter.searchText.toLowerCase();
  final resultado = todos
      .where((i) => i.nombre.toLowerCase().contains(texto))
      .where((i) => filter.categoria == null || i.categoria == filter.categoria)
      .where((i) => filter.tipo == null || i.tipo == filter.tipo)
      .where((i) => filter.ubicacion == null || i.ubicacion == filter.ubicacion)
      .toList();

  // sort compara de a dos insumos (a y b) y los acomoda según el resultado.
  switch (filter.sort) {
    case InventarioSort.nombre:
      resultado.sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      );
    case InventarioSort.stockMenor:
      resultado.sort((a, b) => a.stock.compareTo(b.stock));
    case InventarioSort.stockMayor:
      resultado.sort((a, b) => b.stock.compareTo(a.stock));
  }
  return resultado;
}
