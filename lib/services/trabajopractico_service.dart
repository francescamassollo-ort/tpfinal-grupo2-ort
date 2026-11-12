import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trabajo_practico.dart';

class TpService {
  TpService(FirebaseFirestore db)
      : _ref = db.collection('trabajos_practicos').withConverter<TrabajoPractico>(
              fromFirestore: TrabajoPractico.fromFirestore,
              toFirestore: (tp, _) => tp.toFirestore(),
            );

  // [VERIFICAR] nombre real de la colección con el equipo
  final CollectionReference<TrabajoPractico> _ref;

  Future<List<TrabajoPractico>> getAll() async {
    final snap = await _ref.orderBy('fecha').get();
    // Filtro en Dart para no exigir un índice compuesto en Firestore.
    return snap.docs.map((d) => d.data()).where((tp) => tp.activo).toList();
  }

  Future<TrabajoPractico?> getById(String id) async =>
      (await _ref.doc(id).get()).data();

  Future<void> create(TrabajoPractico tp) => _ref.doc().set(tp); // id único generado

  Future<void> update(TrabajoPractico tp) => _ref.doc(tp.id).set(tp);

  /// Borrado lógico, no se elimina el documento.
  Future<void> desactivar(String id) => _ref.doc(id).update({'activo': false});
}
