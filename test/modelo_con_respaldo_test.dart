import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/providers/sinonimos_provider.dart';
import 'package:tpfinal_grupo2/services/gemini_client.dart';
import 'package:tpfinal_grupo2/services/groq_client.dart';
import 'package:tpfinal_grupo2/services/modelo_con_respaldo.dart';
import 'package:tpfinal_grupo2/services/modelo_de_lenguaje.dart';

/// Modelo falso: responde un texto o lanza el error que se le indique, y anota
/// cuántas veces lo consultaron.
class _Modelo implements ModeloDeLenguaje {
  _Modelo({this.texto = 'ok', this.error});

  final String texto;
  final Object? error;
  int consultas = 0;
  String? ultimaConsulta;

  @override
  Future<String> responder({
    required String instrucciones,
    required String consulta,
  }) async {
    consultas++;
    ultimaConsulta = consulta;
    if (error != null) throw error!;
    return texto;
  }
}

const _errorGemini = ModeloDeLenguajeException('límite de Gemini', codigo: 429);
const _errorGroq = ModeloDeLenguajeException('sin conexión con Groq');

Future<String> _preguntar(ModeloDeLenguaje modelo) {
  return modelo.responder(instrucciones: 'a', consulta: 'hola');
}

void main() {
  group('ModeloConRespaldo', () {
    test('si el principal responde, no se toca el respaldo', () async {
      final principal = _Modelo(texto: 'del principal');
      final respaldo = _Modelo(texto: 'del respaldo');

      final respuesta = await _preguntar(
        ModeloConRespaldo(principal: principal, respaldo: respaldo),
      );

      expect(respuesta, 'del principal');
      expect(respaldo.consultas, 0);
    });

    test('si el principal falla, responde el respaldo con la misma consulta',
        () async {
      final principal = _Modelo(error: _errorGemini);
      final respaldo = _Modelo(texto: 'del respaldo');

      final respuesta = await _preguntar(
        ModeloConRespaldo(principal: principal, respaldo: respaldo),
      );

      expect(respuesta, 'del respaldo');
      expect(principal.consultas, 1);
      expect(respaldo.consultas, 1);
      expect(respaldo.ultimaConsulta, 'hola');
    });

    test('si los dos fallan, lanza el error del principal', () async {
      final modelo = ModeloConRespaldo(
        principal: _Modelo(error: _errorGemini),
        respaldo: _Modelo(error: _errorGroq),
      );

      await expectLater(
        _preguntar(modelo),
        throwsA(
          isA<ModeloDeLenguajeException>()
              .having((e) => e.mensaje, 'mensaje', 'límite de Gemini')
              .having((e) => e.codigo, 'codigo', 429),
        ),
      );
    });

    test('un error que no es del modelo no se tapa con el respaldo', () async {
      final respaldo = _Modelo(texto: 'del respaldo');
      final modelo = ModeloConRespaldo(
        principal: _Modelo(error: StateError('bug')),
        respaldo: respaldo,
      );

      await expectLater(_preguntar(modelo), throwsA(isA<StateError>()));
      expect(respaldo.consultas, 0);
    });
  });

  group('elegirModeloDeLenguaje', () {
    test('sin ninguna clave no hay modelo', () {
      expect(
        elegirModeloDeLenguaje(hayClaveDeGemini: false, hayClaveDeGroq: false),
        isNull,
      );
    });

    test('solo con la de Gemini usa Gemini', () {
      expect(
        elegirModeloDeLenguaje(hayClaveDeGemini: true, hayClaveDeGroq: false),
        isA<GeminiClient>(),
      );
    });

    test('solo con la de Groq usa Groq', () {
      expect(
        elegirModeloDeLenguaje(hayClaveDeGemini: false, hayClaveDeGroq: true),
        isA<GroqClient>(),
      );
    });

    test('con las dos usa Gemini y deja a Groq de respaldo', () {
      final modelo = elegirModeloDeLenguaje(
        hayClaveDeGemini: true,
        hayClaveDeGroq: true,
      );

      expect(modelo, isA<ModeloConRespaldo>());
      final conRespaldo = modelo! as ModeloConRespaldo;
      expect(conRespaldo.principal, isA<GeminiClient>());
      expect(conRespaldo.respaldo, isA<GroqClient>());
    });
  });
}
