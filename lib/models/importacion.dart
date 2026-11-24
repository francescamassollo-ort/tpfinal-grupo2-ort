/// Una hoja de un Excel ya leída: su nombre y sus filas, con cada celda como
/// texto, número, fecha o null si está vacía. Es lo que recibe el lector de la
/// plantilla, así se prueba sin armar archivos de Excel.
class HojaPlana {
  const HojaPlana(this.nombre, this.filas);

  final String nombre;
  final List<List<Object?>> filas;
}

/// Un insumo tal como se leyó de la plantilla, todavía sin guardar.
class InsumoImportado {
  const InsumoImportado({
    required this.nombre,
    required this.cantidad,
    required this.ubicacion,
    required this.fila,
    this.stockMinimo,
    this.unidad,
    this.categoria,
    this.codigoInterno,
    this.formula,
    this.pesoMolecular,
    this.marca,
    this.otrosNombres = const [],
    this.controlado = false,
  });

  final String nombre;

  /// El stock.
  final int cantidad;

  final String ubicacion;

  /// Número de fila en el Excel (la primera es la 1), para poder avisar "fila N".
  final int fila;

  /// Si la plantilla no lo trae, se usa el que define el plan de importación.
  final num? stockMinimo;
  final String? unidad;
  final String? categoria;
  final String? codigoInterno;
  final String? formula;
  final double? pesoMolecular;
  final String? marca;
  final List<String> otrosNombres;
  final bool controlado;
}

/// Un problema de una fila (o de todo el archivo, con [fila] en 0).
class AvisoImportacion {
  const AvisoImportacion(this.fila, this.mensaje);

  /// Número de fila en el Excel (la primera es la 1). 0 si es de todo el archivo.
  final int fila;
  final String mensaje;

  @override
  String toString() => fila == 0 ? mensaje : 'Fila $fila: $mensaje';
}

/// Lo que salió de leer la plantilla.
class ResultadoLectura {
  const ResultadoLectura({required this.insumos, required this.errores});

  /// Las filas correctas, listas para cargar.
  final List<InsumoImportado> insumos;

  /// Las filas que no se pueden cargar y por qué. Las que tienen errores no se
  /// cargan; el resto sí.
  final List<AvisoImportacion> errores;

  /// El archivo en sí no sirve (no es la plantilla, o le falta una columna
  /// obligatoria): no hay nada para cargar.
  bool get archivoInvalido => insumos.isEmpty && errores.any((e) => e.fila == 0);
}
