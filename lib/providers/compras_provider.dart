import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/compras/compras_sample_data.dart';
import '../screens/compras/item_compra.dart';

// Guarda la lista de compras que muestra la pantalla. Por ahora arranca con
// los datos de ejemplo; cuando exista el servicio de compras, build() pasa a
// leer la lista real y los métodos de abajo actualizan ese servicio.
class ComprasNotifier extends Notifier<List<ItemCompra>> {
  // Cantidad mínima que se puede pedir. Llegar a cero no está definido en el
  // diseño, así que el menos se detiene en 1. Quitar un ítem queda para la
  // papelera cuando se defina.
  static const int cantidadMinima = 1;

  @override
  List<ItemCompra> build() => comprasSampleData;

  void incrementar(String id) {
    _cambiarCantidad(id, 1);
  }

  void decrementar(String id) {
    _cambiarCantidad(id, -1);
  }

  void _cambiarCantidad(String id, int delta) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(
            cantidadSolicitada:
                math.max(cantidadMinima, item.cantidadSolicitada + delta),
          )
        else
          item,
    ];
  }
}

final comprasProvider =
    NotifierProvider<ComprasNotifier, List<ItemCompra>>(ComprasNotifier.new);
