import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/services/groq_client.dart';
import 'package:tpfinal_grupo2/services/modelo_de_lenguaje.dart';

/// Un servidor falso en la propia computadora: así se prueba el cliente sin
/// llamar a Groq de verdad ni gastar cuota.
class _ServidorFalso {
  late final HttpServer _servidor;
  int estado = 200;
  String cuerpoDeRespuesta = '';
  Map<String, dynamic>? pedidoRecibido;
  String? autorizacionRecibida;
  int cantidadDePedidos = 0;

  String get urlBase => 'http://127.0.0.1:${_servidor.port}/v1';

  Future<void> iniciar() async {
    _servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _servidor.listen((pedido) async {
      cantidadDePedidos++;
      autorizacionRecibida =
          pedido.headers.value(HttpHeaders.authorizationHeader);
      final texto = await utf8.decoder.bind(pedido).join();
      pedidoRecibido = jsonDecode(texto) as Map<String, dynamic>;

      pedido.response
        ..statusCode = estado
        ..headers.contentType = ContentType.json
        ..write(cuerpoDeRespuesta);
      await pedido.response.close();
    });
  }

  Future<void> cerrar() => _servidor.close(force: true);
}

String _respuestaOk(String contenido) => jsonEncode({
      'choices': [
        {
          'message': {'role': 'assistant', 'content': contenido},
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

  GroqClient cliente({String clave = 'clave-falsa', String modelo = 'openai/gpt-oss-20b'}) {
    return GroqClient(
      apiKey: clave,
      modelo: modelo,
      urlBase: servidor.urlBase,
      tiempoMaximo: const Duration(seconds: 5),
    );
  }

  test('devuelve el contenido de la respuesta', () async {
    servidor.cuerpoDeRespuesta = _respuestaOk('{"grupos":[]}');

    final respuesta = await cliente().responder(
      instrucciones: 'Sé breve',
      consulta: 'hola',
    );

    expect(respuesta, '{"grupos":[]}');
  });

  test('manda la clave, el modelo, las consignas y pide JSON', () async {
    servidor.cuerpoDeRespuesta = _respuestaOk('{}');

    await cliente().responder(instrucciones: 'Sé breve', consulta: 'hola');

    expect(servidor.autorizacionRecibida, 'Bearer clave-falsa');
    final pedido = servidor.pedidoRecibido!;
    expect(pedido['model'], 'openai/gpt-oss-20b');
    expect(pedido['temperature'], 0);
    expect(pedido['response_format'], {'type': 'json_object'});
    expect(pedido['messages'], [
      {'role': 'system', 'content': 'Sé breve'},
      {'role': 'user', 'content': 'hola'},
    ]);
  });

  test('con un modelo gpt-oss pide razonar poco', () async {
    servidor.cuerpoDeRespuesta = _respuestaOk('{}');

    await cliente().responder(instrucciones: 'a', consulta: 'b');

    expect(servidor.pedidoRecibido!['reasoning_effort'], 'low');
  });

  test('con otro modelo no manda el ajuste de razonamiento', () async {
    servidor.cuerpoDeRespuesta = _respuestaOk('{}');

    await cliente(modelo: 'qwen/qwen3.8-27b')
        .responder(instrucciones: 'a', consulta: 'b');

    expect(servidor.pedidoRecibido!.containsKey('reasoning_effort'), isFalse);
  });

  test('sin clave falla sin llamar al servidor', () async {
    await expectLater(
      cliente(clave: '').responder(instrucciones: 'a', consulta: 'b'),
      throwsA(isA<ModeloDeLenguajeException>()),
    );

    expect(servidor.cantidadDePedidos, 0);
  });

  test('un 401 dice que la clave no es válida', () async {
    servidor.estado = 401;
    servidor.cuerpoDeRespuesta = '{"error":{"message":"Invalid API Key"}}';

    await expectLater(
      cliente().responder(instrucciones: 'a', consulta: 'b'),
      throwsA(
        isA<ModeloDeLenguajeException>()
            .having((e) => e.codigo, 'codigo', 401)
            .having((e) => e.mensaje, 'mensaje', contains('no es válida')),
      ),
    );
  });

  test('un 429 dice que se alcanzó el límite', () async {
    servidor.estado = 429;
    servidor.cuerpoDeRespuesta = '{"error":{"message":"rate limit"}}';

    await expectLater(
      cliente().responder(instrucciones: 'a', consulta: 'b'),
      throwsA(
        isA<ModeloDeLenguajeException>()
            .having((e) => e.codigo, 'codigo', 429)
            .having((e) => e.mensaje, 'mensaje', contains('límite')),
      ),
    );
  });

  test('otro error incluye el detalle que explica el servidor', () async {
    servidor.estado = 400;
    servidor.cuerpoDeRespuesta = '{"error":{"message":"modelo inexistente"}}';

    await expectLater(
      cliente().responder(instrucciones: 'a', consulta: 'b'),
      throwsA(
        isA<ModeloDeLenguajeException>()
            .having((e) => e.mensaje, 'mensaje', contains('modelo inexistente')),
      ),
    );
  });

  test('una respuesta vacía o rara es un error', () async {
    servidor.cuerpoDeRespuesta = '{"choices":[]}';

    await expectLater(
      cliente().responder(instrucciones: 'a', consulta: 'b'),
      throwsA(isA<ModeloDeLenguajeException>()),
    );
  });

  test('si el servidor no existe, avisa que no hay conexión', () async {
    final sinServidor = GroqClient(
      apiKey: 'clave-falsa',
      urlBase: 'http://127.0.0.1:1/v1',
      tiempoMaximo: const Duration(seconds: 3),
    );

    await expectLater(
      sinServidor.responder(instrucciones: 'a', consulta: 'b'),
      throwsA(isA<ModeloDeLenguajeException>()),
    );
  });

  test('ningún mensaje de error contiene la clave', () async {
    servidor.estado = 400;
    servidor.cuerpoDeRespuesta = '{"error":{"message":"algo falló"}}';

    try {
      await cliente(clave: 'clave-secreta-de-prueba')
          .responder(instrucciones: 'a', consulta: 'b');
      fail('tenía que fallar');
    } on ModeloDeLenguajeException catch (e) {
      expect(e.toString().contains('clave-secreta-de-prueba'), isFalse);
    }
  });
}
