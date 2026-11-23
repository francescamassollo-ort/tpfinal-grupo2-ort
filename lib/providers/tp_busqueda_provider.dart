import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trabajo_practico.dart';
import 'trabajopractico_provider.dart';

// Texto que se escribe en el buscador de la lista de TPs.
// autoDispose: al salir de la pantalla el filtro se borra solo, así no
// queda una búsqueda "fantasma" aplicada cuando se vuelve a entrar.
class TpBusquedaNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setTexto(String texto) => state = texto;
}

final tpBusquedaProvider =
    NotifierProvider.autoDispose<TpBusquedaNotifier, String>(
  TpBusquedaNotifier.new,
);

// La lista ya filtrada por nombre: la pantalla solo la dibuja.
// Parte de tpProvider (la lista que se invalida al crear/editar/desactivar).
final tpsFiltradosProvider =
    Provider.autoDispose<AsyncValue<List<TrabajoPractico>>>((ref) {
  final busqueda = ref.watch(tpBusquedaProvider).trim().toLowerCase();
  return ref.watch(tpProvider).whenData((tps) {
    if (busqueda.isEmpty) return tps;
    return tps
        .where((tp) => tp.nombre.toLowerCase().contains(busqueda))
        .toList();
  });
});