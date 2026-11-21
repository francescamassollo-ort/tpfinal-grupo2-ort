import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/hallazgo.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/services/modelo_de_lenguaje.dart';
import 'package:tpfinal_grupo2/services/synonym_detection_service.dart';

/// Un modelo de lenguaje falso: devuelve lo que se le indique y anota qué se
/// le consultó. No llama a ningún servicio.
class _ModeloFalso implements ModeloDeLenguaje {
  _ModeloFalso(this.respuestas);

  final List<String> respuestas;
  final consultas = <String>[];
  String? ultimasInstrucciones;

  @override
  Future<String> responder({
    required String instrucciones,
    required String consulta,
  }) async {
    ultimasInstrucciones = instrucciones;
    consultas.add(consulta);
    return respuestas[(consultas.length - 1).clamp(0, respuestas.length - 1)];
  }
}

class _ModeloQueFalla implements ModeloDeLenguaje {
  @override
  Future<String> responder({
    required String instrucciones,
    required String consulta,
  }) async {
    throw const ModeloDeLenguajeException('sin conexión');
  }
}

Insumo _insumo(
  String id,
  String nombre, {
  InsumoTipo tipo = InsumoTipo.comprado,
  String? marca,
}) {
  return Insumo(
    id: id,
    nombre: nombre,
    tipo: tipo,
    stock: 10,
    ubicacion: 'Estante A',
    umbralMinimo: 5,
    marca: marca,
  );
}

