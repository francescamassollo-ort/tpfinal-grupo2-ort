import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/prediccion_stock.dart';
import '../services/stock_prediction_service.dart';
import 'historial_provider.dart';
import 'insumo_providers.dart';

// Cuándo se estima que se agota cada insumo con consumo reciente, en tiempo
// real. Mira los movimientos y los insumos, y se recalcula solo cuando cambia
// cualquiera de los dos (por ejemplo, al registrarse una salida de stock).
// Igual que las alertas, no se guarda nada: se calcula a partir de los datos.
final prediccionStockProvider =
    Provider<AsyncValue<List<PrediccionStock>>>((ref) {
  final movimientos = ref.watch(movimientosStockProvider);
  final insumos = ref.watch(insumosProvider);

  return movimientos.when(
    loading: () => const AsyncLoading<List<PrediccionStock>>(),
    error: (error, stack) => AsyncError<List<PrediccionStock>>(error, stack),
    data: (lista) => insumos.whenData(
      (todos) => StockPredictionService.predecir(
        insumos: todos,
        movimientos: lista,
      ),
    ),
  );
});
