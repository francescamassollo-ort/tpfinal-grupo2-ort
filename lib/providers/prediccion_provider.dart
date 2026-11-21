import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/prediccion_stock.dart';
import '../models/ventana_prediccion.dart';
import '../services/stock_prediction_service.dart';
import 'historial_provider.dart';
import 'insumo_providers.dart';
import 'trabajopractico_provider.dart';

// Cuántos días de consumo mira la predicción: 30 o 60, la que mejor habría
// predicho lo que realmente pasó en las últimas semanas (ver
// StockPredictionService.elegirVentana). Se recalcula con cada movimiento nuevo,
// así que "aprende" sola a medida que hay más historial. Con poco historial
// usa 30. También dice por qué eligió esa, para poder mostrarlo.
final ventanaPrediccionProvider = Provider<AsyncValue<VentanaPrediccion>>((ref) {
  return ref.watch(movimientosStockProvider).whenData(
        (movimientos) =>
            StockPredictionService.elegirVentana(movimientos: movimientos),
      );
});

// Qué se espera de cada insumo hasta la próxima compra, en tiempo real: cuándo
// se agota al ritmo actual y si alcanza para los trabajos prácticos
// planificados. Mira los movimientos, los insumos y los TP, y se recalcula solo
// cuando cambia cualquiera de los tres (por ejemplo, al registrarse una salida
// de stock). Igual que las alertas, no se guarda nada: se calcula.
//
// Usa la ventana de días que elige [ventanaPrediccionProvider].
//
// Los trabajos prácticos mejoran la predicción pero no son imprescindibles: si
// no se pueden leer, se sigue solo con el ritmo de consumo en lugar de caerse.
final prediccionStockProvider =
    Provider<AsyncValue<List<PrediccionStock>>>((ref) {
  final movimientos = ref.watch(movimientosStockProvider);
  final insumos = ref.watch(insumosProvider);
  final tps = ref.watch(tpsStreamProvider);
  final ventana = ref.watch(ventanaPrediccionProvider).value?.ventanaDias ??
      StockPredictionService.ventanaPorDefecto;

  return movimientos.when(
    loading: () => const AsyncLoading<List<PrediccionStock>>(),
    error: (error, stack) => AsyncError<List<PrediccionStock>>(error, stack),
    data: (lista) => insumos.when(
      loading: () => const AsyncLoading<List<PrediccionStock>>(),
      error: (error, stack) => AsyncError<List<PrediccionStock>>(error, stack),
      data: (todos) {
        // Mientras los TP cargan se espera, para que los avisos del plan no
        // aparezcan de golpe un momento después. Si fallan, se sigue sin ellos.
        if (!tps.hasValue && !tps.hasError) {
          return const AsyncLoading<List<PrediccionStock>>();
        }
        return AsyncData(
          StockPredictionService.predecir(
            insumos: todos,
            movimientos: lista,
            trabajosPracticos: tps.value ?? const [],
            ventanaDias: ventana,
          ),
        );
      },
    ),
  );
});
