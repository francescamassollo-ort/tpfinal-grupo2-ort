import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/hallazgo.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/providers/hallazgos_provider.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/sinonimos_provider.dart';
import 'package:tpfinal_grupo2/services/modelo_de_lenguaje.dart';

class _ModeloFalso implements ModeloDeLenguaje {
  _ModeloFalso(this.respuesta);

  final String respuesta;
  int consultas = 0;

  @override
  Future<String> responder({
    required String instrucciones,
    required String consulta,
  }) async {
    consultas++;
    return respuesta;
  }
}

class _ModeloQueFalla implements ModeloDeLenguaje {
  @override
  Future<String> responder({
    required String instrucciones,
    required String consulta,
  }) async {
    throw const ModeloDeLenguajeException('límite alcanzado');
  }
}

Insumo _insumo(String id, String nombre, {int stock = 10}) {
  return Insumo(
    id: id,
    nombre: nombre,
    tipo: InsumoTipo.comprado,
    stock: stock,
    ubicacion: 'Estante A',
    umbralMinimo: 5,
  );
}

/// Arma el contenedor con insumos y un modelo falsos. Deja escuchando a los
/// insumos, como lo haría una pantalla, y espera a que lleguen. Si [insumos]
/// es null, el stream nunca emite: así se simula que todavía no se cargaron.
Future<ProviderContainer> _contenedor({
  required List<Insumo>? insumos,
  required ModeloDeLenguaje? modelo,
}) async {
  final contenedor = ProviderContainer(
    overrides: [
      insumosProvider.overrideWith(
        (ref) => insumos == null
            ? StreamController<List<Insumo>>().stream
            : Stream.value(insumos),
      ),
      modeloDeLenguajeProvider.overrideWithValue(modelo),
    ],
  );
  addTearDown(contenedor.dispose);

  contenedor.listen(insumosProvider, (_, _) {});
  contenedor.listen(sinonimosProvider, (_, _) {});
  if (insumos != null) await contenedor.read(insumosProvider.future);
  return contenedor;
}

void main() {
  final insumos = [
    _insumo('a', 'Etanol 96%'),
    _insumo('b', 'Alcohol etílico 96 grados'),
    _insumo('c', 'Guantes de nitrilo'),
  ];

  test('al principio no hay nada analizado ni se consulta al modelo', () async {
    final modelo = _ModeloFalso('{"grupos":[["e1","e2"]]}');
    final contenedor = await _contenedor(insumos: insumos, modelo: modelo);

    expect(contenedor.read(sinonimosProvider).value, isEmpty);
    expect(modelo.consultas, 0);
  });

  test('analizar trae los sinónimos del modelo', () async {
    final modelo = _ModeloFalso('{"grupos":[["e1","e2"]]}');
    final contenedor = await _contenedor(insumos: insumos, modelo: modelo);

    await contenedor.read(sinonimosProvider.notifier).analizar();

    final hallazgos = contenedor.read(sinonimosProvider).requireValue;
    expect(hallazgos, hasLength(1));
    expect(hallazgos.first.tipo, TipoHallazgo.sinonimoProbable);
    expect(hallazgos.first.insumoIds, ['a', 'b']);
    expect(modelo.consultas, 1);
  });

  test('no repite un par que la comparación de texto ya encontró', () async {
    // "Etanol 96%" y "etanol 96 %" ya son un duplicado exacto por texto.
    final iguales = [_insumo('a', 'Etanol 96%'), _insumo('b', 'etanol 96 %')];
    final modelo = _ModeloFalso('{"grupos":[["e1","e2"]]}');
    final contenedor = await _contenedor(insumos: iguales, modelo: modelo);

    await contenedor.read(sinonimosProvider.notifier).analizar();

    expect(contenedor.read(sinonimosProvider).requireValue, isEmpty);
  });

  test('sin clave, analizar deja un error claro y no consulta nada', () async {
    final contenedor = await _contenedor(insumos: insumos, modelo: null);

    await contenedor.read(sinonimosProvider.notifier).analizar();

    final estado = contenedor.read(sinonimosProvider);
    expect(estado.hasError, isTrue);
    expect(
      (estado.error as ModeloDeLenguajeException).mensaje,
      contains('clave'),
    );
  });

  test('si los insumos todavía no llegaron, avisa en vez de esperar', () async {
    final modelo = _ModeloFalso('{"grupos":[]}');
    final contenedor = await _contenedor(insumos: null, modelo: modelo);

    await contenedor.read(sinonimosProvider.notifier).analizar();

    final estado = contenedor.read(sinonimosProvider);
    expect(estado.hasError, isTrue);
    expect(
      (estado.error as ModeloDeLenguajeException).mensaje,
      contains('insumos'),
    );
    expect(modelo.consultas, 0);
  });

  test('si el modelo falla, el estado queda en error con su mensaje', () async {
    final contenedor =
        await _contenedor(insumos: insumos, modelo: _ModeloQueFalla());

    await contenedor.read(sinonimosProvider.notifier).analizar();

    final estado = contenedor.read(sinonimosProvider);
    expect(estado.hasError, isTrue);
    expect(
      (estado.error as ModeloDeLenguajeException).mensaje,
      'límite alcanzado',
    );
  });

  test('mientras espera la respuesta, el estado es "cargando"', () async {
    final modelo = _ModeloFalso('{"grupos":[]}');
    final contenedor = await _contenedor(insumos: insumos, modelo: modelo);

    final espera = contenedor.read(sinonimosProvider.notifier).analizar();

    expect(contenedor.read(sinonimosProvider).isLoading, isTrue);
    await espera;
    expect(contenedor.read(sinonimosProvider).isLoading, isFalse);
  });

  test('hallazgosCompletos junta lo de texto con lo del modelo', () async {
    final conInconsistencia = [
      _insumo('a', 'Etanol 96%', stock: -1),
      _insumo('b', 'Alcohol etílico 96 grados'),
    ];
    final modelo = _ModeloFalso('{"grupos":[["e1","e2"]]}');
    final contenedor =
        await _contenedor(insumos: conInconsistencia, modelo: modelo);

    await contenedor.read(sinonimosProvider.notifier).analizar();

    final tipos = contenedor
        .read(hallazgosCompletosProvider)
        .requireValue
        .map((h) => h.tipo)
        .toList();
    expect(tipos, contains(TipoHallazgo.stockNegativo));
    expect(tipos, contains(TipoHallazgo.sinonimoProbable));
  });

  test('sin analizar, hallazgosCompletos son solo los de texto', () async {
    final modelo = _ModeloFalso('{"grupos":[["e1","e2"]]}');
    final contenedor = await _contenedor(insumos: insumos, modelo: modelo);

    expect(
      contenedor.read(hallazgosCompletosProvider).requireValue,
      contenedor.read(hallazgosProvider).requireValue,
    );
    expect(modelo.consultas, 0);
  });
}
