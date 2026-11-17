import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/groq_config.dart';
import 'modelo_de_lenguaje.dart';

/// Cliente de Groq. Usa dart:io en vez de un paquete de HTTP para no sumar
/// dependencias al proyecto.
///
/// Nunca escribe la clave en ningún mensaje ni excepción.
class GroqClient implements ModeloDeLenguaje {
  GroqClient({
    String? apiKey,
    String? modelo,
    String? urlBase,
    Duration? tiempoMaximo,
  })  : _apiKey = apiKey ?? GroqConfig.apiKey,
        _modelo = modelo ?? GroqConfig.modelo,
        _urlBase = urlBase ?? GroqConfig.urlBase,
        _tiempoMaximo = tiempoMaximo ?? GroqConfig.tiempoMaximo;

  final String _apiKey;
  final String _modelo;
  final String _urlBase;
  final Duration _tiempoMaximo;

  // Tope de tokens de la respuesta. Los modelos que razonan gastan parte de
  // este tope pensando, por eso es más alto que lo que mide el JSON final.
  static const int _maximoDeTokens = 1500;

  @override
  Future<String> responder({
    required String instrucciones,
    required String consulta,
  }) async {
    if (_apiKey.isEmpty) {
      throw const ModeloDeLenguajeException('No hay una clave de Groq cargada');
    }

    final cliente = HttpClient()..connectionTimeout = _tiempoMaximo;
    try {
      final pedido = await cliente
          .postUrl(Uri.parse('$_urlBase/chat/completions'))
          .timeout(_tiempoMaximo);
      pedido.headers
        ..contentType = ContentType.json
        ..set(HttpHeaders.authorizationHeader, 'Bearer $_apiKey');
      pedido.add(utf8.encode(jsonEncode(_cuerpo(instrucciones, consulta))));

      final respuesta = await pedido.close().timeout(_tiempoMaximo);
      final texto = await respuesta
          .transform(utf8.decoder)
          .join()
          .timeout(_tiempoMaximo);

      if (respuesta.statusCode != 200) {
        throw ModeloDeLenguajeException(
          _mensajeDeError(respuesta.statusCode, texto),
          codigo: respuesta.statusCode,
        );
      }
      return _contenido(texto);
    } on ModeloDeLenguajeException {
      rethrow;
    } on TimeoutException {
      throw const ModeloDeLenguajeException('Groq tardó demasiado en responder');
    } on SocketException {
      throw const ModeloDeLenguajeException('No hay conexión con Groq');
    } on HttpException {
      throw const ModeloDeLenguajeException('No se pudo hablar con Groq');
    } finally {
      cliente.close(force: true);
    }
  }

  Map<String, Object?> _cuerpo(String instrucciones, String consulta) {
    return {
      'model': _modelo,
      'messages': [
        {'role': 'system', 'content': instrucciones},
        {'role': 'user', 'content': consulta},
      ],
      // Temperatura 0: ante la misma lista, la misma respuesta.
      'temperature': 0,
      'max_completion_tokens': _maximoDeTokens,
      'response_format': {'type': 'json_object'},
      // Solo los modelos gpt-oss entienden este ajuste: pensar poco alcanza
      // para agrupar nombres y gasta menos cuota.
      if (_modelo.startsWith('openai/gpt-oss')) 'reasoning_effort': 'low',
    };
  }

  String _contenido(String cuerpo) {
    try {
      final json = jsonDecode(cuerpo) as Map<String, dynamic>;
      final contenido = (json['choices'] as List).first['message']['content'];
      if (contenido is String && contenido.trim().isNotEmpty) return contenido;
    } catch (_) {
      // Cae en el error de abajo.
    }
    throw const ModeloDeLenguajeException('Groq devolvió una respuesta vacía');
  }

  String _mensajeDeError(int codigo, String cuerpo) {
    if (codigo == 401) return 'La clave de Groq no es válida';
    if (codigo == 429) return 'Se alcanzó el límite de uso de Groq';

    // El servidor suele explicar el problema en error.message.
    try {
      final detalle = (jsonDecode(cuerpo) as Map)['error']['message'];
      if (detalle is String && detalle.isNotEmpty) {
        return 'Groq respondió con error $codigo: $detalle';
      }
    } catch (_) {
      // Sin detalle: se usa el mensaje genérico.
    }
    return 'Groq respondió con error $codigo';
  }
}
