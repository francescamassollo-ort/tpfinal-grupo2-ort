import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/services/gemini_client.dart';
import 'package:tpfinal_grupo2/services/modelo_de_lenguaje.dart';

/// Un servidor falso en la propia computadora: así se prueba el cliente sin
/// llamar a Gemini de verdad ni gastar cuota.
class _ServidorFalso {
  late final HttpServer _servidor;
  int estado = 200;
  String cuerpoDeRespuesta = '';
  Duration demora = Duration.zero;
  Map<String, dynamic>? pedidoRecibido;
  String? claveRecibida;
  String? rutaRecibida;
  int cantidadDePedidos = 0;

  int get puerto => _servidor.port;
  String get urlBase => 'http://127.0.0.1:$puerto/v1beta';

  Future<void> iniciar() async {
    _servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _servidor.listen((pedido) async {
      cantidadDePedidos++;
      claveRecibida = pedido.headers.value('x-goog-api-key');
      rutaRecibida = pedido.uri.toString();
      final texto = await utf8.decoder.bind(pedido).join();
      pedidoRecibido = jsonDecode(texto) as Map<String, dynamic>;

      if (demora > Duration.zero) await Future<void>.delayed(demora);
      pedido.response
        ..statusCode = estado
        ..headers.contentType = ContentType.json
        ..write(cuerpoDeRespuesta);
      await pedido.response.close();
    });
  }

  Future<void> cerrar() => _servidor.close(force: true);
}

String _respuestaOk(String contenido, {String? finishReason}) => jsonEncode({
      'candidates': [
        {
          'content': {
            'role': 'model',
            'parts': [
              {'text': contenido},
            ],
          },
          'finishReason': ?finishReason,
        },
      ],
    });

