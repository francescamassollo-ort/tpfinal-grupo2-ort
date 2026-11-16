import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trabajo_practico.dart';
 
/// Resultado de comparar los insumos de un TP contra el stock actual.
class DisponibilidadTP {
  const DisponibilidadTP(this.faltantes);
 
  /// insumoId -> cantidad que falta (solo los insumos con faltante).
  final Map<String, double> faltantes;
 
  bool get completo => faltantes.isEmpty;
}
 
class TpService {
  TpService(FirebaseFirestore db)
      : _ref = db.collection('listasTP').withConverter<TrabajoPractico>(
              fromFirestore: TrabajoPractico.fromFirestore,
              toFirestore: (tp, _) => tp.toFirestore(),
            );
 
  // Nombre de colección acordado: listasTP.
  // Tiene que coincidir con las reglas de Firestore (issue #44).
  final CollectionReference<TrabajoPractico> _ref;
 
  // ---- Versión Future (una sola lectura) ---------------------------------
 
  Future<List<TrabajoPractico>> getAll() async {
    final snap = await _ref.orderBy('fecha').get();
    // Filtro en Dart para no exigir un índice compuesto en Firestore.
    return snap.docs.map((d) => d.data()).where((tp) => tp.activo).toList();
  }
 
  // ---- Versión Stream (tiempo real) --------------------------------------
 
  Stream<List<TrabajoPractico>> watchAll() {
    return _ref.orderBy('fecha').snapshots().map(
          (snap) =>
              snap.docs.map((d) => d.data()).where((tp) => tp.activo).toList(),
        );
  }
 
  // ---- CRUD --------------------------------------------------------------
 
  Future<TrabajoPractico?> getById(String id) async =>
      (await _ref.doc(id).get()).data();
 
  /// Crea el TP con id autogenerado y devuelve ese id.
  Future<String> create(TrabajoPractico tp) async {
    final doc = _ref.doc(); // id único generado por Firestore
    await doc.set(tp);
    return doc.id;
  }
 
  Future<void> update(TrabajoPractico tp) => _ref.doc(tp.id).set(tp);
 
  /// Borrado lógico, no se elimina el documento.
  Future<void> desactivar(String id) => _ref.doc(id).update({'activo': false});
 
  /// Alias de [desactivar], por si el issue pide literalmente `delete(id)`.
  Future<void> delete(String id) => desactivar(id);
 
  // ---- Reglas de negocio -------------------------------------------------
 
  /// Compara los insumos requeridos del TP contra el stock actual.
  /// [stockPorInsumo]: insumoId -> stock disponible. Se recibe por parámetro
  /// para no acoplar este servicio al de insumos.
  DisponibilidadTP verificarDisponibilidad(
    TrabajoPractico tp,
    Map<String, num> stockPorInsumo,
  ) {
    final faltantes = <String, double>{};
    for (final insumo in tp.insumos) {
      final stock = stockPorInsumo[insumo.insumoId] ?? 0;
      if (stock < insumo.cantidad) {
        faltantes[insumo.insumoId] = insumo.cantidad - stock;
      }
    }
    return DisponibilidadTP(faltantes);
  }
}
