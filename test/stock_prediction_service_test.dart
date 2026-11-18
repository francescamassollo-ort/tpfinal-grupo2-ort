import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/movimiento_stock.dart';
import 'package:tpfinal_grupo2/models/prediccion_stock.dart';
import 'package:tpfinal_grupo2/services/stock_prediction_service.dart';

// Miércoles 18/11/2026, 12:00. La próxima compra es el 1/12: dentro de 13 días.
final _ahora = DateTime(2026, 11, 18, 12);

Insumo _insumo(String id, String nombre, {int stock = 10}) => Insumo(
      id: id,
      nombre: nombre,
      tipo: InsumoTipo.comprado,
      stock: stock,
      ubicacion: 'Estante 1',
      umbralMinimo: 2,
    );

// Un movimiento de [producto] ocurrido hace [diasAtras] días.
MovimientoStock _mov(
  String producto,
  TipoMovimiento tipo,
  int cantidad, {
  required int diasAtras,
}) {
  return MovimientoStock(
    id: '$producto-$tipo-$diasAtras-$cantidad',
    productoId: producto,
    usuarioId: 'u1',
    usuarioNombre: 'Juan Perez',
    tipo: tipo,
    cantidad: cantidad,
    fecha: _ahora.subtract(Duration(days: diasAtras)),
  );
}

List<PrediccionStock> _predecir(
  List<Insumo> insumos,
  List<MovimientoStock> movimientos, {
  int ventanaDias = 30,
}) {
  return StockPredictionService.predecir(
    insumos: insumos,
    movimientos: movimientos,
    ahora: _ahora,
    ventanaDias: ventanaDias,
  );
}

