import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trabajo_practico.dart';
import '../services/trabajopractico_service.dart';

final tpServiceProvider =
    Provider((ref) => TpService(FirebaseFirestore.instance));

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