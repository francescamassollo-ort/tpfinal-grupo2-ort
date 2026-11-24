import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/insumo.dart';
import '../services/insumo_service.dart';

// StreamProvider: a diferencia del NotifierProvider del rol (que vos
// cambiás a mano con setRole), este tipo de provider expone datos que
// "fluyen solos" desde afuera -- acá, lo que emite watchInsumos().
// Cualquier pantalla que haga ref.watch(insumosProvider) se redibuja
// sola cada vez que cambia algo en Firestore, sin que nadie se lo pida.
final insumosProvider = StreamProvider<List<Insumo>>((ref) {
  return ref.watch(insumoServiceProvider).watchInsumos();
});

// El servicio de insumos. Se pide por acá para poder reemplazarlo en las
// pruebas (el de verdad habla con Firestore apenas se crea).
final insumoServiceProvider = Provider<InsumoService>((ref) => InsumoService());

// Igual que insumosProvider pero **con los insumos dados de baja**. Solo lo usa
// el Historial para mostrar el nombre de los movimientos viejos; todo lo demás
// trabaja con los activos.
final insumosConBajasProvider = StreamProvider<List<Insumo>>((ref) {
  return ref.watch(insumoServiceProvider).watchInsumos(incluirBajas: true);
});

// Un insumo puntual, buscado por id dentro de la lista en tiempo real.
// ".family" = provider con parámetro: se usa como insumoPorIdProvider(id).
// Como mira insumosProvider, si el insumo cambia en Firestore, el Detalle
// se actualiza solo. Devuelve null si no hay ningún insumo con ese id.
final insumoPorIdProvider =
    Provider.family<AsyncValue<Insumo?>, String>((ref, id) {
  return ref.watch(insumosProvider).whenData(
        (insumos) => insumos.where((i) => i.id == id).firstOrNull,
      );
});
