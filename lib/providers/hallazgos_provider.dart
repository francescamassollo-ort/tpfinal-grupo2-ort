import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hallazgo.dart';
import '../services/duplicate_detection_service.dart';
import 'insumo_providers.dart';

// Duplicados e inconsistencias de los insumos, calculados a partir de los
// insumos en tiempo real. Se actualizan solos cuando alguien corrige un dato.
final hallazgosProvider = Provider<AsyncValue<List<Hallazgo>>>((ref) {
  return ref
      .watch(insumosProvider)
      .whenData((insumos) => DuplicateDetectionService.detectar(insumos));
});
