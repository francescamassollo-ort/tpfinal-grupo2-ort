import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trabajo_practico.dart';
import '../providers/insumo_providers.dart';
import '../services/trabajopractico_service.dart';
 
final tpServiceProvider =
    Provider((ref) => TpService(FirebaseFirestore.instance));
 
// ---- Versión Future: lista + acciones de escritura -----------------------
 
class TpNotifier extends AsyncNotifier<List<TrabajoPractico>> {
  @override
  Future<List<TrabajoPractico>> build() => ref.read(tpServiceProvider).getAll();
 
  Future<void> crear(TrabajoPractico tp) async {
    await ref.read(tpServiceProvider).create(tp);
    ref.invalidateSelf();
  }
 
  Future<void> actualizar(TrabajoPractico tp) async {
    await ref.read(tpServiceProvider).update(tp);
    ref.invalidateSelf();
  }
 
  Future<void> desactivar(String id) async {
    await ref.read(tpServiceProvider).desactivar(id);
    ref.invalidateSelf();
  }
}
 
final tpProvider =
    AsyncNotifierProvider<TpNotifier, List<TrabajoPractico>>(TpNotifier.new);
 
// ---- Versión Stream: lista en tiempo real (solo lectura) -----------------
// Se redibuja sola ante cambios en Firestore; no hace falta invalidar.
 
final tpsStreamProvider = StreamProvider<List<TrabajoPractico>>(
  (ref) => ref.watch(tpServiceProvider).watchAll(),
);
 
// ---- Un TP por id (Detalle y precarga de Editar) -------------------------
 
final tpPorIdProvider = FutureProvider.family<TrabajoPractico?, String>(
  (ref, id) => ref.watch(tpServiceProvider).getById(id),
);
 
// ---- Disponibilidad de insumos de un TP ----------------------------------
// Cruza el TP con el stock que emite insumosProvider.
// SUPUESTO: el modelo Insumo expone `id` y `stock` (numérico). Ajustar si
// los campos se llaman distinto.
 
final disponibilidadTpProvider =
    Provider.family<AsyncValue<DisponibilidadTP>, TrabajoPractico>((ref, tp) {
  final service = ref.watch(tpServiceProvider);
  return ref.watch(insumosProvider).whenData((insumos) {
    final stock = {for (final i in insumos) i.id: i.stock};
    return service.verificarDisponibilidad(tp, stock);
  });
});