import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/alerta.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/services/alerta_service.dart';

Insumo _insumo(
  String id, {
  String? nombre,
  int stock = 20,
  num umbral = 5,
  DateTime? vencimiento,
  bool alarma = true,
}) {
  return Insumo(
    id: id,
    nombre: nombre ?? 'Insumo $id',
    tipo: InsumoTipo.comprado,
    stock: stock,
    ubicacion: 'Estante A',
    umbralMinimo: umbral,
    fechaVencimiento: vencimiento,
    alarmaVencimiento: alarma,
  );
}

List<TipoAlerta> _tipos(List<Alerta> alertas) =>
    alertas.map((a) => a.tipo).toList();

void main() {
  final hoy = DateTime.now();

  group('stock', () {
    test('sin alertas si el stock está por encima del umbral', () {
      expect(AlertaService.generar([_insumo('a', stock: 20, umbral: 5)]), isEmpty);
    });

    test('stock bajo cuando el stock está en el umbral', () {
      final alertas = AlertaService.generar([_insumo('a', stock: 5, umbral: 5)]);

      expect(_tipos(alertas), [TipoAlerta.stockBajo]);
    });

    test('stock bajo cuando el stock está por debajo del umbral', () {
      final alertas = AlertaService.generar([_insumo('a', stock: 2, umbral: 5)]);

      expect(_tipos(alertas), [TipoAlerta.stockBajo]);
    });

    test('sin stock cuando el stock es cero, y no además stock bajo', () {
      final alertas = AlertaService.generar([_insumo('a', stock: 0, umbral: 5)]);

      expect(_tipos(alertas), [TipoAlerta.sinStock]);
    });
  });

  group('vencimiento', () {
    test('vencimiento cercano si vence dentro de los próximos días', () {
      final alertas = AlertaService.generar([
        _insumo('a', vencimiento: hoy.add(const Duration(days: 10))),
      ]);

      expect(_tipos(alertas), [TipoAlerta.vencimientoCercano]);
    });

    test('vencido si la fecha ya pasó', () {
      final alertas = AlertaService.generar([
        _insumo('a', vencimiento: hoy.subtract(const Duration(days: 1))),
      ]);

      expect(_tipos(alertas), [TipoAlerta.vencido]);
    });

    test('sin alerta si vence más adelante del plazo', () {
      final alertas = AlertaService.generar([
        _insumo('a', vencimiento: hoy.add(const Duration(days: 200))),
      ]);

      expect(alertas, isEmpty);
    });

    test('sin alerta si la alarma de vencimiento está apagada', () {
      final alertas = AlertaService.generar([
        _insumo(
          'a',
          vencimiento: hoy.subtract(const Duration(days: 30)),
          alarma: false,
        ),
      ]);

      expect(alertas, isEmpty);
    });
  });

  group('combinaciones y orden', () {
    test('un insumo puede tener stock bajo y vencimiento cercano a la vez', () {
      final alertas = AlertaService.generar([
        _insumo(
          'a',
          stock: 2,
          umbral: 5,
          vencimiento: hoy.add(const Duration(days: 5)),
        ),
      ]);

      expect(
        _tipos(alertas),
        containsAll([TipoAlerta.stockBajo, TipoAlerta.vencimientoCercano]),
      );
      expect(alertas, hasLength(2));
    });

    test('las críticas van primero y después por nombre', () {
      final alertas = AlertaService.generar([
        _insumo('0', nombre: 'Aceite', vencimiento: hoy.add(const Duration(days: 5))),
        _insumo('1', nombre: 'Zinc', stock: 2, umbral: 5),
        _insumo('2', nombre: 'Agar', stock: 0),
        _insumo('3', nombre: 'Buffer', stock: 1, umbral: 5),
        _insumo('4', nombre: 'Etanol', vencimiento: hoy.subtract(const Duration(days: 2))),
      ]);

      // Aceite solo tiene vencimiento cercano (advertencia), por eso va
      // último aunque alfabéticamente sea el primero.
      expect(
        alertas.map((a) => a.productoNombre).toList(),
        ['Agar', 'Buffer', 'Etanol', 'Zinc', 'Aceite'],
      );
      expect(alertas.first.severidad, SeveridadAlerta.critica);
      expect(alertas.last.severidad, SeveridadAlerta.advertencia);
    });

    test('sin insumos no hay alertas', () {
      expect(AlertaService.generar(const []), isEmpty);
    });
  });

  group('Alerta', () {
    test('el id combina el insumo y el tipo', () {
      const alerta = Alerta(
        productoId: 'abc',
        productoNombre: 'Etanol',
        tipo: TipoAlerta.stockBajo,
      );

      expect(alerta.id, 'abc-stockBajo');
    });

    test('cada tipo tiene la severidad esperada', () {
      expect(TipoAlerta.sinStock.severidad, SeveridadAlerta.critica);
      expect(TipoAlerta.vencido.severidad, SeveridadAlerta.critica);
      expect(TipoAlerta.stockBajo.severidad, SeveridadAlerta.critica);
      expect(TipoAlerta.vencimientoCercano.severidad, SeveridadAlerta.advertencia);
    });
  });
}
