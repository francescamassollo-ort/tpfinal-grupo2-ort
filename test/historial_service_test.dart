import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/filtro_historial.dart';
import 'package:tpfinal_grupo2/models/movimiento_stock.dart';
import 'package:tpfinal_grupo2/services/historial_service.dart';

MovimientoStock _mov(
  String id, {
  String producto = 'p1',
  String usuario = 'u1',
  TipoMovimiento tipo = TipoMovimiento.entrada,
  DateTime? fecha,
}) {
  return MovimientoStock(
    id: id,
    productoId: producto,
    usuarioId: usuario,
    usuarioNombre: 'Persona $usuario',
    tipo: tipo,
    cantidad: 5,
    fecha: fecha ?? DateTime(2026, 11, 10, 12),
  );
}

List<String> _ids(List<MovimientoStock> lista) => [for (final m in lista) m.id];

void main() {
  group('FiltroHistorial', () {
    final movimientos = [
      _mov('a', producto: 'p1', usuario: 'u1', tipo: TipoMovimiento.entrada),
      _mov('b', producto: 'p2', usuario: 'u1', tipo: TipoMovimiento.salida),
      _mov('c', producto: 'p1', usuario: 'u2', tipo: TipoMovimiento.ajuste),
    ];

    test('un filtro vacío deja pasar todo, en el mismo orden', () {
      const filtro = FiltroHistorial();

      expect(filtro.estaVacio, isTrue);
      expect(_ids(filtro.aplicar(movimientos)), ['a', 'b', 'c']);
    });

    test('por insumo', () {
      const filtro = FiltroHistorial(productoId: 'p1');

      expect(_ids(filtro.aplicar(movimientos)), ['a', 'c']);
    });

    test('por persona', () {
      const filtro = FiltroHistorial(usuarioId: 'u1');

      expect(_ids(filtro.aplicar(movimientos)), ['a', 'b']);
    });

    test('por tipo', () {
      const filtro = FiltroHistorial(tipo: TipoMovimiento.salida);

      expect(_ids(filtro.aplicar(movimientos)), ['b']);
    });

    test('los filtros se combinan: tienen que cumplirse todos', () {
      const filtro = FiltroHistorial(productoId: 'p1', usuarioId: 'u2');

      expect(_ids(filtro.aplicar(movimientos)), ['c']);
    });

    test('un filtro que no coincide con nada devuelve una lista vacía', () {
      const filtro = FiltroHistorial(productoId: 'no-existe');

      expect(filtro.aplicar(movimientos), isEmpty);
    });

    test('un filtro con valores no está vacío', () {
      expect(const FiltroHistorial(tipo: TipoMovimiento.entrada).estaVacio, isFalse);
    });
  });

  group('FiltroHistorial por fechas', () {
    final movimientos = [
      _mov('madrugada', fecha: DateTime(2026, 11, 10, 0, 0)),
      _mov('tarde', fecha: DateTime(2026, 11, 10, 18, 30)),
      _mov('casi-medianoche', fecha: DateTime(2026, 11, 10, 23, 59, 59)),
      _mov('dia-siguiente', fecha: DateTime(2026, 11, 11, 0, 0)),
      _mov('dia-anterior', fecha: DateTime(2026, 11, 9, 23, 59)),
    ];

    test('desde cuenta el día completo, desde la medianoche', () {
      final filtro = FiltroHistorial(desde: DateTime(2026, 11, 10, 15));

      expect(
        _ids(filtro.aplicar(movimientos)),
        ['madrugada', 'tarde', 'casi-medianoche', 'dia-siguiente'],
      );
    });

    test('hasta cuenta el día completo, hasta las 23:59', () {
      final filtro = FiltroHistorial(hasta: DateTime(2026, 11, 10, 8));

      expect(
        _ids(filtro.aplicar(movimientos)),
        ['madrugada', 'tarde', 'casi-medianoche', 'dia-anterior'],
      );
    });

    test('un solo día: desde y hasta iguales', () {
      final dia = DateTime(2026, 11, 10);
      final filtro = FiltroHistorial(desde: dia, hasta: dia);

      expect(
        _ids(filtro.aplicar(movimientos)),
        ['madrugada', 'tarde', 'casi-medianoche'],
      );
    });
  });

  group('HistorialService.desdeDocumentos', () {
    Map<String, dynamic> datos({String tipo = 'entrada'}) => {
          'productoId': 'p1',
          'usuarioId': 'u1',
          'usuarioNombre': 'Juan Perez',
          'tipo': tipo,
          'cantidad': 4,
          'fecha': Timestamp.fromDate(DateTime(2026, 11, 10)),
        };

    test('convierte los documentos y conserva el orden', () {
      final lista = HistorialService.desdeDocumentos([
        (id: 'x', data: datos()),
        (id: 'y', data: datos(tipo: 'salida')),
      ]);

      expect(_ids(lista), ['x', 'y']);
      expect(lista[1].tipo, TipoMovimiento.salida);
    });

    test('un documento roto se saltea y no afecta a los demás', () {
      final lista = HistorialService.desdeDocumentos([
        (id: 'ok1', data: datos()),
        (id: 'roto', data: datos(tipo: 'devolucion')),
        (id: 'vacio', data: <String, dynamic>{}),
        (id: 'ok2', data: datos()),
      ]);

      expect(_ids(lista), ['ok1', 'ok2']);
    });

    test('sin documentos devuelve una lista vacía', () {
      expect(HistorialService.desdeDocumentos(const []), isEmpty);
    });
  });
}
