import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/insumo.dart';

// Único lugar de la app que habla con la colección insumos de Firestore.
class InsumoService {
  final _insumosRef = FirebaseFirestore.instance.collection('insumos');

  // Cada vez q algo cambia en firestore, devuelve la lista completa de insumos actualizada

  Stream<List<Insumo>> watchInsumos() {
    return _insumosRef.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Insumo.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // Trae un insumo puntual por su id, para la pantalla de Detalle.
  Future<Insumo?> obtenerInsumo(String id) async {
    final doc = await _insumosRef.doc(id).get();
    if (!doc.exists) return null;
    return Insumo.fromMap(doc.id, doc.data()!);
  }

  // Crea un insumo nuevo, para la pantalla de Alta.
  Future<void> agregarInsumo(Insumo insumo) {
    return _insumosRef.add(insumo.toMap());
  }

  // Actualiza solo el stock de un insumo existente (Alta/Consumo).
  Future<void> actualizarStock(String insumoId, int nuevoStock) {
    return _insumosRef.doc(insumoId).update({'stock': nuevoStock});
  }
}
