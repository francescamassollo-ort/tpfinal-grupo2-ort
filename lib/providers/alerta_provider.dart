import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/alerta.dart';
import '../services/alerta_service.dart';
import 'insumo_providers.dart';
import 'prediccion_provider.dart';

// Alertas activas, calculadas a partir de los insumos y de la predicción de
// stock. Como los insumos llegan en tiempo real desde Firestore, las alertas se
// actualizan solas: aparecen cuando el stock baja y desaparecen cuando se
// repone. Lo mismo con los avisos de la predicción: se recalculan cuando hay un
// movimiento nuevo o cambia un trabajo práctico.
//
// La predicción es un extra: las alertas de los insumos no esperan por ella ni
// dependen de ella. Mientras la predicción carga, o si falla (por ejemplo, si
// no se pueden leer los movimientos), se muestran igual las de siempre.
final alertasProvider = Provider<AsyncValue<List<Alerta>>>((ref) {
  final predicciones = ref.watch(prediccionStockProvider).value ?? const [];

  return ref.watch(insumosProvider).whenData(
        (insumos) =>
            AlertaService.generar(insumos, predicciones: predicciones),
      );
});
