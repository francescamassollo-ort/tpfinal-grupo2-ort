import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ubicacion.dart';
import 'ubicaciones_logica.dart';

/// Único lugar de la app que habla con la colección "ubicaciones" de Firestore.
class UbicacionService {
  // Tiene que coincidir con las reglas de Firestore (issue #46).
  static const String coleccion = 'ubicaciones';

  final _ref = FirebaseFirestore.instance.collection(coleccion);

  /// Las ubicaciones, en tiempo real y ordenadas por nombre.
  Stream<List<Ubicacion>> watchUbicaciones() {
    return _ref.snapshots().map((snapshot) {
      final lista = [
        for (final doc in snapshot.docs) Ubicacion.fromMap(doc.id, doc.data()),
      ]..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      return lista;
    });
  }

  /// Agrega [nombre] a la lista si todavía no está. El id sale del nombre, así
  /// que escribir dos veces el mismo lugar (aunque cambien mayúsculas o
  /// espacios) toca el mismo documento y no lo duplica. Si ya existía no pisa su
  /// escritura.
  Future<void> crearSiNoExiste(String nombre) async {
    final limpio = UbicacionesLogica.limpiar(nombre);
    final id = UbicacionesLogica.idDe(limpio);
    if (id.isEmpty) return;

    final doc = _ref.doc(id);
    await doc.firestore.runTransaction((transaccion) async {
      final actual = await transaccion.get(doc);
      if (!actual.exists) transaccion.set(doc, Ubicacion(id: id, nombre: limpio).toMap());
    });
  }
}
