import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/alerta.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/prediccion_stock.dart';
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

  group('predicción de stock', () {
    final agotamiento = DateTime(2026, 12, 3);
    final fechaTp = DateTime(2026, 11, 25);

    PrediccionStock prediccion(
      String id, {
      String? nombre,
      int stock = 10,
      bool seAgota = false,
      TpSinCobertura? tp,
    }) {
      return PrediccionStock(
        productoId: id,
        productoNombre: nombre ?? 'Insumo $id',
        stock: stock,
        consumoDiario: 1,
        diasRestantes: stock,
        fechaAgotamiento: agotamiento,
        seAgotaAntesDeLaCompra: seAgota,
        primerTpSinCobertura: tp,
      );
    }

    test('sin predicciones todo sigue igual', () {
      expect(AlertaService.generar(const [], predicciones: const []), isEmpty);
    });

    test('una predicción sin riesgo no genera alertas', () {
      final alertas = AlertaService.generar(
        const [],
        predicciones: [prediccion('a')],
      );

      expect(alertas, isEmpty);
    });

    test('se agota antes de la compra: alerta con el día en que se agota', () {
      final alertas = AlertaService.generar(
        const [],
        predicciones: [prediccion('a', seAgota: true)],
      );

      expect(alertas, hasLength(1));
      expect(alertas.single.tipo, TipoAlerta.agotamientoProximo);
      expect(alertas.single.fecha, agotamiento);
      expect(alertas.single.productoId, 'a');
    });

    test('no alcanza para un TP: alerta con el nombre y la fecha del TP', () {
      final alertas = AlertaService.generar(
        const [],
        predicciones: [
          prediccion(
            'a',
            tp: TpSinCobertura(nombre: 'Química 3', fecha: fechaTp),
          ),
        ],
      );

      expect(alertas, hasLength(1));
      expect(alertas.single.tipo, TipoAlerta.tpSinCobertura);
      expect(alertas.single.trabajoPractico, 'Química 3');
      expect(alertas.single.fecha, fechaTp);
    });

    test('un insumo con los dos motivos genera dos alertas', () {
      final alertas = AlertaService.generar(
        const [],
        predicciones: [
          prediccion(
            'a',
            seAgota: true,
            tp: TpSinCobertura(nombre: 'Química 3', fecha: fechaTp),
          ),
        ],
      );

      expect(_tipos(alertas), [
        TipoAlerta.agotamientoProximo,
        TipoAlerta.tpSinCobertura,
      ]);
      expect(alertas.map((a) => a.id).toSet(), hasLength(2));
    });

    test('sin stock no repite "se agotaría": ya dice "sin stock"', () {
      final alertas = AlertaService.generar(
        [_insumo('a', stock: 0)],
        predicciones: [prediccion('a', stock: 0, seAgota: true)],
      );

      expect(_tipos(alertas), [TipoAlerta.sinStock]);
    });

    test('sin stock el aviso del TP se mantiene', () {
      final alertas = AlertaService.generar(
        [_insumo('a', stock: 0)],
        predicciones: [
          prediccion(
            'a',
            stock: 0,
            seAgota: true,
            tp: TpSinCobertura(nombre: 'Química 3', fecha: fechaTp),
          ),
        ],
      );

      expect(_tipos(alertas), [
        TipoAlerta.sinStock,
        TipoAlerta.tpSinCobertura,
      ]);
    });

    test('con stock bajo se avisa también que se agota', () {
      final alertas = AlertaService.generar(
        [_insumo('a', stock: 3, umbral: 5)],
        predicciones: [prediccion('a', stock: 3, seAgota: true)],
      );

      expect(_tipos(alertas), [
        TipoAlerta.stockBajo,
        TipoAlerta.agotamientoProximo,
      ]);
    });

    test('las de predicción van después de las críticas, por nombre', () {
      final alertas = AlertaService.generar(
        [
          _insumo('v', nombre: 'Vencido', vencimiento: hoy.subtract(const Duration(days: 1))),
          _insumo('s', nombre: 'Sin stock', stock: 0),
        ],
        predicciones: [
          prediccion('z', nombre: 'Zinc', seAgota: true),
          prediccion('b', nombre: 'Benceno', seAgota: true),
        ],
      );

      expect(alertas.map((a) => a.productoNombre).toList(), [
        'Sin stock',
        'Vencido',
        'Benceno',
        'Zinc',
      ]);
      expect(alertas.first.severidad, SeveridadAlerta.critica);
      expect(alertas.last.severidad, SeveridadAlerta.advertencia);
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
