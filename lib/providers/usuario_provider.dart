import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/usuario_actual.dart';


// Id de la persona que está usando la app, para guardar cosas que son de cada
// una (por ejemplo, qué alertas ya vio).
//
// Sale de la sesión de Firebase. Todavía no hay login conectado (se deja para
// el final), así que hoy nadie tiene sesión y todos comparten el id fijo
// [usuarioSinSesion]: en la práctica, lo que se guarda por persona se comparte
// entre todos. Cuando se conecte el login, empieza a ser por persona sin
// cambiar nada de lo que usa este provider.
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