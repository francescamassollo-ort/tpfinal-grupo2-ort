import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_strings.dart';
import '../models/lista_compra.dart';
import '../screens/compras/item_compra.dart';
import '../services/lista_compra_service.dart';
import 'insumo_providers.dart';
import 'stock_provider.dart';

final listaCompraServiceProvider =
    Provider((ref) => ListaCompraService(FirebaseFirestore.instance));

// Productos pendientes de compra, en tiempo real. Se redibuja solo ante
// cualquier cambio en Firestore, también los que hace este mismo celular.
final listaCompraStreamProvider = StreamProvider<List<ListaCompra>>(
  (ref) => ref.watch(listaCompraServiceProvider).watchPendientes(),
);

// Lo que muestra la pantalla de Lista de compras: cada producto pendiente
// cruzado con su insumo, para tener el nombre y el stock actual. La lista no
// guarda esos datos, así el stock siempre está al día.
final itemsCompraProvider = Provider<AsyncValue<List<ItemCompra>>>((ref) {
  final lista = ref.watch(listaCompraStreamProvider);
  final insumos = ref.watch(insumosProvider);

  return lista.when(
    loading: () => const AsyncLoading<List<ItemCompra>>(),
    error: (error, stack) => AsyncError<List<ItemCompra>>(error, stack),
    data: (pendientes) => insumos.whenData((todos) {
      final porId = {for (final insumo in todos) insumo.id: insumo};
      return [
        for (final item in pendientes)
          // Si el insumo ya no existe, el ítem no se muestra.
          if (porId[item.productoId] case final insumo?)
            ItemCompra(
              id: item.id,
              nombre: insumo.nombre,
              stock: insumo.stock,
              cantidadSolicitada: item.cantidadSolicitada,
            ),
      ];
    }),
  );
});

/// Acciones de la pantalla de Lista de compras. Escriben en Firestore y la
/// pantalla se actualiza sola a través de [itemsCompraProvider].
class ComprasAcciones {
  ComprasAcciones(this._ref);

  final Ref _ref;

  Future<void> incrementar(String id) => _cambiarCantidad(id, 1);

  Future<void> decrementar(String id) => _cambiarCantidad(id, -1);

  Future<void> _cambiarCantidad(String id, int delta) async {
    final items = _ref.read(itemsCompraProvider).value ?? const [];
    final item = items.where((i) => i.id == id).firstOrNull;
    if (item == null) return;

    final nueva = item.cantidadSolicitada + delta;
    // No se baja de la cantidad mínima: no hace falta escribir nada.
    if (nueva < ListaCompra.cantidadMinima) return;

    await _ref.read(listaCompraServiceProvider).cambiarCantidad(id, nueva);
  }

  /// Cambia el estado de un ítem. La pantalla muestra solo los pendientes, así
  /// que pasarlo a comprado o descartado lo saca de la lista, y volverlo a
  /// pendiente (Deshacer) lo trae de nuevo con la misma cantidad.
  ///
  /// Marcar como comprado **suma la cantidad pedida al stock** del insumo y
  /// deja la entrada en el historial; Deshacer lo revierte con una salida. El
  /// stock y el estado se guardan en una sola transacción, así no puede quedar
  /// el ítem comprado sin stock sumado ni al revés. Si el stock ya no alcanza
  /// para deshacer (porque se usó), lanza una [StockException].
  Future<void> cambiarEstado(String id, EstadoCompra estado) async {
    final lista = _ref.read(listaCompraServiceProvider);
    final item = await lista.obtener(id);
    if (item == null || item.estado == estado) return;

    final stock = _ref.read(stockServiceProvider);
    void guardarEstado(Transaction t) => lista.actualizarEstadoEn(t, id, estado);

    if (estado == EstadoCompra.comprado) {
      await stock.registrarEntrada(
        item.productoId,
        item.cantidadSolicitada,
        AppStrings.comprasMotivoEntrada,
        junto: guardarEstado,
      );
    } else if (item.estado == EstadoCompra.comprado) {
      await stock.registrarSalida(
        item.productoId,
        item.cantidadSolicitada,
        AppStrings.comprasMotivoDeshacer,
        junto: guardarEstado,
      );
    } else {
      await lista.actualizarEstado(id, estado);
    }
  }

  /// Borra de la lista los ítems con estos [ids].
  Future<void> eliminar(Iterable<String> ids) {
    if (ids.isEmpty) return Future.value();
    return _ref.read(listaCompraServiceProvider).eliminar(ids);
  }

  /// Agrega un insumo a la lista con la [cantidad] que se eligió. Si el insumo
  /// ya está pendiente no crea otro ítem: queda el que había.
  ///
  /// La cantidad "sugerida" sigue siendo la que propone el sistema, no la que
  /// se tipeó: la elegida se guarda aparte como cantidad a comprar.
  Future<void> agregar(String productoId, int cantidad) async {
    final insumos = _ref.read(insumosProvider).value ?? const [];
    final insumo = insumos.where((i) => i.id == productoId).firstOrNull;
    final sugerida = insumo == null
        ? cantidad
        : ListaCompraService.cantidadSugeridaPara(insumo);

    final servicio = _ref.read(listaCompraServiceProvider);
    final id = await servicio.agregar(productoId, sugerida);
    if (cantidad != sugerida) await servicio.cambiarCantidad(id, cantidad);
  }

  /// Agrega los insumos con stock bajo que todavía no están en la lista.
  /// Devuelve cuántos agregó.
  Future<int> agregarSugerencias() {
    final insumos = _ref.read(insumosProvider).value ?? const [];
    return _ref.read(listaCompraServiceProvider).importarSugerencias(insumos);
  }
}

final comprasAccionesProvider = Provider((ref) => ComprasAcciones(ref));
