import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/usuario.dart';
import '../services/rol_de_sesion_service.dart';
import '../services/user_service.dart';

// Quién tiene la sesión iniciada y el mail verificado (null si nadie, o si
// todavía no verificó), y cada vez que entra o sale alguien. En las pruebas se
// reemplaza: FirebaseAuth necesita que Firebase esté inicializado.
//
// Que la persona verifique su mail no hace que Firebase avise: la pantalla de
// verificación vuelve a pedir este provider (`ref.invalidate`) cuando pasa.
final sesionProvider = StreamProvider<PersonaConSesion?>(
  (ref) => FirebaseAuth.instance.authStateChanges().map(
        (usuario) => RolDeSesionService.personaDeSesion(
          uid: usuario?.uid,
          nombre: usuario?.displayName,
          email: usuario?.email,
          mailVerificado: usuario?.emailVerified ?? false,
          // Con Google solo valen las cuentas de ORT.
          exigeMailInstitucional:
              usuario?.providerData.any((p) => p.providerId == 'google.com') ??
                  false,
        ),
      ),
);

// Quien averigua el rol. Se pide por acá, y no con Firestore directo, para
// poder reemplazarlo por uno falso en las pruebas.
final rolDeSesionServiceProvider = Provider<RolDeSesionService>((ref) {
  final usuarios = UserService(FirebaseFirestore.instance);
  return RolDeSesionService(
    crearSiNoExiste: usuarios.crearSiNoExiste,
    vigilar: usuarios.watchById,
  );
});

// El rol de la persona que inició sesión, tal como está en su documento de la
// colección "usuarios", y cada vez que cambia. Sin sesión no hay rol.
final rolDeSesionProvider = StreamProvider<UserRole>((ref) async* {
  final persona = await ref.watch(sesionProvider.future);
  // Si mientras tanto cambió la sesión, este cálculo ya no vale.
  if (!ref.mounted || persona == null) return;

  yield* ref.watch(rolDeSesionServiceProvider).rolDe(persona);
});

// El rol que usa la app para decidir qué se ve y qué se puede hacer.
//
// Mientras se averigua (o si no se puede, por ejemplo sin conexión) vale el rol
// de menos permisos: es mejor mostrar de menos un instante que dejar a alguien
// ver o tocar lo que no le corresponde.
final roleProvider = Provider<UserRole>(
  (ref) =>
      ref.watch(rolDeSesionProvider).value ?? RolDeSesionService.rolPorDefecto,
);
