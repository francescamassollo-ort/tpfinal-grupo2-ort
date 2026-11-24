import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/alerta_vista.dart';

/// Único lugar de la app que habla con la colección "alertasVistas": guarda
/// qué alertas ya vio cada persona.
///
/// Hay un documento por persona y alerta, con el id `{usuarioId}_{alertaId}`.
/// Así marcar dos veces la misma alerta no la duplica, y desmarcarla es borrar
/// ese documento.
class AlertasVistasService {
  AlertasVistasService(FirebaseFirestore db)
      : _db = db,
        _ref = db.collection(coleccion);

  // Nombre de colección propuesto: alertasVistas. Tiene que coincidir con las
  // reglas de Firestore (issue #46).
  static const String coleccion = 'alertasVistas';

  final FirebaseFirestore _db;
  final CollectionReference<Map<String, dynamic>> _ref;

  /// Id del documento de una marca: la persona más la alerta.
  static String idDocumento(String usuarioId, String alertaId) =>
      '${usuarioId}_$alertaId';

  /// Las alertas que [usuarioId] ya vio, en tiempo real. Filtrar por un solo
  /// campo no exige crear ningún índice en Firestore.
  Stream<List<AlertaVista>> watchVistas(String usuarioId) {
    return _ref
        .where('usuarioId', isEqualTo: usuarioId)
        .snapshots()
        .map(
          (snap) => desdeDocumentos([
            for (final doc in snap.docs) (id: doc.id, data: doc.data()),
          ]),
        );
  }

  /// Marca la alerta como vista por [usuarioId]. Si ya estaba marcada, solo
  /// actualiza la fecha.
  Future<void> marcar(
    String usuarioId,
    String alertaId, {
    DateTime? ahora,
  }) {
    final marca = AlertaVista(
      alertaId: alertaId,
      usuarioId: usuarioId,
      vistaEn: ahora ?? DateTime.now(),
    );
    return _ref.doc(idDocumento(usuarioId, alertaId)).set(marca.toMap());
  }

  /// Marca de una vez todas las [alertaIds] como vistas por [usuarioId].
  Future<void> marcarVarias(
    String usuarioId,
    Iterable<String> alertaIds, {
    DateTime? ahora,
  }) {
    final fecha = ahora ?? DateTime.now();
    final batch = _db.batch();
    for (final alertaId in alertaIds) {
      final marca = AlertaVista(
        alertaId: alertaId,
        usuarioId: usuarioId,
        vistaEn: fecha,
      );
      batch.set(_ref.doc(idDocumento(usuarioId, alertaId)), marca.toMap());
    }
    return batch.commit();
  }

  /// Saca la marca: la alerta vuelve a verse como nueva.
  Future<void> desmarcar(String usuarioId, String alertaId) {
    return _ref.doc(idDocumento(usuarioId, alertaId)).delete();
  }

  /// Borra de una vez las marcas de [alertaIds]. Se usa para limpiar las de
  /// alertas que ya no existen (por ejemplo, el stock se repuso): así, si la
  /// alerta vuelve a aparecer más adelante, aparece como nueva.
  Future<void> olvidar(String usuarioId, Iterable<String> alertaIds) {
    final batch = _db.batch();
    for (final alertaId in alertaIds) {
      batch.delete(_ref.doc(idDocumento(usuarioId, alertaId)));
    }
    return batch.commit();
  }

  /// Convierte documentos de Firestore en marcas, en el mismo orden.
  ///
  /// Un documento roto (sin un campo) se saltea y se avisa en la consola: no
  /// tiene que dejar sin marcas a todos los demás.
  static List<AlertaVista> desdeDocumentos(
    Iterable<({String id, Map<String, dynamic> data})> documentos,
  ) {
    final vistas = <AlertaVista>[];
    for (final doc in documentos) {
      try {
        vistas.add(AlertaVista.fromMap(doc.data));
      } catch (error) {
        debugPrint('Marca ${doc.id} ignorada, está mal guardada: $error');
      }
    }
    return vistas;
  }
}
