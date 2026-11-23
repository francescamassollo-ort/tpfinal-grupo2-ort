import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/usuario_actual.dart';


// Id de la persona que está usando la app, para guardar cosas que son de cada
// una (por ejemplo, qué alertas ya vio).
//
// Sale de la sesión de Firebase: es el uid de la cuenta con la que se ingresó.
// Si por algún motivo no hay sesión, se usa el id fijo [usuarioSinSesion].
//
// En las pruebas se reemplaza por un id fijo: FirebaseAuth necesita que
// Firebase esté inicializado.
const usuarioSinSesion = 'sin-sesion';

final usuarioActualIdProvider = Provider<String>(
  (ref) => FirebaseAuth.instance.currentUser?.uid ?? usuarioSinSesion,
);

final usuarioActualProvider = Provider<UsuarioActual>((ref) {
  final uid = ref.watch(usuarioActualIdProvider);
  if (uid == usuarioSinSesion) return UsuarioActual.sinSesion;
  final usuario = FirebaseAuth.instance.currentUser;
  return UsuarioActual(
    id: uid,
    nombre: usuario?.displayName ??
        usuario?.email ??
        UsuarioActual.nombreSinDatos,
  );
});