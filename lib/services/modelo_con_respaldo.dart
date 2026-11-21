import 'modelo_de_lenguaje.dart';

/// Un modelo de lenguaje con otro de respaldo: consulta al [principal] y, si
/// este falla (sin conexión, límite de uso agotado, clave inválida...), repite
/// la misma consulta con el [respaldo].
///
/// Si los dos fallan, lanza el error del principal, que es el que se eligió
/// usar. Los errores que no son de [ModeloDeLenguajeException] (un fallo de
/// programación, por ejemplo) no se tapan con el respaldo.
class ModeloConRespaldo implements ModeloDeLenguaje {
  const ModeloConRespaldo({required this.principal, required this.respaldo});

  final ModeloDeLenguaje principal;
  final ModeloDeLenguaje respaldo;

  @override
  Future<String> responder({
    required String instrucciones,
    required String consulta,
  }) async {
    final ModeloDeLenguajeException errorDelPrincipal;
    try {
      return await principal.responder(
        instrucciones: instrucciones,
        consulta: consulta,
      );
    } on ModeloDeLenguajeException catch (error) {
      errorDelPrincipal = error;
    }

    try {
      return await respaldo.responder(
        instrucciones: instrucciones,
        consulta: consulta,
      );
    } on ModeloDeLenguajeException {
      throw errorDelPrincipal;
    }
  }
}
