import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/movimiento_stock.dart';

/// Lee los movimientos de stock de la colección "movimientosStock".
///
/// Solo lee. Los movimientos los escribe quien cambia el stock (el servicio de
/// stock), en la misma operación que cambia el stock del insumo, para que no
/// quede un stock cambiado sin su movimiento ni al revés. Esa persona usa
/// [coleccion] y [MovimientoStock.toMap].
class HistorialService {
  HistorialService(FirebaseFirestore db) : _ref = db.collection(coleccion);

  // Nombre de colección propuesto: movimientosStock. Tiene que coincidir con
  // las reglas de Firestore (issue #46).
  static const String coleccion = 'movimientosStock';

  // Provisorio: cuántos movimientos, los más recientes, se traen. Alcanza para
  // un laboratorio chico. Si el historial crece, hay que paginar.
  static const int maximoMovimientos = 500;

  final CollectionReference<Map<String, dynamic>> _ref;

  /// Los últimos movimientos, en tiempo real y del más nuevo al más viejo.
  /// Ordenar por un solo campo no exige crear ningún índice en Firestore.
  Stream<List<MovimientoStock>> watchMovimientos() {
    return _ref
        .orderBy('fecha', descending: true)
        .limit(maximoMovimientos)
        .snapshots()
        .map(
          (snap) => desdeDocumentos([
            for (final doc in snap.docs) (id: doc.id, data: doc.data()),
          ]),
        );
  }

  /// Convierte documentos de Firestore en movimientos, en el mismo orden.
  ///
  /// Un documento roto (sin un campo, con un tipo desconocido) se saltea y se
  /// avisa en la consola: no tiene que dejar sin historial a todos los demás.
  static List<MovimientoStock> desdeDocumentos(
    Iterable<({String id, Map<String, dynamic> data})> documentos,
  ) {
    final movimientos = <MovimientoStock>[];
    for (final doc in documentos) {
      try {
        movimientos.add(MovimientoStock.fromMap(doc.id, doc.data));
      } catch (error) {
        debugPrint('Movimiento ${doc.id} ignorado, está mal guardado: $error');
      }
    }
    return movimientos;
  }
}
