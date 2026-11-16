import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/insumo.dart';
import '../services/insumo_service.dart';

// StreamProvider: a diferencia del NotifierProvider del rol (que vos
// cambiás a mano con setRole), este tipo de provider expone datos que
// "fluyen solos" desde afuera -- acá, lo que emite watchInsumos().
// Cualquier pantalla que haga ref.watch(insumosProvider) se redibuja
// sola cada vez que cambia algo en Firestore, sin que nadie se lo pida.
final insumosProvider = StreamProvider<List<Insumo>>((ref) {
  final service = InsumoService();
  return service.watchInsumos();
});
