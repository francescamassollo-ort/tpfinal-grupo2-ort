import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/insumo.dart';

// Único lugar de la app que habla con la colección "insumos" de Firestore.
// Las pantallas le piden datos a esta clase, nunca hablan con Firestore
// directo.
class InsumoService {
  // Nombre de la colección. Tiene que coincidir con las reglas de Firestore
  // (issue #46) y lo usa también StockService para cambiar el stock.
  static const String coleccion = 'insumos';

  final _insumosRef = FirebaseFirestore.instance.collection(coleccion);

  // Lista de insumos en tiempo real: cada vez que algo cambia en Firestore
  // (en este celular o en cualquier otro), este Stream emite la lista
  // actualizada solo, sin que nadie tenga que pedir nada de nuevo.
  //
  // Por defecto solo trae los insumos activos: son los que se usan en todas las
  // pantallas. Con [incluirBajas] trae también los dados de baja, que hacen
  // falta para mostrar el nombre en el historial de movimientos viejos.
  Stream<List<Insumo>> watchInsumos({bool incluirBajas = false}) {
    return _insumosRef.snapshots().map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              if (incluirBajas || (doc.data()['activo'] as bool? ?? true))
                Insumo.fromMap(doc.id, doc.data()),
          ],
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

  // Guarda los datos editados de un insumo. No toca el stock ni la baja: el
  // stock cambia solo con movimientos (para que el historial lo explique) y la
  // baja con [darDeBaja].
  Future<void> actualizarInsumo(Insumo insumo) {
    final datos = insumo.toMap()
      ..remove('stock')
      ..remove('activo');
    return _insumosRef.doc(insumo.id).update(datos);
  }

  // Baja lógica: el insumo queda con activo en false y deja de aparecer en la
  // app, pero sus movimientos del historial se conservan.
  Future<void> darDeBaja(String insumoId) {
    return _insumosRef.doc(insumoId).update({'activo': false});
  }

  // Actualiza solo el stock de un insumo existente (Alta/Consumo).
  Future<void> actualizarStock(String insumoId, int nuevoStock) {
    return _insumosRef.doc(insumoId).update({'stock': nuevoStock});
  }
}
