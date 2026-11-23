import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/usuario_actual_service.dart';

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

// Quien averigua con qué nombre dejar constancia de lo que hace la persona (por
// ejemplo, el docente de un trabajo práctico). Es el mismo servicio que usan los
// movimientos de stock, así que el nombre es el mismo en todas partes. Consulta
// la sesión cada vez que se le pide (no la guarda), por eso siempre es de quien
// está usando la app en ese momento.
final usuarioActualServiceProvider = Provider<UsuarioActualService>(
  (ref) => UsuarioActualService(),
);
