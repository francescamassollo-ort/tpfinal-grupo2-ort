/// Textos de la interfaz en un solo lugar. Cada pantalla agrega acá los suyos
/// cuando se construye, para no repetirlos ni dejarlos sueltos en los widgets.
class AppStrings {
  AppStrings._();

  static const String volver = 'Volver';
  static const String compartir = 'Compartir';
  static const String descargar = 'Descargar';
  static const String filtros = 'Filtros';
  static const String disminuirCantidad = 'Disminuir cantidad';
  static const String aumentarCantidad = 'Aumentar cantidad';

  static const String comprasTitulo = 'Lista de compras';
  static const String comprasVacia = 'La lista de compras está vacía';
  static const String comprasAgregarSugerencias =
      '+Agregar sugerencias del sistema';
  static const String comprasError = 'No se pudo cargar la lista de compras';
  static const String comprasSinSugerencias = 'No hay sugerencias nuevas';
  static const String comprasErrorSugerencias =
      'No se pudieron agregar las sugerencias';

  static String comprasSugerenciasAgregadas(int cantidad) => cantidad == 1
      ? 'Se agregó 1 sugerencia'
      : 'Se agregaron $cantidad sugerencias';
  static const String buscar = 'Buscar';
  static const String papelera = 'Papelera';
  static const String agregar = 'Agregar';

  static const String historialTitulo = 'Historial de movimientos';
  static const String historialVacio = 'Todavía no hay movimientos registrados';
  static const String movimientoEntrada = 'Entrada de stock';
  static const String movimientoSalida = 'Salida de stock';
}
