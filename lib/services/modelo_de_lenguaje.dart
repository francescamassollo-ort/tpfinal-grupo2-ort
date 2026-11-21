/// Un modelo de lenguaje al que se le da una consigna y un texto, y responde
/// con texto. Es una interfaz para poder cambiar de proveedor o usar uno falso
/// en las pruebas, sin llamar a ningún servicio de verdad.
abstract class ModeloDeLenguaje {
  /// Hace una consulta y devuelve la respuesta del modelo. Si algo sale mal
  /// (sin clave, sin conexión, cuota agotada, respuesta rara) lanza una
  /// [ModeloDeLenguajeException].
  Future<String> responder({
    required String instrucciones,
    required String consulta,
  });
}

/// No se pudo obtener una respuesta del modelo de lenguaje.
class ModeloDeLenguajeException implements Exception {
  const ModeloDeLenguajeException(this.mensaje, {this.codigo});

  final String mensaje;

  /// Código HTTP, si el servidor llegó a responder.
  final int? codigo;

  @override
  String toString() => 'ModeloDeLenguajeException: $mensaje';
}
