/// Una hoja de un Excel ya leída: su nombre y sus filas, con cada celda como
/// texto, número, fecha o null si está vacía. Es lo que recibe el intérprete,
/// así se prueba sin armar archivos de Excel.
class HojaPlana {
  const HojaPlana(this.nombre, this.filas);

  final String nombre;
  final List<List<Object?>> filas;
}

/// Un insumo tal como se leyó de una planilla, todavía sin guardar.
class InsumoImportado {
  const InsumoImportado({
    required this.nombre,
    required this.cantidad,
    required this.ubicacion,
    required this.hoja,
    required this.fila,
    this.codigoInterno,
    this.formula,
    this.categoria,
    this.otrosNombres = const [],
    this.controlado = false,
  });

  final String nombre;

  /// El stock. "NO HAY" se lee como 0.
  final int cantidad;

  /// El lugar armado con el nombre de la hoja y los títulos de estante, cajón,
  /// armario, etc. que preceden al insumo ("404 - Armario N°1 - Soluciones").
  final String ubicacion;

  /// De dónde salió, para poder avisar "hoja X, fila N".
  final String hoja;
  final int fila;

  final String? codigoInterno;
  final String? formula;
  final String? categoria;
  final List<String> otrosNombres;
  final bool controlado;
}

/// Algo que el intérprete no pudo entender del todo y que conviene revisar.
class AvisoImportacion {
  const AvisoImportacion(this.hoja, this.fila, this.mensaje);

  final String hoja;

  /// Número de fila en el Excel (la primera es la 1). 0 si es de toda la hoja.
  final int fila;
  final String mensaje;

  @override
  String toString() => fila == 0 ? '$hoja: $mensaje' : '$hoja, fila $fila: $mensaje';
}

/// Lo que salió de leer un Excel completo.
class ResultadoLectura {
  const ResultadoLectura({
    required this.insumos,
    required this.avisos,
    required this.hojasLeidas,
    required this.hojasIgnoradas,
  });

  final List<InsumoImportado> insumos;
  final List<AvisoImportacion> avisos;

  /// Hojas de las que se sacó al menos un insumo.
  final List<String> hojasLeidas;

  /// Hojas que no se pudieron interpretar (no tienen una columna de nombres).
  final List<String> hojasIgnoradas;
}
