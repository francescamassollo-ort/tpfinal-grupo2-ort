import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/alerta_vista.dart';
import 'package:tpfinal_grupo2/services/alertas_vistas_service.dart';

final _momento = DateTime(2026, 11, 20, 10, 30);

Map<String, dynamic> _datos({
  String alertaId = 'p1-stockBajo',
  String usuarioId = 'u1',
}) {
  return {
    'alertaId': alertaId,
    'usuarioId': usuarioId,
    'vistaEn': Timestamp.fromDate(_momento),
  };
}

void main() {
  group('AlertaVista', () {
    test('se lee de un documento de Firestore', () {
      final vista = AlertaVista.fromMap(_datos());

      expect(vista.alertaId, 'p1-stockBajo');
      expect(vista.usuarioId, 'u1');
      expect(vista.vistaEn, _momento);
    });

    test('lo que se guarda se vuelve a leer igual', () {
      final original = AlertaVista(
        alertaId: 'p2-agotamientoProximo',
        usuarioId: 'u9',
        vistaEn: _momento,
      );

      expect(AlertaVista.fromMap(original.toMap()), original);
    });

    test('un documento incompleto lanza una excepción', () {
      expect(
        () => AlertaVista.fromMap({'alertaId': 'p1-stockBajo'}),
        throwsA(anything),
      );
    });

    test('dos marcas con distinta persona no son iguales', () {
      final a = AlertaVista(alertaId: 'x', usuarioId: 'u1', vistaEn: _momento);
      final b = AlertaVista(alertaId: 'x', usuarioId: 'u2', vistaEn: _momento);

      expect(a, isNot(b));
      expect(a, AlertaVista(alertaId: 'x', usuarioId: 'u1', vistaEn: _momento));
    });
  });

  group('AlertasVistasService', () {
    test('el id del documento junta la persona y la alerta', () {
      expect(
        AlertasVistasService.idDocumento('u1', 'p1-stockBajo'),
        'u1_p1-stockBajo',
      );
    });

    test('la misma alerta de dos personas son documentos distintos', () {
      expect(
        AlertasVistasService.idDocumento('u1', 'p1-stockBajo'),
        isNot(AlertasVistasService.idDocumento('u2', 'p1-stockBajo')),
      );
    });

    test('convierte documentos en marcas, en el mismo orden', () {
      final vistas = AlertasVistasService.desdeDocumentos([
        (id: 'a', data: _datos(alertaId: 'p1-stockBajo')),
        (id: 'b', data: _datos(alertaId: 'p2-vencido')),
      ]);

      expect([for (final v in vistas) v.alertaId], ['p1-stockBajo', 'p2-vencido']);
    });

    test('un documento roto se saltea y no tira abajo a los demás', () {
      final vistas = AlertasVistasService.desdeDocumentos([
        (id: 'a', data: _datos(alertaId: 'p1-stockBajo')),
        (id: 'roto', data: {'usuarioId': 'u1'}),
        (id: 'b', data: _datos(alertaId: 'p2-vencido')),
      ]);

      expect([for (final v in vistas) v.alertaId], ['p1-stockBajo', 'p2-vencido']);
    });

    test('sin documentos no hay marcas', () {
      expect(AlertasVistasService.desdeDocumentos(const []), isEmpty);
    });
  });
}
