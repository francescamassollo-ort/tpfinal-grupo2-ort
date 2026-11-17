import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/alerta.dart';
import '../services/alerta_service.dart';
import 'insumo_providers.dart';

// Alertas activas, calculadas a partir de los insumos. Como los insumos llegan
// en tiempo real desde Firestore, las alertas se actualizan solas: aparecen
// cuando el stock baja y desaparecen cuando se repone.
final alertasProvider = Provider<AsyncValue<List<Alerta>>>((ref) {
  return ref
      .watch(insumosProvider)
      .whenData((insumos) => AlertaService.generar(insumos));
});
