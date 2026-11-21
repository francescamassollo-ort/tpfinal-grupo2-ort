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

  // Selector de formato de Compartir y Descargar.
  static const String compartirComo = 'Compartir como';
  static const String descargarComo = 'Descargar como';
  static const String formatoPdf = 'PDF';
  static const String formatoPdfDetalle = 'Para imprimir o leer en el celular';
  static const String formatoCsv = 'Excel (CSV)';
  static const String formatoCsvDetalle = 'Para abrir y editar en Excel';
  static const String archivoGuardado = 'Archivo guardado';
  static const String archivoErrorGuardar = 'No se pudo guardar el archivo';
  static const String archivoErrorCompartir = 'No se pudo compartir el archivo';
  static const String comprasExportarVacia =
      'La lista está vacía, no hay nada para exportar';

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
  static const String historialError = 'No se pudo cargar el historial';
  static const String historialSinCoincidencias =
      'Ningún movimiento coincide con los filtros';
  static const String historialLimpiarFiltros = 'Limpiar filtros';
  static const String historialInsumoEliminado = 'Insumo eliminado';
  static const String historialFiltroTipo = 'Tipo de movimiento';
  static const String historialFiltroInsumo = 'Insumo';
  static const String historialFiltroDesde = 'Desde';
  static const String historialFiltroHasta = 'Hasta';
  static const String historialFiltroTodos = 'Todos';
  static const String historialFiltroCualquierFecha = 'Cualquier fecha';
  static const String historialFiltroEntrada = 'Entrada';
  static const String historialFiltroSalida = 'Salida';
  static const String historialFiltroAjuste = 'Ajuste';
  static const String filtrar = 'Filtrar';
  static const String limpiar = 'Limpiar';
  static const String historialHoy = 'Hoy';
  static const String historialAyer = 'Ayer';
  static const String movimientoEntrada = 'Entrada de stock';
  static const String movimientoSalida = 'Salida de stock';

  static const String alertasTitulo = 'Alertas';
  static String alertasConCantidad(int cantidad) => 'Alertas ($cantidad)';

  // Aviso de duplicados al dar de alta un insumo.
  static const String duplicadosBuscar = 'Buscar duplicados';
  static const String duplicadosEscribirNombre = 'Escribí un nombre primero';
  static const String duplicadosNinguno = 'No se encontraron duplicados';
  static const String duplicadosEncontrados = 'Ya hay insumos parecidos';
  static const String duplicadosMismoCodigo = 'Mismo código de barras';
  static const String duplicadosNombreParecido = 'Nombre muy parecido';
  static const String duplicadosCargarConsumo = 'Cargarle un consumo';
  static const String duplicadosSeguir = 'Es distinto, seguir cargando';
  static const String duplicadosCerrar = 'Cerrar';
  static const String duplicadosUnidades = 'unidades';
  static const String duplicadosError = 'No se pudo buscar duplicados';
  static const String duplicadosBuscandoIa = 'Buscando sinónimos con IA…';
  static const String duplicadosSugeridoIa = 'Sugerido por la IA';
  static const String duplicadosIaFallo =
      'No se pudo consultar la IA: se muestra solo la comparación de texto';
  static const String duplicadosIaNoDisponible =
      'La búsqueda con IA no está configurada';
  static const String duplicadosCargando =
      'Los insumos todavía se están cargando, probá de nuevo en un momento';
  static String duplicadosStockActual(int stock, String unidad) =>
      'Stock actual: $stock $unidad';
  static const String alertasVacia = 'No hay alertas por ahora';
  static const String alertasError = 'No se pudieron cargar las alertas';
  static const String alertaSinStock = 'Sin stock';
  static const String alertaStockBajo = 'Stock bajo';
  static const String alertaVencimientoCercano = 'Vencimiento cercano';
  static const String alertaVencido = 'Vencido';
  // Alertas de predicción de stock. La versión sin fecha o sin nombre es por si
  // falta el dato, para no mostrar un texto cortado.
  static const String alertaAgotamientoProximo =
      'Se agotaría antes de la próxima compra';
  static String alertaAgotamientoConFecha(String fecha) =>
      'Se agotaría el $fecha, antes de la próxima compra';
  static const String alertaTpSinCobertura =
      'No alcanza para un trabajo práctico';
  static String alertaTpSinCoberturaConNombre(String tp, String fecha) =>
      'No alcanza para $tp ($fecha)';
  static const String alertaCritica = 'Alerta crítica';
  static const String alertaAdvertencia = 'Advertencia';
}