void main() {
  group('buscar', () {
    test('convierte los grupos del modelo en hallazgos', () async {
      final modelo = _ModeloFalso(['{"grupos":[["e1","e2"]]}']);
      final servicio = SynonymDetectionService(modelo);

      final hallazgos = await servicio.buscar([
        _insumo('a', 'Etanol 96%'),
        _insumo('b', 'Alcohol etílico 96 grados'),
        _insumo('c', 'Guantes'),
      ]);

      expect(hallazgos, hasLength(1));
      expect(hallazgos.first.tipo, TipoHallazgo.sinonimoProbable);
      expect(hallazgos.first.insumoIds, ['a', 'b']);
      expect(hallazgos.first.confianza, SynonymDetectionService.confianzaDelModelo);
    });

    test('un grupo de tres da los tres pares', () async {
      final modelo = _ModeloFalso(['{"grupos":[["e1","e2","e3"]]}']);

      final hallazgos = await SynonymDetectionService(modelo).buscar([
        _insumo('a', 'Etanol'),
        _insumo('b', 'Alcohol etílico'),
        _insumo('c', 'Alcohol'),
      ]);

      expect(hallazgos, hasLength(3));
    });

    test('manda solo los nombres, con ids cortos', () async {
      final modelo = _ModeloFalso(['{"grupos":[]}']);

      await SynonymDetectionService(modelo).buscar([
        _insumo('id-largo-de-firestore-1', 'Etanol'),
        _insumo('id-largo-de-firestore-2', 'Agar'),
      ]);

      expect(modelo.consultas.single, 'e1: Etanol\ne2: Agar');
      expect(modelo.consultas.single.contains('firestore'), isFalse);
    });

    test('descarta a los que tienen números distintos', () async {
      final modelo = _ModeloFalso(['{"grupos":[["e1","e2"]]}']);

      final hallazgos = await SynonymDetectionService(modelo).buscar([
        _insumo('a', 'Ácido acético 1M'),
        _insumo('b', 'Vinagre de laboratorio 2M'),
      ]);

      expect(hallazgos, isEmpty);
    });

    test('descarta a los de marcas distintas', () async {
      final modelo = _ModeloFalso(['{"grupos":[["e1","e2"]]}']);

      final hallazgos = await SynonymDetectionService(modelo).buscar([
        _insumo('a', 'Etanol', marca: 'Merck'),
        _insumo('b', 'Alcohol etílico', marca: 'Biopack'),
      ]);

      expect(hallazgos, isEmpty);
    });

    test('ignora ids que el modelo se inventó', () async {
      final modelo = _ModeloFalso(['{"grupos":[["e1","e99"],["e1","e2"]]}']);

      final hallazgos = await SynonymDetectionService(modelo).buscar([
        _insumo('a', 'Etanol'),
        _insumo('b', 'Alcohol etílico'),
      ]);

      expect(hallazgos, hasLength(1));
      expect(hallazgos.first.insumoIds, ['a', 'b']);
    });

    test('un mismo par en dos grupos se cuenta una sola vez', () async {
      final modelo = _ModeloFalso(['{"grupos":[["e1","e2"],["e2","e1"]]}']);

      final hallazgos = await SynonymDetectionService(modelo).buscar([
        _insumo('a', 'Etanol'),
        _insumo('b', 'Alcohol etílico'),
      ]);

      expect(hallazgos, hasLength(1));
    });

    test('entiende la respuesta aunque venga con texto alrededor', () async {
      final modelo = _ModeloFalso(['Claro: {"grupos":[["e1","e2"]]} Listo.']);

      final hallazgos = await SynonymDetectionService(modelo).buscar([
        _insumo('a', 'Etanol'),
        _insumo('b', 'Alcohol etílico'),
      ]);

      expect(hallazgos, hasLength(1));
    });

    test('sin grupos no hay hallazgos', () async {
      final modelo = _ModeloFalso(['{"grupos":[]}']);

      final hallazgos = await SynonymDetectionService(modelo).buscar([
        _insumo('a', 'Etanol'),
        _insumo('b', 'Agar'),
      ]);

      expect(hallazgos, isEmpty);
    });
  });

  group('casos en los que no hay que molestar al modelo', () {
    test('con menos de dos insumos no se consulta', () async {
      final modelo = _ModeloFalso(['{"grupos":[]}']);

      await SynonymDetectionService(modelo).buscar([_insumo('a', 'Etanol')]);
      await SynonymDetectionService(modelo).buscar(const []);

      expect(modelo.consultas, isEmpty);
    });

    test('se consulta por separado cada tipo de insumo', () async {
      final modelo = _ModeloFalso(['{"grupos":[]}']);

      await SynonymDetectionService(modelo).buscar([
        _insumo('a', 'Etanol'),
        _insumo('b', 'Agar'),
        _insumo('c', 'Etanol 70%', tipo: InsumoTipo.solucion),
        _insumo('d', 'Buffer', tipo: InsumoTipo.solucion),
      ]);

      expect(modelo.consultas, hasLength(2));
    });

    test('un tipo con un solo insumo no se consulta', () async {
      final modelo = _ModeloFalso(['{"grupos":[]}']);

      await SynonymDetectionService(modelo).buscar([
        _insumo('a', 'Etanol'),
        _insumo('b', 'Agar'),
        _insumo('c', 'Etanol 70%', tipo: InsumoTipo.solucion),
      ]);

      expect(modelo.consultas, hasLength(1));
    });

    test('si hay más de la cuenta, se parte en tandas', () async {
      final modelo = _ModeloFalso(['{"grupos":[]}']);
      final muchos = [
        for (var i = 0; i < SynonymDetectionService.maxInsumosPorConsulta + 10; i++)
          _insumo('id$i', 'Insumo $i'),
      ];

      await SynonymDetectionService(modelo).buscar(muchos);

      // 260 insumos: una tanda de 250 y otra de 10.
      expect(modelo.consultas, hasLength(2));
    });
  });

  group('errores', () {
    test('si el modelo falla, el error se propaga', () async {
      await expectLater(
        SynonymDetectionService(_ModeloQueFalla()).buscar([
          _insumo('a', 'Etanol'),
          _insumo('b', 'Agar'),
        ]),
        throwsA(isA<ModeloDeLenguajeException>()),
      );
    });

    test('una respuesta que no es JSON es un error claro', () async {
      final modelo = _ModeloFalso(['no sé qué decirte']);

      await expectLater(
        SynonymDetectionService(modelo).buscar([
          _insumo('a', 'Etanol'),
          _insumo('b', 'Agar'),
        ]),
        throwsA(
          isA<ModeloDeLenguajeException>()
              .having((e) => e.mensaje, 'mensaje', contains('formato')),
        ),
      );
    });

    test('un JSON con otra forma es un error claro', () async {
      final modelo = _ModeloFalso(['{"resultado": "ok"}']);

      await expectLater(
        SynonymDetectionService(modelo).buscar([
          _insumo('a', 'Etanol'),
          _insumo('b', 'Agar'),
        ]),
        throwsA(isA<ModeloDeLenguajeException>()),
      );
    });
  });

  group('sinRepetir', () {
    const exacto = Hallazgo(
      tipo: TipoHallazgo.duplicadoExacto,
      insumoIds: ['b', 'a'],
    );

    test('saca los pares que ya estaban, en cualquier orden', () {
      const sugerido = Hallazgo(
        tipo: TipoHallazgo.sinonimoProbable,
        insumoIds: ['a', 'b'],
        confianza: 0.8,
      );

      expect(SynonymDetectionService.sinRepetir([sugerido], [exacto]), isEmpty);
    });

    test('deja los pares nuevos', () {
      const sugerido = Hallazgo(
        tipo: TipoHallazgo.sinonimoProbable,
        insumoIds: ['a', 'c'],
        confianza: 0.8,
      );

      expect(
        SynonymDetectionService.sinRepetir([sugerido], [exacto]),
        [sugerido],
      );
    });
  });

  test('las instrucciones piden JSON y aclaran lo de los números', () {
    expect(SynonymDetectionService.instrucciones, contains('JSON'));
    expect(SynonymDetectionService.instrucciones, contains('numero distinto'));
  });

  test('un sinónimo cuenta como duplicado', () {
    expect(TipoHallazgo.sinonimoProbable.esDuplicado, isTrue);
  });
}