void main() {
  group('ritmo de consumo', () {
    test('reparte lo consumido sobre los días de la ventana', () {
      // Historial de 40 días: 30 unidades en los últimos 30 días = 1 por día.
      final resultado = _predecir(
        [_insumo('p1', 'Etanol', stock: 10)],
        [
          _mov('p1', TipoMovimiento.salida, 10, diasAtras: 40),
          _mov('p1', TipoMovimiento.salida, 12, diasAtras: 15),
          _mov('p1', TipoMovimiento.salida, 18, diasAtras: 2),
        ],
      );

      expect(resultado.single.consumoDiario, closeTo(30 / 30, 0.001));
      expect(resultado.single.diasRestantes, 10);
    });

    test('un insumo nuevo se mide solo sobre los días que lleva con historial',
        () {
      // Primer movimiento hace 10 días: 20 unidades en 10 días = 2 por día,
      // no 20 en 30 (que daría 0,67 y el triple de días de los reales).
      final resultado = _predecir(
        [_insumo('p1', 'Etanol', stock: 10)],
        [
          _mov('p1', TipoMovimiento.entrada, 50, diasAtras: 10),
          _mov('p1', TipoMovimiento.salida, 20, diasAtras: 5),
        ],
      );

      expect(resultado.single.consumoDiario, closeTo(2, 0.001));
      expect(resultado.single.diasRestantes, 5);
    });

    test('con muy poco historial se reparte sobre un mínimo de 7 días', () {
      // Un solo movimiento de hace un día: sin el piso sería 7 por día.
      final resultado = _predecir(
        [_insumo('p1', 'Etanol', stock: 14)],
        [_mov('p1', TipoMovimiento.salida, 7, diasAtras: 1)],
      );

      expect(resultado.single.consumoDiario, closeTo(1, 0.001));
      expect(resultado.single.diasRestantes, 14);
    });

    test('las salidas más viejas que la ventana no cuentan, pero sí '
        'cuentan como historial', () {
      final resultado = _predecir(
        [_insumo('p1', 'Etanol', stock: 10)],
        [
          _mov('p1', TipoMovimiento.salida, 100, diasAtras: 45),
          _mov('p1', TipoMovimiento.salida, 30, diasAtras: 3),
        ],
      );

      // Historial de 45 días (se acota a la ventana de 30): 30 / 30.
      expect(resultado.single.consumoDiario, closeTo(1, 0.001));
    });

    test('la ventana se puede ampliar', () {
      final movimientos = [
        _mov('p1', TipoMovimiento.salida, 60, diasAtras: 45),
        _mov('p1', TipoMovimiento.salida, 30, diasAtras: 3),
      ];
      final insumos = [_insumo('p1', 'Etanol')];

      expect(_predecir(insumos, movimientos).single.consumoDiario,
          closeTo(1, 0.001));
      // Con 60 días entran las dos salidas (90 unidades). El historial del
      // insumo es de 45 días, así que se reparten sobre 45 y no sobre 60.
      expect(
        _predecir(insumos, movimientos, ventanaDias: 60).single.consumoDiario,
        closeTo(2, 0.001),
      );
    });
  });

  group('qué cuenta como consumo', () {
    test('las entradas y los ajustes no cuentan', () {
      final resultado = _predecir(
        [_insumo('p1', 'Etanol')],
        [
          _mov('p1', TipoMovimiento.entrada, 100, diasAtras: 20),
          _mov('p1', TipoMovimiento.ajuste, -50, diasAtras: 10),
          _mov('p1', TipoMovimiento.salida, 10, diasAtras: 5),
        ],
      );

      // Solo la salida de 10, sobre 20 días de historial.
      expect(resultado.single.consumoDiario, closeTo(10 / 20, 0.001));
    });

    test('un insumo sin salidas no aparece', () {
      final resultado = _predecir(
        [_insumo('p1', 'Etanol')],
        [_mov('p1', TipoMovimiento.entrada, 100, diasAtras: 5)],
      );

      expect(resultado, isEmpty);
    });

    test('un insumo sin movimientos no aparece', () {
      expect(_predecir([_insumo('p1', 'Etanol')], const []), isEmpty);
    });

    test('las salidas de un insumo no se mezclan con las de otro', () {
      final resultado = _predecir(
        [_insumo('p1', 'Etanol'), _insumo('p2', 'Pipetas')],
        [
          _mov('p1', TipoMovimiento.salida, 7, diasAtras: 2),
          _mov('p2', TipoMovimiento.salida, 14, diasAtras: 2),
        ],
      );

      final porId = {for (final p in resultado) p.productoId: p};
      expect(porId['p1']!.consumoDiario, closeTo(1, 0.001));
      expect(porId['p2']!.consumoDiario, closeTo(2, 0.001));
    });

    test('los movimientos de un insumo que no está en la lista se ignoran', () {
      final resultado = _predecir(
        [_insumo('p1', 'Etanol')],
        [_mov('borrado', TipoMovimiento.salida, 50, diasAtras: 2)],
      );

      expect(resultado, isEmpty);
    });

    test('un movimiento con fecha futura (reloj desfasado) se ignora', () {
      final resultado = _predecir(
        [_insumo('p1', 'Etanol')],
        [_mov('p1', TipoMovimiento.salida, 50, diasAtras: -3)],
      );

      expect(resultado, isEmpty);
    });
  });

  group('días restantes', () {
    test('sin stock queda en cero días', () {
      final resultado = _predecir(
        [_insumo('p1', 'Etanol', stock: 0)],
        [_mov('p1', TipoMovimiento.salida, 7, diasAtras: 2)],
      );

      expect(resultado.single.diasRestantes, 0);
      expect(resultado.single.fechaAgotamiento, _ahora);
    });

    test('se cuentan solo los días completos', () {
      // 1 por día con 10,9 de stock no existe: 10 de stock y 3 por día = 3,33.
      final resultado = _predecir(
        [_insumo('p1', 'Etanol', stock: 10)],
        [_mov('p1', TipoMovimiento.salida, 21, diasAtras: 2)],
      );

      expect(resultado.single.consumoDiario, closeTo(3, 0.001));
      expect(resultado.single.diasRestantes, 3);
    });

    test('la fecha de agotamiento es hoy más los días restantes', () {
      final resultado = _predecir(
        [_insumo('p1', 'Etanol', stock: 10)],
        [_mov('p1', TipoMovimiento.salida, 14, diasAtras: 2)],
      );

      expect(resultado.single.diasRestantes, 5);
      expect(resultado.single.fechaAgotamiento, DateTime(2026, 11, 23, 12));
    });
  });

  group('orden', () {
    test('primero los que antes se agotan, y a igual plazo por nombre', () {
      final resultado = _predecir(
        [
          _insumo('a', 'Pipetas', stock: 10),
          _insumo('b', 'Etanol', stock: 10),
          _insumo('c', 'Agar', stock: 100),
          _insumo('d', 'Barbijo', stock: 10),
        ],
        [
          _mov('a', TipoMovimiento.salida, 7, diasAtras: 2),
          _mov('b', TipoMovimiento.salida, 7, diasAtras: 2),
          _mov('c', TipoMovimiento.salida, 7, diasAtras: 2),
          _mov('d', TipoMovimiento.salida, 14, diasAtras: 2),
        ],
      );

      expect(
        [for (final p in resultado) p.productoNombre],
        ['Barbijo', 'Etanol', 'Pipetas', 'Agar'],
      );
    });
  });

  group('próxima compra', () {
    test('se agota antes de la compra del 1/12 si no llega', () {
      // Quedan 13 días hasta el 1/12 (a las 0:00). Se agota en 5.
      final resultado = _predecir(
        [_insumo('p1', 'Etanol', stock: 10)],
        [_mov('p1', TipoMovimiento.salida, 14, diasAtras: 2)],
      );

      expect(resultado.single.seAgotaAntesDeLaCompra, isTrue);
    });

    test('no se agota antes si alcanza hasta la compra', () {
      // 1 por día con 20 de stock: se agota en 20 días, después del 1/12.
      final resultado = _predecir(
        [_insumo('p1', 'Etanol', stock: 20)],
        [_mov('p1', TipoMovimiento.salida, 7, diasAtras: 2)],
      );

      expect(resultado.single.diasRestantes, 20);
      expect(resultado.single.seAgotaAntesDeLaCompra, isFalse);
    });

    test('la fecha de compra se puede pasar a mano', () {
      final resultado = StockPredictionService.predecir(
        insumos: [_insumo('p1', 'Etanol', stock: 10)],
        movimientos: [_mov('p1', TipoMovimiento.salida, 14, diasAtras: 2)],
        ahora: _ahora,
        // Se agota el 23/11: una compra el 20/11 llega antes.
        proximaCompra: DateTime(2026, 11, 20),
      );

      expect(resultado.single.seAgotaAntesDeLaCompra, isFalse);
    });

    test('proximaVentanaDeCompra: de noviembre a diciembre', () {
      expect(
        StockPredictionService.proximaVentanaDeCompra(DateTime(2026, 11, 18)),
        DateTime(2026, 12, 1),
      );
    });

    test('proximaVentanaDeCompra: el día de la compra salta a la siguiente', () {
      expect(
        StockPredictionService.proximaVentanaDeCompra(DateTime(2026, 12, 1, 9)),
        DateTime(2027, 7, 1),
      );
      expect(
        StockPredictionService.proximaVentanaDeCompra(DateTime(2027, 7, 1)),
        DateTime(2027, 12, 1),
      );
    });

    test('proximaVentanaDeCompra: pasa de año', () {
      expect(
        StockPredictionService.proximaVentanaDeCompra(DateTime(2026, 12, 2)),
        DateTime(2027, 7, 1),
      );
      expect(
        StockPredictionService.proximaVentanaDeCompra(DateTime(2027, 1, 5)),
        DateTime(2027, 7, 1),
      );
      expect(
        StockPredictionService.proximaVentanaDeCompra(DateTime(2027, 6, 30)),
        DateTime(2027, 7, 1),
      );
    });
  });
}
