import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/services/ocr_service.dart';

class _LectorFalso implements LectorDeTexto {
  _LectorFalso(this.texto, {this.falla = false});

  final String texto;
  final bool falla;
  final rutas = <String>[];

  @override
  Future<String> leer(String rutaImagen) async {
    rutas.add(rutaImagen);
    if (falla) throw Exception('el reconocedor se cayó');
    return texto;
  }
}

const _etiquetaConCas = '''
ETANOL ABSOLUTO
CAS 64-17-5
Venc: 11/2027
''';

void main() {
  test('lee la etiqueta de la imagen que se le indica', () async {
    final lector = _LectorFalso(_etiquetaConCas);
    final ocr = OcrService(lector: lector, buscarQuimica: (_) async => null);

    final etiqueta = await ocr.leerEtiqueta('/tmp/foto.jpg');

    expect(lector.rutas, ['/tmp/foto.jpg']);
    expect(etiqueta.nombre, 'Etanol absoluto');
    expect(etiqueta.fechaVencimiento, DateTime(2027, 11, 30));
  });

  test('con un CAS, le pide la fórmula y el peso a PubChem', () async {
    final pedidos = <String>[];
    final ocr = OcrService(
      lector: _LectorFalso(_etiquetaConCas),
      buscarQuimica: (nombreOCas) async {
        pedidos.add(nombreOCas);
        return (formula: 'C2H6O', pesoMolecular: 46.07);
      },
    );

    final etiqueta = await ocr.leerEtiqueta('x.jpg');

    expect(pedidos, ['64-17-5']);
    expect(etiqueta.formula, 'C2H6O');
    expect(etiqueta.pesoMolecular, 46.07);
  });

  test('lo que la etiqueta ya dice no se pisa con lo de PubChem', () async {
    final ocr = OcrService(
      lector: _LectorFalso('Etanol\nCAS 64-17-5\nFormula: CH3CH2OH'),
      buscarQuimica: (_) async => (formula: 'C2H6O', pesoMolecular: 46.07),
    );

    final etiqueta = await ocr.leerEtiqueta('x.jpg');

    // La fórmula es la de la etiqueta; el peso, que faltaba, es el de PubChem.
    expect(etiqueta.formula, 'CH3CH2OH');
    expect(etiqueta.pesoMolecular, 46.07);
  });

  test('si la etiqueta ya trae todo, no consulta a PubChem', () async {
    var consultas = 0;
    final ocr = OcrService(
      lector: _LectorFalso('Etanol\nCAS 64-17-5\nFormula: C2H6O\nPM 46,07'),
      buscarQuimica: (_) async {
        consultas++;
        return null;
      },
    );

    await ocr.leerEtiqueta('x.jpg');

    expect(consultas, 0);
  });

  test('sin CAS no consulta a PubChem', () async {
    var consultas = 0;
    final ocr = OcrService(
      lector: _LectorFalso('Agar LB\nVenc 11/2027'),
      buscarQuimica: (_) async {
        consultas++;
        return null;
      },
    );

    await ocr.leerEtiqueta('x.jpg');

    expect(consultas, 0);
  });

  test('si PubChem no reconoce el CAS, queda lo que dice la etiqueta', () async {
    final ocr = OcrService(
      lector: _LectorFalso(_etiquetaConCas),
      buscarQuimica: (_) async => null,
    );

    final etiqueta = await ocr.leerEtiqueta('x.jpg');

    expect(etiqueta.nombre, 'Etanol absoluto');
    expect(etiqueta.formula, isNull);
  });

  test('si PubChem falla, no se pierde lo leído', () async {
    final ocr = OcrService(
      lector: _LectorFalso(_etiquetaConCas),
      buscarQuimica: (_) async => throw Exception('sin conexión'),
    );

    final etiqueta = await ocr.leerEtiqueta('x.jpg');

    expect(etiqueta.nombre, 'Etanol absoluto');
    expect(etiqueta.cas, '64-17-5');
  });

  test('si el reconocedor falla, avisa con un mensaje claro', () async {
    final ocr = OcrService(
      lector: _LectorFalso('', falla: true),
      buscarQuimica: (_) async => null,
    );

    await expectLater(
      ocr.leerEtiqueta('x.jpg'),
      throwsA(
        isA<OcrException>()
            .having((e) => e.mensaje, 'mensaje', 'No se pudo leer la etiqueta')
            .having((e) => e.toString(), 'toString', isNot(contains('se cayó'))),
      ),
    );
  });

  test('una imagen sin texto da una etiqueta vacía, no un error', () async {
    final ocr = OcrService(
      lector: _LectorFalso(''),
      buscarQuimica: (_) async => null,
    );

    final etiqueta = await ocr.leerEtiqueta('x.jpg');

    expect(etiqueta.vacia, isTrue);
  });
}
