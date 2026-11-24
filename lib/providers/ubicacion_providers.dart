import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ubicacion.dart';
import '../services/ubicacion_service.dart';

// El servicio de ubicaciones. Se pide por acá para poder reemplazarlo en las
// pruebas (el de verdad habla con Firestore apenas se crea).
final ubicacionServiceProvider =
    Provider<UbicacionService>((ref) => UbicacionService());

// La lista de ubicaciones en tiempo real, ordenada por nombre.
final ubicacionesProvider = StreamProvider<List<Ubicacion>>(
  (ref) => ref.watch(ubicacionServiceProvider).watchUbicaciones(),
);
