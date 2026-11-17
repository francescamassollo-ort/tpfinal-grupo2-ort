import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/movimiento_stock.dart';
import '../screens/historial/historial_sample_data.dart';
import '../screens/historial/movimiento_item.dart';
import '../services/historial_service.dart';

final historialServiceProvider =
    Provider((ref) => HistorialService(FirebaseFirestore.instance));

// Los últimos movimientos de stock, en tiempo real y del más nuevo al más
// viejo. Se redibuja solo ante cualquier cambio en Firestore.
final movimientosStockProvider = StreamProvider<List<MovimientoStock>>(
  (ref) => ref.watch(historialServiceProvider).watchMovimientos(),
);

// Lista de movimientos que muestra la pantalla de Historial. Por ahora son los
// datos de ejemplo; cuando exista el servicio de stock, este provider pasa a
// leer los movimientos reales y la pantalla no cambia.
final historialProvider = Provider<List<MovimientoItem>>(
  (ref) => historialSampleData,
);
