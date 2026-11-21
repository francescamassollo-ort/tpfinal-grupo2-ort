import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/movimiento_stock.dart';
import 'package:tpfinal_grupo2/screens/historial/historial_items.dart';

// Miércoles 17/11/2026, 15:00.
final _ahora = DateTime(2026, 11, 17, 15);

Insumo _insumo(String id, String nombre) => Insumo(
      id: id,
      nombre: nombre,
      tipo: InsumoTipo.comprado,
      stock: 10,
      ubicacion: 'Estante 1',
      umbralMinimo: 2,
    );

MovimientoStock _mov(
  String id, {
  String producto = 'p1',
  TipoMovimiento tipo = TipoMovimiento.entrada,
  int cantidad = 5,
  DateTime? fecha,
}) {
  return MovimientoStock(
    id: id,
    productoId: producto,
    usuarioId: 'u1',
    usuarioNombre: 'Juan Perez',
    tipo: tipo,
    cantidad: cantidad,
    fecha: fecha ?? DateTime(2026, 11, 17, 14, 32),
  );
}

void main() {
  group('HistorialItems.etiquetaFecha', () {
    test('un movimiento de hoy dice "Hoy" y la hora', () {
      expect(
        HistorialItems.etiquetaFecha(DateTime(2026, 11, 17, 14, 32), _ahora),
        'Hoy 14:32',
      );
    });

    test('un movimiento de ayer dice "Ayer" y la hora', () {
      expect(
        HistorialItems.etiquetaFecha(DateTime(2026, 11, 16, 16, 40), _ahora),
        'Ayer 16:40',
      );
    });

    test('antes de ayer muestra día/mes y la hora, con ceros a la izquierda', () {
      expect(
        HistorialItems.etiquetaFecha(DateTime(2026, 9, 2, 9, 2), _ahora),
        '02/09 09:02',
      );
    });

    test('de otro año muestra también el año con dos cifras', () {
      expect(
        HistorialItems.etiquetaFecha(DateTime(2025, 12, 31, 23, 59), _ahora),
        '31/12/25 23:59',
      );
    });

    test('ayer se calcula por día calendario, no por 24 horas', () {
      final ahora = DateTime(2026, 11, 17, 0, 5);

      expect(
        HistorialItems.etiquetaFecha(DateTime(2026, 11, 16, 23, 50), ahora),
        'Ayer 23:50',
      );
    });

    test('ayer cruza el cambio de mes', () {
      final ahora = DateTime(2026, 12, 1, 10);

      expect(
        HistorialItems.etiquetaFecha(DateTime(2026, 11, 30, 18, 0), ahora),
        'Ayer 18:00',
      );
    });

    test('una fecha futura (reloj desfasado) no dice "Hoy" ni "Ayer"', () {
      expect(
        HistorialItems.etiquetaFecha(DateTime(2026, 11, 20, 8, 0), _ahora),
        '20/11 08:00',
      );
    });
  });

  group('HistorialItems.armar', () {
    final insumos = [_insumo('p1', 'Etanol 96'), _insumo('p2', 'Pipetas')];

    test('cruza cada movimiento con el nombre de su insumo', () {
      final items = HistorialItems.armar(
        movimientos: [_mov('a', producto: 'p2')],
        insumos: insumos,
        ahora: _ahora,
      );

      expect(items.single.elementoNombre, 'Pipetas');
      expect(items.single.usuarioNombre, 'Juan Perez');
      expect(items.single.fechaEtiqueta, 'Hoy 14:32');
    });

    test('la variación sale del tipo: entrada suma, salida resta', () {
      final items = HistorialItems.armar(
        movimientos: [
          _mov('a', tipo: TipoMovimiento.entrada, cantidad: 19),
          _mov('b', tipo: TipoMovimiento.salida, cantidad: 10),
          _mov('c', tipo: TipoMovimiento.ajuste, cantidad: -3),
        ],
        insumos: insumos,
        ahora: _ahora,
      );

      expect([for (final i in items) i.delta], [19, -10, -3]);
      expect([for (final i in items) i.deltaTexto], ['+19', '-10', '-3']);
    });

    test('solo las entradas van destacadas', () {
      final items = HistorialItems.armar(
        movimientos: [
          _mov('a', tipo: TipoMovimiento.entrada),
          _mov('b', tipo: TipoMovimiento.salida),
        ],
        insumos: insumos,
        ahora: _ahora,
      );

      expect([for (final i in items) i.destacado], [true, false]);
    });

    test('mantiene el orden que traen los movimientos', () {
      final items = HistorialItems.armar(
        movimientos: [_mov('c'), _mov('a'), _mov('b')],
        insumos: insumos,
        ahora: _ahora,
      );

      expect([for (final i in items) i.id], ['c', 'a', 'b']);
    });

    test('si el insumo ya no existe, el movimiento se muestra igual', () {
      final items = HistorialItems.armar(
        movimientos: [_mov('a', producto: 'borrado')],
        insumos: insumos,
        ahora: _ahora,
      );

      expect(items, hasLength(1));
      expect(items.single.elementoNombre, 'Insumo eliminado');
    });

    test('sin movimientos devuelve una lista vacía', () {
      expect(
        HistorialItems.armar(movimientos: const [], insumos: insumos, ahora: _ahora),
        isEmpty,
      );
    });
  });
}
