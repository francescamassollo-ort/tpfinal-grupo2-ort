import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRole { administrador, ayudante, docente }

// Guarda el rol del usuario actual. Por ahora queda fijo en "administrador"
// (todavía no hay login) para poder probar las otras pantallas. Cuando
// armemos el login al final, esta clase va a actualizar el rol con el que
// venga del usuario logueado.
class RoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() => UserRole.administrador;

  void setRole(UserRole role) => state = role;
}

final roleProvider = NotifierProvider<RoleNotifier, UserRole>(RoleNotifier.new);
