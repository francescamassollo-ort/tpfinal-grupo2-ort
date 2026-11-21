import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/movimiento_stock.dart';

MovimientoStock _movimiento({
  TipoMovimiento tipo = TipoMovimiento.entrada,
  int cantidad = 10,
  String? motivo,
}) {
  return MovimientoStock(
    id: 'm1',
    productoId: 'insumo1',
    usuarioId: 'u1',
    usuarioNombre: 'Juan Perez',
    tipo: tipo,
    cantidad: cantidad,
    fecha: DateTime(2026, 11, 17, 14, 32),
    motivo: motivo,
  );
}

void main() {
  group('variacion', () {
    test('una entrada suma', () {
      expect(_movimiento(tipo: TipoMovimiento.entrada, cantidad: 19).variacion, 19);
    });

    test('una salida resta, aunque la cantidad se guarde positiva', () {
      expect(_movimiento(tipo: TipoMovimiento.salida, cantidad: 10).variacion, -10);
    });

    test('un ajuste positivo suma', () {
      expect(_movimiento(tipo: TipoMovimiento.ajuste, cantidad: 3).variacion, 3);
    });

    test('un ajuste negativo resta', () {
      expect(_movimiento(tipo: TipoMovimiento.ajuste, cantidad: -4).variacion, -4);
    });

    test('una entrada guardada con signo negativo no invierte el sentido', () {
      expect(_movimiento(tipo: TipoMovimiento.entrada, cantidad: -5).variacion, 5);
    });

    test('una salida guardada con signo negativo sigue restando', () {
      expect(_movimiento(tipo: TipoMovimiento.salida, cantidad: -5).variacion, -5);
    });
  });

  group('toMap y fromMap', () {
    test('ida y vuelta devuelve el mismo movimiento', () {
      final original = _movimiento(
        tipo: TipoMovimiento.salida,
        motivo: 'Trabajo práctico 3',
      );

      final copia = MovimientoStock.fromMap('m1', original.toMap());

      expect(copia, original);
    });

    test('toMap no incluye el id y guarda el tipo por su nombre', () {
      final mapa = _movimiento(tipo: TipoMovimiento.ajuste).toMap();

      expect(mapa.containsKey('id'), isFalse);
      expect(mapa['tipo'], 'ajuste');
      expect(mapa['fecha'], isA<Timestamp>());
    });

    test('el motivo es opcional', () {
      final mapa = _movimiento().toMap()..remove('motivo');

      expect(MovimientoStock.fromMap('m1', mapa).motivo, isNull);
    });

    test('un tipo desconocido lanza una excepción', () {
      final mapa = _movimiento().toMap()..['tipo'] = 'devolucion';

      expect(() => MovimientoStock.fromMap('m1', mapa), throwsArgumentError);
    });

    test('un documento sin la cantidad lanza una excepción', () {
      final mapa = _movimiento().toMap()..remove('cantidad');

      expect(() => MovimientoStock.fromMap('m1', mapa), throwsA(isA<TypeError>()));
    });
  });

  group('igualdad', () {
    test('dos movimientos con los mismos datos son iguales', () {
      expect(_movimiento(), _movimiento());
      expect(_movimiento().hashCode, _movimiento().hashCode);
    });

    test('cambiar un dato los hace distintos', () {
      expect(_movimiento(cantidad: 10), isNot(_movimiento(cantidad: 11)));
    });
  });
}
