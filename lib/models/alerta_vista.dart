import 'package:cloud_firestore/cloud_firestore.dart';

/// La marca de que una persona ya vio una alerta.
///
/// Las alertas se calculan y no se guardan, así que lo único que se guarda es
/// esta marca: "[usuarioId] vio la alerta [alertaId]". Es por persona: que una
/// la haya visto no la saca de la lista de las demás.
///
/// [alertaId] es el id de la propia alerta (`Alerta.id`, por ejemplo
/// "abc-stockBajo"): el insumo más el motivo.
class AlertaVista {
  const AlertaVista({
    required this.alertaId,
    required this.usuarioId,
    required this.vistaEn,
  });

  final String alertaId;
  final String usuarioId;

  /// Cuándo la marcó como vista.
  final DateTime vistaEn;

  /// Convierte un documento de Firestore (Map) en una AlertaVista. Lanza una
  /// excepción si el documento está incompleto: quien lo lea decide qué hacer
  /// con un documento roto.
  factory AlertaVista.fromMap(Map<String, dynamic> data) {
    return AlertaVista(
      alertaId: data['alertaId'] as String,
      usuarioId: data['usuarioId'] as String,
      vistaEn: (data['vistaEn'] as Timestamp).toDate(),
    );
  }

  /// Convierte esta marca en un Map listo para guardar en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'alertaId': alertaId,
      'usuarioId': usuarioId,
      'vistaEn': Timestamp.fromDate(vistaEn),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is AlertaVista &&
      other.alertaId == alertaId &&
      other.usuarioId == usuarioId &&
      other.vistaEn == vistaEn;

  @override
  int get hashCode => Object.hash(alertaId, usuarioId, vistaEn);
}
