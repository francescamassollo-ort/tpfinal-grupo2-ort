/// Formatos de presentación compartidos por varias pantallas.

/// dd/MM/yyyy, sin sumar la dependencia intl solo para esto.
String formatearFecha(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}

/// 5.0 -> "5"; 2.5 -> "2.5".
String formatearCantidad(double cantidad) =>
    cantidad == cantidad.truncateToDouble()
        ? cantidad.toInt().toString()
        : cantidad.toString();