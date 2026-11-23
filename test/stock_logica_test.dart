import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/movimiento_stock.dart';
import 'package:tpfinal_grupo2/models/usuario_actual.dart';
import 'package:tpfinal_grupo2/services/stock_logica.dart';

const _ana = UsuarioActual(id: 'u1', nombre: 'Ana Pérez');
final _ahora = DateTime(2026, 11, 23, 10, 30);

CambioDeStock _entrada({int stock = 10, int cantidad = 5, String? motivo}) =>
    StockLogica.entrada(
      insumoId: 'p1',
      stockActual: stock,
      cantidad: cantidad,
      usuario: _ana,
      ahora: _ahora,
      motivo: motivo,
    );

CambioDeStock _salida({int stock = 10, int cantidad = 4, String? motivo}) =>
    StockLogica.salida(
      insumoId: 'p1',
      stockActual: stock,
      cantidad: cantidad,
      usuario: _ana,
      ahora: _ahora,
      motivo: motivo,
    );

CambioDeStock _ajuste({int stock = 10, int deseado = 7, String? motivo}) =>
    StockLogica.ajuste(
      insumoId: 'p1',
      stockActual: stock,
      stockDeseado: deseado,
      usuario: _ana,
      ahora: _ahora,
      motivo: motivo,
    );

Matcher _falla(String mensaje) => throwsA(
      isA<StockException>().having((e) => e.mensaje, 'mensaje', mensaje),
    );

