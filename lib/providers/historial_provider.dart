import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/filtro_historial.dart';
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

// Guarda lo que la persona eligió en el panel de filtros del Historial. Mismo
// patrón que InventarioFilterNotifier: al cambiar "state", la pantalla que lo
// mira se redibuja sola.
class FiltroHistorialNotifier extends Notifier<FiltroHistorial> {
  // Valor inicial: sin filtros, se ven todos los movimientos.
  @override
  FiltroHistorial build() => const FiltroHistorial();

  // Lo llama el botón del panel con el filtro completo que se eligió.
  void cambiar(FiltroHistorial filtro) => state = filtro;

  void limpiar() => state = const FiltroHistorial();
}

final filtroHistorialProvider =
    NotifierProvider<FiltroHistorialNotifier, FiltroHistorial>(
  FiltroHistorialNotifier.new,
);

// Lo que muestra la pantalla de Historial: los movimientos que cumplen el
// filtro, cada uno cruzado con su insumo para tener el nombre. El movimiento
// solo guarda el id del insumo, así un cambio de nombre se ve también en los
// movimientos viejos.
final historialProvider = Provider<AsyncValue<List<MovimientoItem>>>((ref) {
  final movimientos = ref.watch(movimientosStockProvider);
  final insumos = ref.watch(insumosProvider);
  final filtro = ref.watch(filtroHistorialProvider);

  return movimientos.when(
    loading: () => const AsyncLoading<List<MovimientoItem>>(),
    error: (error, stack) => AsyncError<List<MovimientoItem>>(error, stack),
    data: (lista) => insumos.whenData(
      (todos) => HistorialItems.armar(
        movimientos: filtro.aplicar(lista),
        insumos: todos,
        ahora: DateTime.now(),
      ),
    ),
  );
});
