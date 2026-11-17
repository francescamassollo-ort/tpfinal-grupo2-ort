import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/movimiento_stock.dart';
import '../screens/historial/historial_items.dart';
import '../screens/historial/movimiento_item.dart';
import '../services/historial_service.dart';
import 'insumo_providers.dart';

final historialServiceProvider =
    Provider((ref) => HistorialService(FirebaseFirestore.instance));

// Los últimos movimientos de stock, en tiempo real y del más nuevo al más
// viejo. Se redibuja solo ante cualquier cambio en Firestore.
final movimientosStockProvider = StreamProvider<List<MovimientoStock>>(
  (ref) => ref.watch(historialServiceProvider).watchMovimientos(),
);

// Lo que muestra la pantalla de Historial: cada movimiento cruzado con su
// insumo para tener el nombre. El movimiento solo guarda el id del insumo, así
// un cambio de nombre se ve también en los movimientos viejos.
final historialProvider = Provider<AsyncValue<List<MovimientoItem>>>((ref) {
  final movimientos = ref.watch(movimientosStockProvider);
  final insumos = ref.watch(insumosProvider);

  return movimientos.when(
    loading: () => const AsyncLoading<List<MovimientoItem>>(),
    error: (error, stack) => AsyncError<List<MovimientoItem>>(error, stack),
    data: (lista) => insumos.whenData(
      (todos) => HistorialItems.armar(
        movimientos: lista,
        insumos: todos,
        ahora: DateTime.now(),
      ),
    ),
  );
});
