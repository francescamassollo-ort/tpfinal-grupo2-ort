import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/insumo.dart';
import '../services/busqueda_de_insumos.dart';
import 'insumo_providers.dart';

// Las 3 formas de ordenar la lista que ofrece el panel de filtros.
enum InventarioSort { nombre, stockMenor, stockMayor }

// En qué situación está el stock de un insumo. Son tres estados que no se
// pisan: con stock de sobra, bajo (en el mínimo o por debajo, pero no en cero)
// y sin stock (cero). Es el mismo criterio de los colores del Inventario.
enum EstadoStock {
  enStock('En stock'),
  stockBajo('Stock bajo'),
  sinStock('Sin stock');

  const EstadoStock(this.etiqueta);

  /// Lo que dice el panel de filtros.
  final String etiqueta;

  /// El estado de [insumo].
  static EstadoStock de(Insumo insumo) {
    if (insumo.stock <= 0) return sinStock;
    return insumo.stockBajo ? stockBajo : enStock;
  }
}

// "Foto" de lo que el usuario eligió para filtrar el inventario.
// null en categoria/tipo/ubicacion/estado significa "todas" (sin filtrar).
class InventarioFilter {
  const InventarioFilter({
    this.searchText = '',
    this.sort = InventarioSort.nombre,
    this.categoria,
    this.tipo,
    this.ubicacion,
    this.estado,
  });

  final String searchText;
  final InventarioSort sort;
  final String? categoria;
  final InsumoTipo? tipo;
  final String? ubicacion;
  final EstadoStock? estado;
}

// Mismo patrón que RoleNotifier: guarda un valor (el filtro actual) y
// tiene métodos para cambiarlo. Cada vez que se asigna "state", todas
// las pantallas que hacen ref.watch(inventarioFilterProvider) se redibujan.
class InventarioFilterNotifier extends Notifier<InventarioFilter> {
  // Valor inicial: sin texto, ordenado por nombre, sin filtros.
  @override
  InventarioFilter build() => const InventarioFilter();

  // Lo llama el buscador cada vez que se escribe una letra.
  // Se crea un filtro nuevo copiando todo lo anterior y cambiando solo el texto.
  void setSearchText(String text) {
    state = InventarioFilter(
      searchText: text,
      sort: state.sort,
      categoria: state.categoria,
      tipo: state.tipo,
      ubicacion: state.ubicacion,
      estado: state.estado,
    );
  }

  // Lo llama el botón "Filtrar" del panel. Conserva el texto del buscador
  // y reemplaza el resto con lo que se eligió en el panel.
  void applyFilters({
    required InventarioSort sort,
    String? categoria,
    InsumoTipo? tipo,
    String? ubicacion,
    EstadoStock? estado,
  }) {
    state = InventarioFilter(
      searchText: state.searchText,
      sort: sort,
      categoria: categoria,
      tipo: tipo,
      ubicacion: ubicacion,
      estado: estado,
    );
  }
}

final inventarioFilterProvider =
    NotifierProvider<InventarioFilterNotifier, InventarioFilter>(
  InventarioFilterNotifier.new,
);

// La lista que muestra Inventario: ya filtrada y ordenada.
// Mira los insumos y el filtro, y se recalcula solo si cambia cualquiera.
// whenData aplica el filtro cuando hay datos; "cargando" y "error" pasan igual.
final inventarioFiltradoProvider = Provider<AsyncValue<List<Insumo>>>((ref) {
  final insumosAsync = ref.watch(insumosProvider);
  final filter = ref.watch(inventarioFilterProvider);
  return insumosAsync.whenData((todos) => _filtrarYOrdenar(todos, filter));
});

// Aplica el buscador y los filtros del panel, y después ordena.
// Un insumo queda en la lista solo si cumple TODAS las condiciones.
// Si un filtro es null significa "todas", así que no descarta nada.
List<Insumo> _filtrarYOrdenar(List<Insumo> todos, InventarioFilter filter) {
  final resultado = todos
      .where((i) => BusquedaDeInsumos.coincide(i, filter.searchText))
      .where((i) => filter.categoria == null || i.categoria == filter.categoria)
      .where((i) => filter.tipo == null || i.tipo == filter.tipo)
      .where((i) => filter.ubicacion == null || i.ubicacion == filter.ubicacion)
      .where((i) => filter.estado == null || EstadoStock.de(i) == filter.estado)
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
