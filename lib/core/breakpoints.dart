import 'package:flutter/widgets.dart';

/// Medidas de ancho para adaptar el diseño a distintos tamaños de pantalla.
///
/// El layout se decide por el ancho disponible y no por la plataforma: una
/// ventana de escritorio angosta tiene que verse como un celular.
class Breakpoints {
  Breakpoints._();

  /// Desde este ancho (en px lógicos) se usa el diseño de escritorio: panel
  /// lateral en vez de barra inferior y drawer. Por debajo es el de celular.
  static const double compact = 600;

  /// Ancho máximo del contenido de una pantalla de lista o de formulario. Más
  /// ancho que esto las tarjetas se estiran demasiado y cuesta leerlas.
  static const double maxContentWidth = 720;

  /// Ancho máximo de un diálogo (panel de filtros, selector de rol, etc.).
  static const double maxDialogWidth = 480;

  /// Ancho máximo de cada tarjeta de insumo cuando el inventario se muestra
  /// como grilla.
  static const double maxCardWidth = 420;

  /// true si [ancho] corresponde al diseño de escritorio.
  static bool esAncho(double ancho) => ancho >= compact;

  /// true si la ventana actual es lo bastante ancha para el diseño de
  /// escritorio. Para widgets reutilizables es mejor un `LayoutBuilder`, que
  /// mide el espacio que le dan y no el de toda la ventana.
  static bool esAnchoEn(BuildContext context) =>
      esAncho(MediaQuery.sizeOf(context).width);
}