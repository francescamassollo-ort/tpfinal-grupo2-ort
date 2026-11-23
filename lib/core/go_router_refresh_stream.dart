import 'dart:async';

import 'package:flutter/foundation.dart';

/// Hace que el router vuelva a evaluar sus reglas de redirección cada vez que
/// el [stream] emite algo. Se usa con `FirebaseAuth.authStateChanges()`: al
/// iniciar o cerrar sesión, el router manda solo a Inventario o a Bienvenida.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
