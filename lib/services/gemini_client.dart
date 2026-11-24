import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/gemini_config.dart';
import 'modelo_de_lenguaje.dart';

/// Cliente de Gemini (API REST de Google AI Studio). Usa package:http, que
/// también anda en la web.
///
/// La clave viaja en el encabezado `x-goog-api-key`, nunca en la URL, y nunca
/// se escribe en ningún mensaje ni excepción.
class GeminiClient implements ModeloDeLenguaje {
  GeminiClient({
    String? apiKey,
    String? modelo,
    String? urlBase,
    Duration? tiempoMaximo,
  })  : _apiKey = apiKey ?? GeminiConfig.apiKey,
        _modelo = modelo ?? GeminiConfig.modelo,
        _urlBase = urlBase ?? GeminiConfig.urlBase,
        _tiempoMaximo = tiempoMaximo ?? GeminiConfig.tiempoMaximo;

  final String _apiKey;
  final String _modelo;
  final String _urlBase;
  final Duration _tiempoMaximo;

  // Tope de tokens de la respuesta. Los modelos que razonan gastan parte de
  // este tope pensando, por eso es mucho más alto que lo que mide el JSON final.
  static const int _maximoDeTokens = 4096;

  @override
  Future<String> responder({
    required String instrucciones,
    required String consulta,
  }) async {
    if (_apiKey.isEmpty) {
      throw const ModeloDeLenguajeException(
        'No hay una clave de Gemini cargada',
      );
    }

    final cliente = http.Client();
    try {
      final respuesta = await cliente
          .post(
            Uri.parse('$_urlBase/models/$_modelo:generateContent'),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: jsonEncode(_cuerpo(instrucciones, consulta)),
          )
          .timeout(_tiempoMaximo);
      final texto = utf8.decode(respuesta.bodyBytes);

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
      throw const ModeloDeLenguajeException(
        'Gemini tardó demasiado en responder',
      );
    } on http.ClientException {
      throw const ModeloDeLenguajeException('No hay conexión con Gemini');
    } finally {
      cliente.close();
    }
  }

  Map<String, Object?> _cuerpo(String instrucciones, String consulta) {
    return {
      'systemInstruction': {
        'parts': [
          {'text': instrucciones},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': consulta},
          ],
        },
      ],
      'generationConfig': {
        // Temperatura 0: ante la misma lista, la misma respuesta.
        'temperature': 0,
        'maxOutputTokens': _maximoDeTokens,
        'responseMimeType': 'application/json',
      },
    };
  }

  // Une el texto de la respuesta. Si el pedido fue bloqueado o la respuesta se
  // cortó, lo dice con claridad en vez de devolver algo a medias.
  String _contenido(String cuerpo) {
    try {
      final json = jsonDecode(cuerpo) as Map<String, dynamic>;

      final bloqueo = (json['promptFeedback'] as Map?)?['blockReason'];
      if (bloqueo != null) {
        throw const ModeloDeLenguajeException(
          'Gemini no quiso responder a esta consulta',
        );
      }

      final candidato = (json['candidates'] as List).first as Map;
      if (candidato['finishReason'] == 'MAX_TOKENS') {
        throw const ModeloDeLenguajeException(
          'La respuesta de Gemini se cortó antes de terminar',
        );
      }

      // Los modelos que razonan pueden devolver partes con su "pensamiento"
      // (thought: true): no son parte de la respuesta.
      final partes = (candidato['content']['parts'] as List).cast<Map>();
      final texto = partes
          .where((parte) => parte['thought'] != true)
          .map((parte) => parte['text'])
          .whereType<String>()
          .join();
      if (texto.trim().isNotEmpty) return texto;
    } on ModeloDeLenguajeException {
      rethrow;
    } catch (_) {
      // Cae en el error de abajo.
    }
    throw const ModeloDeLenguajeException('Gemini devolvió una respuesta vacía');
  }

  String _mensajeDeError(int codigo, String cuerpo) {
    final detalle = _detalle(cuerpo);

    // Una clave mal copiada vuelve como 400, no como 401.
    final claveInvalida = codigo == 401 ||
        codigo == 403 ||
        cuerpo.contains('API_KEY_INVALID') ||
        cuerpo.contains('API key not valid');
    if (claveInvalida) {
      return 'La clave de Gemini no es válida o no tiene permiso';
    }
    if (codigo == 429) return 'Se alcanzó el límite de uso de Gemini';
    if (codigo == 404) {
      return 'Gemini no encontró el modelo "$_modelo": revisá GEMINI_MODEL';
    }

    if (detalle != null) {
      return 'Gemini respondió con error $codigo: $detalle';
    }
    return 'Gemini respondió con error $codigo';
  }

  // El servidor suele explicar el problema en error.message.
  String? _detalle(String cuerpo) {
    try {
      final detalle = (jsonDecode(cuerpo) as Map)['error']['message'];
      if (detalle is String && detalle.isNotEmpty) return detalle;
    } catch (_) {
      // Sin detalle: se usa el mensaje genérico.
    }
    return null;
  }
}
