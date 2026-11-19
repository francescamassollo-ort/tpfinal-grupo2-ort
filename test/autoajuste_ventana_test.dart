import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/movimiento_stock.dart';
import 'package:tpfinal_grupo2/models/ventana_prediccion.dart';
import 'package:tpfinal_grupo2/services/stock_prediction_service.dart';

// Miércoles 18/11/2026, 12:00.
final _ahora = DateTime(2026, 11, 18, 12);

// Una salida de [cantidad] unidades de [producto] hace [diasAtras] días.
MovimientoStock _salida(String producto, int cantidad, int diasAtras) {
  return MovimientoStock(
    id: '$producto-salida-$diasAtras',
    productoId: producto,
    usuarioId: 'u1',
    usuarioNombre: 'Juan Perez',
    tipo: TipoMovimiento.salida,
    cantidad: cantidad,
    fecha: _ahora.subtract(Duration(days: diasAtras)),
  );
}

// Una salida de [porDia] unidades por día, desde hace [desde] días hasta hace
// [hasta] días, los dos incluidos.
List<MovimientoStock> _diarias(
  String producto,
  int porDia, {
  required int desde,
  int hasta = 0,
}) {
  return [
    for (var dias = desde; dias >= hasta; dias--) _salida(producto, porDia, dias),
  ];
}

VentanaPrediccion _elegir(List<MovimientoStock> movimientos) {
  return StockPredictionService.elegirVentana(
    movimientos: movimientos,
    ahora: _ahora,
  );
}

