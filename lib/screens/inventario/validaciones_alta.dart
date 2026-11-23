/// Las comprobaciones de los campos del Alta de insumo. Son funciones puras para
/// poder probarlas solas: devuelven el aviso que se muestra debajo del campo, o
/// null si está bien.
class ValidacionesAlta {
  ValidacionesAlta._();

  static const String avisoNombre = 'Ingrese un nombre';
  static const String avisoUbicacion = 'Ingrese una ubicación';
  static const String avisoCantidadVacia = 'Ingrese una cantidad';
  static const String avisoCantidadEntera =
      'La cantidad tiene que ser un número entero';
  static const String avisoCantidadNegativa = 'La cantidad no puede ser negativa';
  static const String avisoMinimoVacio = 'Ingrese un stock mínimo';
  static const String avisoMinimoNumero = 'El stock mínimo tiene que ser un número';
  static const String avisoMinimoNegativo = 'El stock mínimo no puede ser negativo';
  static const String avisoPesoNumero = 'El peso molecular tiene que ser un número';
  static const String avisoPesoPositivo = 'El peso molecular tiene que ser mayor a 0';
  static const String avisoFechas =
      'La fecha de vencimiento no puede ser anterior a la de elaboración';

  /// Un número escrito a mano, con coma o con punto como separador decimal
  /// ("0,5" y "0.5" son lo mismo: en el teclado del celular sale la coma). Null
  /// si no es un número.
  static double? numero(String? texto) {
    final limpio = texto?.trim().replaceAll(',', '.') ?? '';
    return double.tryParse(limpio);
  }

  /// Un número entero. "5" sí; "5,5" y "cinco" no.
  static int? entero(String? texto) => int.tryParse(texto?.trim() ?? '');

  static String? nombre(String? texto) =>
      texto == null || texto.trim().isEmpty ? avisoNombre : null;

  static String? ubicacion(String? texto) =>
      texto == null || texto.trim().isEmpty ? avisoUbicacion : null;

  /// El stock inicial: un entero de 0 en adelante (el stock se cuenta en
  /// unidades enteras).
  static String? cantidadInicial(String? texto) {
    if (texto == null || texto.trim().isEmpty) return avisoCantidadVacia;
    final cantidad = entero(texto);
    if (cantidad == null) return avisoCantidadEntera;
    if (cantidad < 0) return avisoCantidadNegativa;
    return null;
  }

  /// El stock mínimo: un número de 0 en adelante (admite decimales).
  static String? stockMinimo(String? texto) {
    if (texto == null || texto.trim().isEmpty) return avisoMinimoVacio;
    final minimo = numero(texto);
    if (minimo == null) return avisoMinimoNumero;
    if (minimo < 0) return avisoMinimoNegativo;
    return null;
  }

  /// El peso molecular es opcional; si se escribe, tiene que ser un número
  /// mayor a 0.
  static String? pesoMolecular(String? texto) {
    if (texto == null || texto.trim().isEmpty) return null;
    final peso = numero(texto);
    if (peso == null) return avisoPesoNumero;
    if (peso <= 0) return avisoPesoPositivo;
    return null;
  }

  /// El vencimiento no puede ser anterior a la elaboración. Si falta alguna de
  /// las dos fechas no hay nada que comparar.
  static String? fechas({DateTime? elaboracion, DateTime? vencimiento}) {
    if (elaboracion == null || vencimiento == null) return null;
    return vencimiento.isBefore(elaboracion) ? avisoFechas : null;
  }
}
