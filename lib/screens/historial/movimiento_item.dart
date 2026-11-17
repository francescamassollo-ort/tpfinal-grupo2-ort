/// Un movimiento tal como lo muestra la pantalla de Historial.
///
/// Es un modelo de presentación: tiene el texto ya listo para mostrar. Cuando
/// exista el modelo de dominio de stock, se arma un MovimientoItem a partir de
/// él sin tocar la pantalla.
class MovimientoItem {
  const MovimientoItem({
    required this.id,
    required this.elementoNombre,
    required this.usuarioNombre,
    required this.fechaEtiqueta,
    required this.delta,
    this.destacado = false,
  });

  final String id;
  final String elementoNombre;
  final String usuarioNombre;

  /// Fecha ya formateada, por ejemplo "Hoy 14:32" o "22/09 09:02".
  final String fechaEtiqueta;

  /// Variación de stock: positiva es una entrada, negativa es una salida.
  final int delta;

  /// Fila con fondo resaltado, como en el diseño.
  final bool destacado;

  bool get esEntrada => delta > 0;

  /// Variación con signo, por ejemplo "+19" o "-10".
  String get deltaTexto => esEntrada ? '+$delta' : '$delta';
}
