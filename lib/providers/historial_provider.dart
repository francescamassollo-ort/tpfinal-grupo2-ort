import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/historial/historial_sample_data.dart';
import '../screens/historial/movimiento_item.dart';

// Lista de movimientos que muestra la pantalla de Historial. Por ahora son los
// datos de ejemplo; cuando exista el servicio de stock, este provider pasa a
// leer los movimientos reales y la pantalla no cambia.
final historialProvider = Provider<List<MovimientoItem>>(
  (ref) => historialSampleData,
);
