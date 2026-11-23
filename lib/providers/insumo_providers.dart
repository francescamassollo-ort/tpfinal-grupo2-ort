import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/insumo.dart';
import '../services/insumo_service.dart';

// Cualquier pantalla que haga ref.watch(insumosProvider) se redibuja
// sola cada vez que cambia algo en firestoire
final insumosProvider = StreamProvider<List<Insumo>>((ref) {
  final service = InsumoService();
  return service.watchInsumos();
});

// Un insumo puntual, buscado por id dentro de la lista en tiempo real.
// como mira por id si cambia en firestore, se redibuja solo, si no tiene nada vale null
final insumoPorIdProvider =
    Provider.family<AsyncValue<Insumo?>, String>((ref, id) {
  return ref.watch(insumosProvider).whenData(
        (insumos) => insumos.where((i) => i.id == id).firstOrNull,
      );
});
