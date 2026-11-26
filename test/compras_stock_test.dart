import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/lista_compra.dart';
import 'package:tpfinal_grupo2/providers/lista_compra_provider.dart';
import 'package:tpfinal_grupo2/providers/stock_provider.dart';
import 'package:tpfinal_grupo2/services/lista_compra_service.dart';
import 'package:tpfinal_grupo2/services/stock_service.dart';

/// Lista de compras falsa: tiene un solo ítem y anota qué se le pidió.
class _ListaFalsa implements ListaCompraService {
  _ListaFalsa(this.item);

  final ListaCompra? item;
  final estadosDirectos = <(String, EstadoCompra)>[];

  @override
  Future<ListaCompra?> obtener(String id) async => item;

  @override
  Future<void> actualizarEstado(String id, EstadoCompra estado) async {
    estadosDirectos.add((id, estado));
  }

  @override
  void actualizarEstadoEn(
    Transaction transaccion,
    String id,
    EstadoCompra estado,
  ) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Servicio de stock falso: anota las entradas y salidas, sin tocar Firestore.
class _StockFalso implements StockService {
  final movimientos = <(String tipo, String insumoId, int cantidad, String motivo)>[];

  @override
  Future<void> registrarEntrada(
    String insumoId,
    int cantidad,
    String motivo, {
    void Function(Transaction transaccion)? junto,
  }) async {
    movimientos.add(('entrada', insumoId, cantidad, motivo));
  }

  @override
  Future<void> registrarSalida(
    String insumoId,
    int cantidad,
    String motivo, {
    void Function(Transaction transaccion)? junto,
  }) async {
    movimientos.add(('salida', insumoId, cantidad, motivo));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ListaCompra _item(EstadoCompra estado) => ListaCompra(
      id: 'c1',
      productoId: 'insumo-9',
      cantidadSugerida: 4,
      cantidadSolicitada: 12,
      generadaEn: DateTime(2026, 11, 1),
      estado: estado,
    );

ProviderContainer _contenedor(_ListaFalsa lista, _StockFalso stock) {
  final container = ProviderContainer(
    overrides: [
      listaCompraServiceProvider.overrideWithValue(lista),
      stockServiceProvider.overrideWithValue(stock),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('marcar como comprado suma la cantidad pedida al stock', () async {
    final lista = _ListaFalsa(_item(EstadoCompra.pendiente));
    final stock = _StockFalso();

    await _contenedor(lista, stock)
        .read(comprasAccionesProvider)
        .cambiarEstado('c1', EstadoCompra.comprado);

    expect(stock.movimientos, [
      ('entrada', 'insumo-9', 12, 'Compra (lista de compras)'),
    ]);
    // El estado lo guarda la misma transacción del stock, no una escritura aparte.
    expect(lista.estadosDirectos, isEmpty);
  });

  test('deshacer una compra resta lo que se había sumado', () async {
    final lista = _ListaFalsa(_item(EstadoCompra.comprado));
    final stock = _StockFalso();

    await _contenedor(lista, stock)
        .read(comprasAccionesProvider)
        .cambiarEstado('c1', EstadoCompra.pendiente);

    expect(stock.movimientos, [
      ('salida', 'insumo-9', 12, 'Compra deshecha (lista de compras)'),
    ]);
    expect(lista.estadosDirectos, isEmpty);
  });

  test('descartar no toca el stock', () async {
    final lista = _ListaFalsa(_item(EstadoCompra.pendiente));
    final stock = _StockFalso();

    await _contenedor(lista, stock)
        .read(comprasAccionesProvider)
        .cambiarEstado('c1', EstadoCompra.descartado);

    expect(stock.movimientos, isEmpty);
    expect(lista.estadosDirectos, [('c1', EstadoCompra.descartado)]);
  });

  test('deshacer un descarte tampoco toca el stock', () async {
    final lista = _ListaFalsa(_item(EstadoCompra.descartado));
    final stock = _StockFalso();

    await _contenedor(lista, stock)
        .read(comprasAccionesProvider)
        .cambiarEstado('c1', EstadoCompra.pendiente);

    expect(stock.movimientos, isEmpty);
    expect(lista.estadosDirectos, [('c1', EstadoCompra.pendiente)]);
  });

  test('si ya está comprado, volver a marcarlo no suma dos veces', () async {
    final lista = _ListaFalsa(_item(EstadoCompra.comprado));
    final stock = _StockFalso();

    await _contenedor(lista, stock)
        .read(comprasAccionesProvider)
        .cambiarEstado('c1', EstadoCompra.comprado);

    expect(stock.movimientos, isEmpty);
    expect(lista.estadosDirectos, isEmpty);
  });

  test('si el ítem ya no existe no hace nada', () async {
    final lista = _ListaFalsa(null);
    final stock = _StockFalso();

    await _contenedor(lista, stock)
        .read(comprasAccionesProvider)
        .cambiarEstado('c1', EstadoCompra.comprado);

    expect(stock.movimientos, isEmpty);
    expect(lista.estadosDirectos, isEmpty);
  });
}