void main() {
  group('entrada', () {
    test('suma la cantidad al stock', () {
      expect(_entrada(stock: 10, cantidad: 5).stockNuevo, 15);
    });

    test('se puede entrar stock a un insumo sin nada', () {
      expect(_entrada(stock: 0, cantidad: 3).stockNuevo, 3);
    });

    test('el movimiento guarda la cantidad positiva y quién lo hizo', () {
      final m = _entrada(cantidad: 5, motivo: 'Compra').movimiento;

      expect(m.tipo, TipoMovimiento.entrada);
      expect(m.cantidad, 5);
      expect(m.productoId, 'p1');
      expect(m.usuarioId, 'u1');
      expect(m.usuarioNombre, 'Ana Pérez');
      expect(m.fecha, _ahora);
      expect(m.motivo, 'Compra');
    });

    test('el id va vacío: lo asigna Firestore', () {
      expect(_entrada().movimiento.id, '');
    });

    test('una cantidad de 0 o negativa se rechaza', () {
      expect(() => _entrada(cantidad: 0), _falla('La cantidad debe ser mayor a 0'));
      expect(() => _entrada(cantidad: -2), _falla('La cantidad debe ser mayor a 0'));
    });
  });

  group('salida', () {
    test('resta la cantidad del stock', () {
      expect(_salida(stock: 10, cantidad: 4).stockNuevo, 6);
    });

    test('se puede sacar todo lo que hay', () {
      expect(_salida(stock: 10, cantidad: 10).stockNuevo, 0);
    });

    test('no se puede sacar más de lo que hay', () {
      expect(() => _salida(stock: 3, cantidad: 4), _falla('Stock insuficiente'));
    });

    test('sin stock no se puede sacar nada', () {
      expect(() => _salida(stock: 0, cantidad: 1), _falla('Stock insuficiente'));
    });

    test('el movimiento guarda la cantidad positiva, no con signo', () {
      final m = _salida(cantidad: 4, motivo: 'TP').movimiento;

      expect(m.tipo, TipoMovimiento.salida);
      expect(m.cantidad, 4);
      expect(m.motivo, 'TP');
    });

    test('una cantidad de 0 o negativa se rechaza', () {
      expect(() => _salida(cantidad: 0), _falla('La cantidad debe ser mayor a 0'));
      expect(() => _salida(cantidad: -1), _falla('La cantidad debe ser mayor a 0'));
    });
  });

  group('ajuste', () {
    test('deja el stock en la cantidad deseada', () {
      expect(_ajuste(stock: 10, deseado: 7).stockNuevo, 7);
    });

    test('si el stock baja, el movimiento guarda la diferencia negativa', () {
      final m = _ajuste(stock: 10, deseado: 7).movimiento;

      expect(m.tipo, TipoMovimiento.ajuste);
      expect(m.cantidad, -3);
    });

    test('si el stock sube, el movimiento guarda la diferencia positiva', () {
      final m = _ajuste(stock: 10, deseado: 14).movimiento;

      expect(m.cantidad, 4);
    });

    test('se puede dejar el stock en 0', () {
      final cambio = _ajuste(stock: 10, deseado: 0);

      expect(cambio.stockNuevo, 0);
      expect(cambio.movimiento.cantidad, -10);
    });

    test('un stock negativo se rechaza', () {
      expect(
        () => _ajuste(deseado: -1),
        _falla('El stock no puede ser negativo'),
      );
    });

    test('un ajuste que no cambia nada se rechaza', () {
      expect(() => _ajuste(stock: 10, deseado: 10), _falla('El stock ya es esa cantidad'));
    });
  });

  group('lo que ve el historial', () {
    test('la variación del movimiento es justo lo que cambió el stock', () {
      final casos = [
        (stock: 10, cambio: _entrada(stock: 10, cantidad: 5)),
        (stock: 10, cambio: _salida(stock: 10, cantidad: 4)),
        (stock: 10, cambio: _ajuste(stock: 10, deseado: 7)),
        (stock: 10, cambio: _ajuste(stock: 10, deseado: 25)),
      ];

      for (final caso in casos) {
        expect(
          caso.cambio.movimiento.variacion,
          caso.cambio.stockNuevo - caso.stock,
          reason: 'tipo ${caso.cambio.movimiento.tipo.name}',
        );
      }
    });

    test('un motivo vacío o de solo espacios queda sin motivo', () {
      expect(_entrada(motivo: '   ').movimiento.motivo, isNull);
      expect(_salida(motivo: '').movimiento.motivo, isNull);
      expect(_ajuste(motivo: null).movimiento.motivo, isNull);
    });

    test('el motivo se guarda sin los espacios de los extremos', () {
      expect(_salida(motivo: '  Trabajo práctico 3 ').movimiento.motivo,
          'Trabajo práctico 3');
    });

    test('sin sesión, el movimiento queda a nombre de "Sin sesión"', () {
      final cambio = StockLogica.salida(
        insumoId: 'p1',
        stockActual: 5,
        cantidad: 1,
        usuario: UsuarioActual.sinSesion,
        ahora: _ahora,
      );

      expect(cambio.movimiento.usuarioId, 'sin-sesion');
      expect(cambio.movimiento.usuarioNombre, 'Sin sesión');
    });
  });

  group('varias salidas a la vez', () {
    List<CambioDeStock> salidas(
      List<LineaDeSalida> lineas, {
      Map<String, int> stocks = const {'a': 10, 'b': 5, 'c': 1},
      String? motivo = 'TP 3',
    }) =>
        StockLogica.salidas(
          lineas: lineas,
          stocks: stocks,
          usuario: _ana,
          ahora: _ahora,
          motivo: motivo,
        );

    Matcher fallaEn(String insumoId, String mensaje) => throwsA(
          isA<StockException>()
              .having((e) => e.insumoId, 'insumoId', insumoId)
              .having((e) => e.mensaje, 'mensaje', mensaje),
        );

    test('resta cada línea de su insumo y devuelve un cambio por línea', () {
      final cambios = salidas([
        (insumoId: 'a', cantidad: 4),
        (insumoId: 'b', cantidad: 5),
      ]);

      expect(cambios, hasLength(2));
      expect(cambios[0].stockNuevo, 6);
      expect(cambios[1].stockNuevo, 0);
    });

    test('cada línea deja su movimiento de salida, en el mismo orden', () {
      final cambios = salidas([
        (insumoId: 'a', cantidad: 4),
        (insumoId: 'b', cantidad: 2),
      ]);

      expect(cambios[0].movimiento.productoId, 'a');
      expect(cambios[0].movimiento.cantidad, 4);
      expect(cambios[1].movimiento.productoId, 'b');
      expect(cambios[1].movimiento.cantidad, 2);
      for (final cambio in cambios) {
        expect(cambio.movimiento.tipo, TipoMovimiento.salida);
        expect(cambio.movimiento.motivo, 'TP 3');
        expect(cambio.movimiento.usuarioNombre, 'Ana Pérez');
        expect(cambio.movimiento.fecha, _ahora);
      }
    });

    test('si una línea no tiene stock suficiente, falla diciendo cuál', () {
      expect(
        () => salidas([
          (insumoId: 'a', cantidad: 4),
          (insumoId: 'b', cantidad: 6),
        ]),
        fallaEn('b', 'Stock insuficiente'),
      );
    });

    test('todo o nada: una línea mala no deja cambios de las buenas', () {
      // La función no devuelve nada si falla: no hay cambios que aplicar.
      List<CambioDeStock>? resultado;
      try {
        resultado = salidas([
          (insumoId: 'a', cantidad: 1),
          (insumoId: 'c', cantidad: 2),
        ]);
      } on StockException {
        // Se esperaba.
      }

      expect(resultado, isNull);
    });

    test('un insumo que no existe falla diciendo cuál', () {
      expect(
        () => salidas([(insumoId: 'zzz', cantidad: 1)]),
        fallaEn('zzz', 'Insumo no encontrado'),
      );
    });

    test('una cantidad de 0 o negativa falla diciendo cuál', () {
      expect(
        () => salidas([(insumoId: 'a', cantidad: 0)]),
        fallaEn('a', 'La cantidad debe ser mayor a 0'),
      );
      expect(
        () => salidas([(insumoId: 'a', cantidad: -2)]),
        fallaEn('a', 'La cantidad debe ser mayor a 0'),
      );
    });

    test('sin líneas no hay nada que retirar', () {
      expect(
        () => salidas([]),
        throwsA(
          isA<StockException>()
              .having((e) => e.mensaje, 'mensaje', 'No hay insumos para retirar')
              .having((e) => e.insumoId, 'insumoId', isNull),
        ),
      );
    });

    test('el mismo insumo en dos líneas se rechaza', () {
      // Cada línea por separado cabría en el stock, pero juntas no.
      expect(
        () => salidas([
          (insumoId: 'a', cantidad: 6),
          (insumoId: 'a', cantidad: 6),
        ]),
        fallaEn('a', 'El mismo insumo está más de una vez'),
      );
    });

    test('un motivo vacío queda sin motivo en todos los movimientos', () {
      final cambios = salidas(
        [(insumoId: 'a', cantidad: 1), (insumoId: 'b', cantidad: 1)],
        motivo: '  ',
      );

      expect(cambios.map((c) => c.movimiento.motivo), [null, null]);
    });
  });

  group('alta de un insumo', () {
    MovimientoStock? alta({int stock = 12, UsuarioActual usuario = _ana}) =>
        StockLogica.altaDeInsumo(
          insumoId: 'nuevo-1',
          stockInicial: stock,
          usuario: usuario,
          ahora: _ahora,
        );

    test('deja una entrada por todo el stock inicial', () {
      final m = alta(stock: 12)!;

      expect(m.tipo, TipoMovimiento.entrada);
      expect(m.cantidad, 12);
      expect(m.productoId, 'nuevo-1');
      expect(m.fecha, _ahora);
    });

    test('queda con el motivo "Alta de insumo" y a nombre de quien lo creó', () {
      final m = alta()!;

      expect(m.motivo, 'Alta de insumo');
      expect(m.usuarioId, 'u1');
      expect(m.usuarioNombre, 'Ana Pérez');
    });

    test('si el stock inicial es 0 no hay movimiento', () {
      expect(alta(stock: 0), isNull);
    });

    test('un stock inicial negativo se rechaza', () {
      expect(
        () => alta(stock: -3),
        _falla('El stock no puede ser negativo'),
      );
    });

    test('el movimiento del alta suma justo el stock inicial al historial', () {
      expect(alta(stock: 12)!.variacion, 12);
    });

    test('sin sesión queda a nombre de "Sin sesión"', () {
      final m = alta(usuario: UsuarioActual.sinSesion)!;

      expect(m.usuarioId, 'sin-sesion');
      expect(m.usuarioNombre, 'Sin sesión');
    });
  });

  test('la excepción se muestra con su mensaje, sin el prefijo "Exception"', () {
    expect(const StockException('Stock insuficiente').toString(), 'Stock insuficiente');
  });
}