void main() {
  group('cuando no hay historial suficiente usa la ventana por defecto', () {
    test('sin movimientos', () {
      final v = _elegir(const []);

      expect(v.ventanaDias, 30);
      expect(v.elegidaPorHistorial, isFalse);
      expect(v.errorRelativoPorVentana, isEmpty);
      expect(v.evaluaciones, 0);
    });

    test('con muy pocos días de historial', () {
      final v = _elegir(_diarias('p1', 1, desde: 10));

      expect(v.ventanaDias, 30);
      expect(v.elegidaPorHistorial, isFalse);
    });

    test('con un solo insumo no alcanza para sacar una conclusión', () {
      // 4 momentos x 1 insumo = 4 comparaciones, menos que las 5 mínimas.
      final v = _elegir(_diarias('p1', 1, desde: 150));

      expect(v.evaluaciones, 4);
      expect(v.ventanaDias, 30);
      expect(v.elegidaPorHistorial, isFalse);
    });

    test('un insumo con poco historial no se evalúa en los momentos en que '
        'todavía no tenía', () {
      // p1 tiene 150 días; p2 recién empezó hace 20: en el corte más reciente
      // (hace 14 días) tenía solo 6 días de historial, menos de los 7 mínimos.
      final v = _elegir([
        ..._diarias('p1', 1, desde: 150),
        ..._diarias('p2', 1, desde: 20),
      ]);

      expect(v.evaluaciones, 4);
      expect(v.elegidaPorHistorial, isFalse);
    });

    test('sin consumo real contra el cual comparar', () {
      // Hubo salidas hace mucho, pero ninguna en los últimos 50 días.
      final v = _elegir([
        ..._diarias('p1', 1, desde: 150, hasta: 60),
        ..._diarias('p2', 1, desde: 150, hasta: 60),
      ]);

      expect(v.ventanaDias, 30);
      expect(v.elegidaPorHistorial, isFalse);
    });
  });

  group('cuando hay historial suficiente', () {
    test('con consumo parejo se queda en 30 y sin error', () {
      final v = _elegir([
        ..._diarias('p1', 1, desde: 150),
        ..._diarias('p2', 1, desde: 150),
      ]);

      expect(v.elegidaPorHistorial, isTrue);
      expect(v.evaluaciones, 8);
      expect(v.ventanaDias, 30);
      expect(v.errorRelativoPorVentana[30], closeTo(0, 0.001));
      expect(v.errorRelativoPorVentana[60], closeTo(0, 0.001));
    });

    test('cuando el consumo cambia de golpe, gana la ventana corta', () {
      // 10 por día hasta hace 40 días y 1 por día desde entonces: la ventana de
      // 30 días se adapta antes al cambio que la de 60.
      final v = _elegir([
        for (final p in ['p1', 'p2']) ...[
          ..._diarias(p, 10, desde: 150, hasta: 41),
          ..._diarias(p, 1, desde: 40),
        ],
      ]);

      expect(v.elegidaPorHistorial, isTrue);
      expect(v.ventanaDias, 30);
      expect(
        v.errorRelativoPorVentana[30]!,
        lessThan(v.errorRelativoPorVentana[60]!),
      );
    });

    test('cuando hay un pico aislado, gana la ventana larga', () {
      // 1 por día, más una salida única de 100 hace 40 días. La ventana de 30
      // días lo sobrevalora; la de 60 lo diluye y se equivoca menos.
      final v = _elegir([
        for (final p in ['p1', 'p2']) ...[
          ..._diarias(p, 1, desde: 150),
          _salida(p, 100, 40),
        ],
      ]);

      expect(v.elegidaPorHistorial, isTrue);
      expect(v.ventanaDias, 60);
      expect(
        v.errorRelativoPorVentana[60]!,
        lessThan(v.errorRelativoPorVentana[30]!),
      );
    });

    test('si la ventana por defecto ya acierta, no se cambia', () {
      // Un pico chico (2 unidades): la de 60 se equivoca menos, pero la de 30
      // ya acierta con error de menos del 10 %, así que se queda.
      final v = _elegir([
        for (final p in ['p1', 'p2']) ...[
          ..._diarias(p, 1, desde: 150),
          _salida(p, 2, 40),
        ],
      ]);

      expect(
        v.errorRelativoPorVentana[60]!,
        lessThan(v.errorRelativoPorVentana[30]!),
      );
      expect(v.errorRelativoPorVentana[30]!, lessThan(0.10));
      expect(v.ventanaDias, 30);
    });

    test('informa el error de cada ventana candidata', () {
      final v = _elegir([
        for (final p in ['p1', 'p2']) ...[
          ..._diarias(p, 1, desde: 150),
          _salida(p, 100, 40),
        ],
      ]);

      expect(v.errorRelativoPorVentana.keys, containsAll([30, 60]));
    });
  });

  group('qué movimientos cuentan', () {
    test('las entradas y los ajustes no cuentan como consumo', () {
      final ruido = [
        for (final p in ['p1', 'p2'])
          for (var dias = 150; dias >= 0; dias -= 5) ...[
            MovimientoStock(
              id: '$p-entrada-$dias',
              productoId: p,
              usuarioId: 'u1',
              usuarioNombre: 'Juan Perez',
              tipo: TipoMovimiento.entrada,
              cantidad: 500,
              fecha: _ahora.subtract(Duration(days: dias)),
            ),
            MovimientoStock(
              id: '$p-ajuste-$dias',
              productoId: p,
              usuarioId: 'u1',
              usuarioNombre: 'Juan Perez',
              tipo: TipoMovimiento.ajuste,
              cantidad: -300,
              fecha: _ahora.subtract(Duration(days: dias)),
            ),
          ],
      ];
      final base = [
        ..._diarias('p1', 1, desde: 150),
        ..._diarias('p2', 1, desde: 150),
      ];

      final sinRuido = _elegir(base);
      final conRuido = _elegir([...base, ...ruido]);

      expect(conRuido.ventanaDias, sinRuido.ventanaDias);
      expect(conRuido.errorRelativoPorVentana[30], closeTo(0, 0.001));
    });

    test('un movimiento con fecha futura (reloj desfasado) se ignora', () {
      final base = [
        ..._diarias('p1', 1, desde: 150),
        ..._diarias('p2', 1, desde: 150),
      ];

      final v = _elegir([...base, _salida('p1', 9999, -3)]);

      expect(v.ventanaDias, 30);
      expect(v.errorRelativoPorVentana[30], closeTo(0, 0.001));
    });
  });
}
