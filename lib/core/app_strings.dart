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
  static const String comprasCambiarEstado = 'Cambiar estado';
  static const String comprasMarcarComprado = 'Marcar como comprado';
  static const String comprasDescartar = 'Descartar';
  static const String comprasDeshacer = 'Deshacer';
  static const String comprasErrorEstado = 'No se pudo cambiar el estado';
  static const String cancelar = 'Cancelar';
  static const String comprasAgregarTitulo = 'Agregar a la lista';
  static const String comprasCampoInsumo = 'Insumo';
  static const String comprasCampoCantidad = 'Cantidad a comprar';
  static const String comprasTodosEnLista =
      'Todos los insumos ya están en la lista';
  static const String comprasErrorAgregar = 'No se pudo agregar a la lista';
  static String comprasStockActual(int stock) => 'Stock actual: $stock u.';
  static String comprasAgregado(String nombre) =>
      '$nombre agregado a la lista';

  // Aviso al sacar un ítem de la lista: sale porque la pantalla muestra solo
  // los pendientes, por eso trae el botón Deshacer.
  static String comprasMarcadoComprado(String nombre) =>
      '$nombre: marcado como comprado';
  static String comprasDescartado(String nombre) => '$nombre: descartado';

  static String comprasSugerenciasAgregadas(int cantidad) => cantidad == 1
      ? 'Se agregó 1 sugerencia'
      : 'Se agregaron $cantidad sugerencias';
  static const String buscar = 'Buscar';
  static const String papelera = 'Papelera';
  static const String agregar = 'Agregar';

  static const String historialTitulo = 'Historial de movimientos';
  static const String historialVacio = 'Todavía no hay movimientos registrados';
  static const String historialError = 'No se pudo cargar el historial';
  static const String historialExportarVacio =
      'No hay movimientos para exportar';
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

  // Alta de insumo: lectura de la etiqueta con la cámara.
  static const String altaLeerEtiqueta = 'Leer etiqueta con la cámara';
  static const String altaLeyendoEtiqueta = 'Leyendo la etiqueta…';
  static const String altaEtiquetaLeida =
      'Se completaron los datos de la etiqueta: revisalos antes de guardar';
  static const String altaEtiquetaVacia =
      'No se encontraron datos en la foto. Probá con más luz y la etiqueta bien de frente';
  static const String altaEtiquetaError = 'No se pudo leer la etiqueta';
  static const String altaCamaraError = 'No se pudo abrir la cámara';

  // Alta de insumo: categoría sugerida.
  static String categoriaSugerida(String categoria) =>
      'Categoría sugerida: $categoria';
  static const String categoriaUsar = 'Usar';
  static const String categoriaPedirIa = 'Sugerir categoría con IA';
  static const String categoriaConsultandoIa = 'Consultando a la IA…';
  static const String categoriaIaSinRespuesta =
      'La IA no pudo sugerir una categoría';
  static const String categoriaIaError = 'No se pudo consultar la IA';
  static const String categoriaOrigenInsumo = 'según un insumo parecido';
  static const String categoriaOrigenReglas = 'por el nombre';
  static const String categoriaOrigenIa = 'sugerida por la IA';

  // Alta de insumo: sugerencias mientras se escribe el nombre.
  static const String altaSugerenciasTitulo = 'Ya existe algo parecido:';
  static const String altaSinCoincidencias =
      'No hay un insumo con ese nombre: se va a agregar como nuevo';

  // Alta de insumo: lo que suma el escáner.
  static const String altaEscanear = 'Escanear código de barras';
  static const String altaDatosCompletados =
      'Se completaron los datos con el código escaneado';

  // Escáner de código de barras.
  static const String escanerIndicacion =
      'Apuntá la cámara al código de barras del producto';
  static const String escanerBuscando = 'Buscando datos del código…';
  static const String escanerCodigoDetectado = 'CÓDIGO DETECTADO';
  static const String escanerCodigoAutocompletado =
      'CÓDIGO DETECTADO · AUTOCOMPLETADO';
  static const String escanerNoEncontrado = 'No encontramos este código';
  static const String escanerRevisarDatos =
      'Datos de una base pública: revisalos antes de usarlos';
  static const String escanerEditar = 'Editar';
  static const String escanerSumarStock = 'Sumar stock';
  static const String escanerEscanearDeNuevo = 'Escanear de nuevo';
  static const String escanerUsarDatos = 'Usar estos datos';
  static const String escanerCargarAMano = 'Cargar a mano';
  static const String escanerCampoNombre = 'Nombre';
  static const String escanerSinPermiso =
      'Para escanear hace falta permitir el acceso a la cámara';
  static const String escanerCamaraError = 'No se pudo abrir la cámara';
  static const String escanerMotivoReposicion = 'Reposición';
  static const String escanerErrorSumar = 'No se pudo sumar el stock';
  static String escanerStockActual(int stock, String unidad) =>
      'Stock actual: $stock $unidad';
  static String escanerFormula(String formula) => 'Fórmula: $formula';
  static String escanerPesoMolecular(double peso) =>
      'Peso molecular: ${peso.toString().replaceAll('.', ',')}';
  static String escanerStockSumado(int cantidad, String nombre) =>
      'Se sumaron $cantidad a $nombre';
  static const String sumarStockTitulo = 'Sumar stock';
  static const String sumarStockCantidad = 'Cantidad a sumar';
  static const String sumarStockConfirmar = 'Sumar';
  static const String escanerUnidadPorDefecto = 'u.';

  // Registro de consumo.
  static const String consumoTitulo = 'Registro de consumo';
  static const String consumoSubtitulo =
      'Seleccionar la cantidad de insumos a retirar';
  static const String consumoAgregarOtro = '+ Agregar otro insumo';
  static const String consumoConfirmar = 'Confirmar salida';
  static const String consumoMotivo = 'Motivo';
  static const String consumoMotivoTp = 'TP';
  static const String consumoMotivoClase = 'Clase';
  static const String consumoMotivoInvestigacion = 'Investigación';
  static const String consumoMotivoOtro = 'Otro';
  static const String consumoDetalleMotivo = 'Detalle del motivo';
  static const String consumoDetalleObligatorio =
      'Escribí el detalle del motivo';
  static const String consumoRegistrado = 'Consumo registrado correctamente';
  static const String consumoError = 'No se pudo registrar el consumo';
  static const String consumoErrorCargar = 'No se pudieron cargar los insumos';
  static const String consumoSinMasInsumos =
      'No hay más insumos con stock para agregar';
  static const String consumoAgregarTitulo = 'Agregar insumo';
  static const String consumoBuscarInsumo = 'Buscar insumo';
  static const String consumoSinCoincidencias =
      'Ningún insumo coincide con la búsqueda';
  static const String consumoUnidadPorDefecto = 'u.';
  static String consumoDisponible(int stock, String unidad) =>
      'Disponible: $stock $unidad';
  static String consumoSinStock(String nombre) =>
      'No hay stock suficiente de $nombre';
  static String consumoInsumoNoExiste(String nombre) =>
      '$nombre ya no existe';

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
  static const String alertasFiltroTipo = 'Tipo de alerta';
  static const String alertasFiltroEstado = 'Estado';
  static const String alertasFiltroTodos = 'Todos';
  static const String alertasFiltroTodas = 'Todas';
  static const String alertasFiltroSinVer = 'Sin ver';
  static const String alertasFiltroVistas = 'Vistas';
  static const String alertasSinCoincidencias =
      'Ninguna alerta coincide con los filtros';
  static const String alertasLimpiarFiltros = 'Limpiar filtros';
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

  //Lista Trabajos Practicos
  static const String tpTitulo = 'Lista para trabajos prácticos';
  static const String tpBuscarHint = 'Buscar trabajo práctico';
  static const String tpEditar = 'Editar trabajo práctico';
  static const String tpVacia = 'Todavía no hay trabajos prácticos cargados';
  static const String tpSinResultados = 'No se encontraron trabajos prácticos';
  static const String tpError = 'No se pudieron cargar los trabajos prácticos';
  static const String tpInsumosCompletos = 'Insumos completos';
  static const String tpErrorDisponibilidad = 'No se pudo verificar el stock';
  static String tpInsumosFaltantes(int cantidad) =>
      cantidad == 1 ? 'Falta 1 insumo' : 'Faltan $cantidad insumos';
  static const String tpCancelar = 'Cancelar';
  static const String tpEliminar = 'Eliminar';
  static const String tpEliminarTitulo = '¿Eliminar trabajos prácticos?';
  static const String tpErrorEliminar =
      'No se pudieron eliminar los trabajos prácticos';
  static String tpDocente(String nombre) => 'Docente: $nombre';
  static String tpSeleccionados(int cantidad) =>
      cantidad == 1 ? '1 seleccionado' : '$cantidad seleccionados';
  static String tpEliminarMensaje(int cantidad) => cantidad == 1
      ? 'Se va a eliminar 1 trabajo práctico de la lista.'
      : 'Se van a eliminar $cantidad trabajos prácticos de la lista.';
  static const String alertaMarcarVista = 'Marcar como vista';
  static const String alertaMarcarNoVista = 'Marcar como no vista';
  static const String alertasErrorMarcar = 'No se pudo actualizar la alerta';
  //Detalle Trabajos Practicos
    static const String tpNoEncontrado = 'No se encontró el trabajo práctico';
  static const String tpErrorDetalle = 'No se pudo cargar el trabajo práctico';
  static const String tpSinInsumos =
      'Este trabajo práctico no tiene insumos cargados';
  static const String tpInsumoNoEncontrado = 'Insumo no encontrado';
  static const String tpColumnaNombre = 'Nombre';
  static const String tpColumnaUbicacion = 'Ubicación';
  // Pantallas que el rol de la persona no puede usar.
  static const String sinPermiso = 'No tenés permiso para usar esta pantalla';

  static const String tpEliminarUnoTitulo = '¿Eliminar trabajo práctico?';
  static String tpDocenteACargo(String nombre) => 'Docente a cargo: $nombre';
  static String tpRequeridoStock(String requerido, int stock) =>
      'Necesita $requerido · Stock $stock';
}