void main() {
  late _ServidorFalso servidor;

  setUp(() async {
    servidor = _ServidorFalso();
    await servidor.iniciar();
  });

  tearDown(() => servidor.cerrar());

  GeminiClient cliente({
    String clave = 'clave-falsa',
    String modelo = 'gemini-3.5-flash-lite',
    Duration tiempoMaximo = const Duration(seconds: 5),
    String? urlBase,
  }) {
    return GeminiClient(
      apiKey: clave,
      modelo: modelo,
      urlBase: urlBase ?? servidor.urlBase,
      tiempoMaximo: tiempoMaximo,
    );
  }

  Future<String> preguntar([GeminiClient? c]) {
    return (c ?? cliente()).responder(instrucciones: 'Sé breve', consulta: 'hola');
  }

  test('devuelve el texto de la respuesta', () async {
    servidor.cuerpoDeRespuesta = _respuestaOk('{"grupos":[]}');

    expect(await preguntar(), '{"grupos":[]}');
  });

  test('une varias partes y deja afuera las del pensamiento', () async {
    servidor.cuerpoDeRespuesta = jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': 'estoy pensando...', 'thought': true},
              {'text': '{"grupos":'},
              {'text': '[]}'},
            ],
          },
        },
      ],
    });

    expect(await preguntar(), '{"grupos":[]}');
  });

  test('manda la clave en el encabezado, el modelo en la ruta y pide JSON', () async {
    servidor.cuerpoDeRespuesta = _respuestaOk('{}');

    await preguntar();

    expect(servidor.claveRecibida, 'clave-falsa');
    expect(servidor.rutaRecibida, '/v1beta/models/gemini-3.5-flash-lite:generateContent');

    final pedido = servidor.pedidoRecibido!;
    expect(pedido['systemInstruction'], {
      'parts': [
        {'text': 'Sé breve'},
      ],
    });
    expect(pedido['contents'], [
      {
        'role': 'user',
        'parts': [
          {'text': 'hola'},
        ],
      },
    ]);
    final config = pedido['generationConfig'] as Map;
    expect(config['temperature'], 0);
    expect(config['responseMimeType'], 'application/json');
    expect(config['maxOutputTokens'], greaterThan(1000));
  });

  test('la clave no viaja en la URL', () async {
    servidor.cuerpoDeRespuesta = _respuestaOk('{}');

    await preguntar();

    expect(servidor.rutaRecibida, isNot(contains('clave-falsa')));
    expect(servidor.rutaRecibida, isNot(contains('key=')));
  });

  test('usa el modelo que se le indique', () async {
    servidor.cuerpoDeRespuesta = _respuestaOk('{}');

    await preguntar(cliente(modelo: 'gemini-2.5-flash-lite'));

    expect(servidor.rutaRecibida, contains('models/gemini-2.5-flash-lite:'));
  });

  test('sin clave falla sin llamar al servidor', () async {
    await expectLater(
      preguntar(cliente(clave: '')),
      throwsA(isA<ModeloDeLenguajeException>()),
    );

    expect(servidor.cantidadDePedidos, 0);
  });

  group('errores', () {
    Matcher fallaCon(int codigo, String texto) {
      return throwsA(
        isA<ModeloDeLenguajeException>()
            .having((e) => e.codigo, 'codigo', codigo)
            .having((e) => e.mensaje, 'mensaje', contains(texto)),
      );
    }

    test('una clave mal copiada (400) dice que no es válida', () async {
      servidor.estado = 400;
      servidor.cuerpoDeRespuesta =
          '{"error":{"code":400,"message":"API key not valid. Please pass a valid API key.","status":"INVALID_ARGUMENT"}}';

      await expectLater(preguntar(), fallaCon(400, 'no es válida'));
    });

    test('un 403 dice que la clave no es válida o no tiene permiso', () async {
      servidor.estado = 403;
      servidor.cuerpoDeRespuesta = '{"error":{"message":"denegado"}}';

      await expectLater(preguntar(), fallaCon(403, 'no tiene permiso'));
    });

    test('un 429 dice que se alcanzó el límite', () async {
      servidor.estado = 429;
      servidor.cuerpoDeRespuesta = '{"error":{"message":"quota"}}';

      await expectLater(preguntar(), fallaCon(429, 'límite'));
    });

    test('un 404 nombra el modelo y dónde cambiarlo', () async {
      servidor.estado = 404;
      servidor.cuerpoDeRespuesta = '{"error":{"message":"not found"}}';

      await expectLater(
        preguntar(cliente(modelo: 'gemini-inexistente')),
        throwsA(
          isA<ModeloDeLenguajeException>()
              .having((e) => e.mensaje, 'mensaje', contains('gemini-inexistente'))
              .having((e) => e.mensaje, 'mensaje', contains('GEMINI_MODEL')),
        ),
      );
    });

    test('otro error incluye lo que explica el servidor', () async {
      servidor.estado = 500;
      servidor.cuerpoDeRespuesta = '{"error":{"message":"falló por dentro"}}';

      await expectLater(preguntar(), fallaCon(500, 'falló por dentro'));
    });

    test('un error sin detalle usa el mensaje genérico', () async {
      servidor.estado = 503;
      servidor.cuerpoDeRespuesta = 'no es json';

      await expectLater(preguntar(), fallaCon(503, 'error 503'));
    });

    test('ningún mensaje de error contiene la clave', () async {
      servidor.estado = 500;
      servidor.cuerpoDeRespuesta = '{"error":{"message":"falló"}}';

      try {
        await preguntar();
        fail('tendría que haber fallado');
      } on ModeloDeLenguajeException catch (e) {
        expect(e.toString(), isNot(contains('clave-falsa')));
        expect(e.mensaje, isNot(contains('clave-falsa')));
      }
    });

    test('un pedido bloqueado lo dice', () async {
      servidor.cuerpoDeRespuesta =
          jsonEncode({'promptFeedback': {'blockReason': 'SAFETY'}});

      await expectLater(
        preguntar(),
        throwsA(
          isA<ModeloDeLenguajeException>()
              .having((e) => e.mensaje, 'mensaje', contains('no quiso responder')),
        ),
      );
    });

    test('una respuesta cortada por el tope de tokens lo dice', () async {
      servidor.cuerpoDeRespuesta =
          _respuestaOk('{"grupos": [["e1",', finishReason: 'MAX_TOKENS');

      await expectLater(
        preguntar(),
        throwsA(
          isA<ModeloDeLenguajeException>()
              .having((e) => e.mensaje, 'mensaje', contains('se cortó')),
        ),
      );
    });

    test('sin candidatos o sin texto es una respuesta vacía', () async {
      servidor.cuerpoDeRespuesta = jsonEncode({'candidates': []});
      await expectLater(preguntar(), fallaSinCodigo('vacía'));

      servidor.cuerpoDeRespuesta = _respuestaOk('   ');
      await expectLater(preguntar(), fallaSinCodigo('vacía'));
    });

    test('si el servidor tarda más del tiempo máximo, avisa', () async {
      servidor.cuerpoDeRespuesta = _respuestaOk('{}');
      servidor.demora = const Duration(seconds: 2);

      await expectLater(
        preguntar(cliente(tiempoMaximo: const Duration(milliseconds: 300))),
        fallaSinCodigo('tardó demasiado'),
      );
    });

    test('sin conexión avisa que no hay conexión', () async {
      final puerto = servidor.puerto;
      await servidor.cerrar();

      await expectLater(
        preguntar(cliente(urlBase: 'http://127.0.0.1:$puerto/v1beta')),
        fallaSinCodigo('No hay conexión'),
      );
      // El tearDown vuelve a cerrar el servidor: no pasa nada.
    });
  });
}

Matcher fallaSinCodigo(String texto) {
  return throwsA(
    isA<ModeloDeLenguajeException>()
        .having((e) => e.mensaje, 'mensaje', contains(texto)),
  );
}
