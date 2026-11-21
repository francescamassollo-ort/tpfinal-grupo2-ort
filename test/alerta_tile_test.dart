import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/alerta.dart';
import 'package:tpfinal_grupo2/screens/alertas/alerta_tile.dart';

Alerta _alerta(TipoAlerta tipo, {DateTime? fecha, String? tp}) {
  return Alerta(
    productoId: 'p1',
    productoNombre: 'Etanol',
    tipo: tipo,
    fecha: fecha,
    trabajoPractico: tp,
  );
}

Widget _envuelto(Alerta alerta) {
  return MaterialApp(
    home: Scaffold(body: AlertaTile(alerta: alerta)),
  );
}

void main() {
  group('texto de la alerta', () {
    test('las alertas de siempre mantienen su texto', () {
      expect(AlertaTile.descripcion(_alerta(TipoAlerta.sinStock)), 'Sin stock');
      expect(
        AlertaTile.descripcion(_alerta(TipoAlerta.stockBajo)),
        'Stock bajo',
      );
      expect(
        AlertaTile.descripcion(_alerta(TipoAlerta.vencimientoCercano)),
        'Vencimiento cercano',
      );
      expect(AlertaTile.descripcion(_alerta(TipoAlerta.vencido)), 'Vencido');
    });

    test('agotamiento próximo dice el día en que se agota', () {
      final alerta = _alerta(
        TipoAlerta.agotamientoProximo,
        fecha: DateTime(2026, 12, 3),
      );

      expect(
        AlertaTile.descripcion(alerta),
        'Se agotaría el 03/12, antes de la próxima compra',
      );
    });

    test('agotamiento próximo sin fecha no muestra un texto cortado', () {
      expect(
        AlertaTile.descripcion(_alerta(TipoAlerta.agotamientoProximo)),
        'Se agotaría antes de la próxima compra',
      );
    });

    test('TP sin cobertura dice cuál y para cuándo', () {
      final alerta = _alerta(
        TipoAlerta.tpSinCobertura,
        fecha: DateTime(2026, 11, 20),
        tp: 'Química 3',
      );

      expect(AlertaTile.descripcion(alerta), 'No alcanza para Química 3 (20/11)');
    });

    test('TP sin cobertura con datos incompletos usa el texto general', () {
      final sinFecha = _alerta(TipoAlerta.tpSinCobertura, tp: 'Química 3');
      final sinNombre = _alerta(
        TipoAlerta.tpSinCobertura,
        fecha: DateTime(2026, 11, 20),
      );

      expect(
        AlertaTile.descripcion(sinFecha),
        'No alcanza para un trabajo práctico',
      );
      expect(
        AlertaTile.descripcion(sinNombre),
        'No alcanza para un trabajo práctico',
      );
    });
  });

  group('severidad', () {
    test('las alertas de predicción son advertencia, no críticas', () {
      expect(TipoAlerta.agotamientoProximo.severidad, SeveridadAlerta.advertencia);
      expect(TipoAlerta.tpSinCobertura.severidad, SeveridadAlerta.advertencia);
    });

    test('un insumo puede tener una alerta de cada tipo de predicción', () {
      final a = _alerta(TipoAlerta.agotamientoProximo);
      final b = _alerta(TipoAlerta.tpSinCobertura);

      expect(a.id, isNot(b.id));
    });

    test('dos alertas con distinta fecha no son iguales', () {
      final a = _alerta(TipoAlerta.agotamientoProximo, fecha: DateTime(2026, 12, 1));
      final b = _alerta(TipoAlerta.agotamientoProximo, fecha: DateTime(2026, 12, 2));

      expect(a, isNot(b));
      expect(a, _alerta(TipoAlerta.agotamientoProximo, fecha: DateTime(2026, 12, 1)));
    });
  });

  group('la fila', () {
    testWidgets('muestra el nombre del insumo y el texto de la alerta', (tester) async {
      await tester.pumpWidget(
        _envuelto(
          _alerta(
            TipoAlerta.tpSinCobertura,
            fecha: DateTime(2026, 11, 20),
            tp: 'Química 3',
          ),
        ),
      );

      expect(find.text('Etanol'), findsOneWidget);
      expect(find.text('No alcanza para Química 3 (20/11)'), findsOneWidget);
    });

    testWidgets('las de predicción usan el color de advertencia', (tester) async {
      await tester.pumpWidget(
        _envuelto(
          _alerta(TipoAlerta.agotamientoProximo, fecha: DateTime(2026, 12, 3)),
        ),
      );

      expect(find.bySemanticsLabel('Advertencia'), findsOneWidget);
      expect(find.bySemanticsLabel('Alerta crítica'), findsNothing);
    });
  });
}
