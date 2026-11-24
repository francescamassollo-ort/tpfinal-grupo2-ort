import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/insumo.dart';
import '../screens/historial/historial_items.dart';
import '../screens/historial/movimiento_item.dart';
import 'alerta_provider.dart';
import 'historial_provider.dart';
import 'insumo_providers.dart';

/// Cuántos insumos tienen el stock en el mínimo o por debajo (los que
/// Inventario marca en rojo). Los sin stock cuentan: están por debajo.
int contarStockBajo(List<Insumo> insumos) =>
    insumos.where((insumo) => insumo.stockBajo).length;

// Insumos con stock bajo, en tiempo real. Mientras cargan, o si fallan, el
// tablero lo dice en vez de mostrar un 0 que podría ser falso.
final homeStockBajoProvider = Provider<AsyncValue<int>>(
  (ref) => ref.watch(insumosProvider).whenData(contarStockBajo),
);

// El último movimiento de stock, ya armado para mostrar (con el nombre del
// insumo), o null si todavía no hay ninguno.
//
// No usa [historialProvider] porque ese respeta el filtro que la persona puso
// en el Historial, y el tablero tiene que mostrar siempre lo último que pasó.
final homeUltimoMovimientoProvider = Provider<AsyncValue<MovimientoItem?>>((ref) {
  final movimientos = ref.watch(movimientosStockProvider);
  final insumos = ref.watch(insumosConBajasProvider);

  return movimientos.when(
    loading: () => const AsyncLoading<MovimientoItem?>(),
    error: (error, stack) => AsyncError<MovimientoItem?>(error, stack),
    data: (lista) {
      // Llegan del más nuevo al más viejo.
      if (lista.isEmpty) return const AsyncData<MovimientoItem?>(null);
      return insumos.whenData(
        (todos) => HistorialItems.armar(
          movimientos: [lista.first],
          insumos: todos,
          ahora: DateTime.now(),
        ).first,
      );
    },
  );
});

/// Lo que cuenta el tablero de alertas: cuántas hay activas y cuántas de esas
/// la persona todavía no vio.
typedef ResumenAlertas = ({int activas, int sinVer});

final homeAlertasProvider = Provider<AsyncValue<ResumenAlertas>>((ref) {
  final sinVer = ref.watch(alertasSinVerProvider).length;
  return ref.watch(alertasProvider).whenData(
        (activas) => (activas: activas.length, sinVer: sinVer),
      );
});
