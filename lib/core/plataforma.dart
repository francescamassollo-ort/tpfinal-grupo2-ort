import 'package:flutter/foundation.dart';

/// Lo que cambia según la plataforma en la que corre la app. Para decidir el
/// diseño se usa el ancho de la ventana (ver `Breakpoints`); esto es solo para
/// funciones que dependen de lo que la plataforma soporta.
class Plataforma {
  Plataforma._();

  /// Si se puede usar el escáner de código de barras. `mobile_scanner`
  /// funciona en Android, iOS, macOS y web, pero no en Windows ni Linux: ahí el
  /// botón se oculta y el código se escribe a mano.
  static bool get escanerDisponible =>
      kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.windows &&
          defaultTargetPlatform != TargetPlatform.linux);
}