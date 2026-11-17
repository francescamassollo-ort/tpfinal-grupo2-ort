import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/services/similitud_texto.dart';

void main() {
  group('normalizar', () {
    test('pasa a minúscula y saca tildes, espacios y signos', () {
      expect(SimilitudTexto.normalizar('Ácido Acético'), 'acidoacetico');
    });

    test('"Etanol 96%" y "etanol 96 %" dan lo mismo', () {
      expect(
        SimilitudTexto.normalizar('Etanol 96%'),
        SimilitudTexto.normalizar('etanol 96 %'),
      );
    });

    test('convierte la ñ en n', () {
      expect(SimilitudTexto.normalizar('Añejo'), 'anejo');
    });

    test('un texto sin letras ni números queda vacío', () {
      expect(SimilitudTexto.normalizar(' -- % '), '');
    });
  });

  group('numerosEn', () {
    test('encuentra los números en orden', () {
      expect(SimilitudTexto.numerosEn('Buffer TAE 1x pH 8'), ['1', '8']);
    });

    test('toma la coma decimal como punto', () {
      expect(SimilitudTexto.numerosEn('NaCl 0,5 M'), ['0.5']);
    });

    test('devuelve vacío si no hay números', () {
      expect(SimilitudTexto.numerosEn('Agar LB'), isEmpty);
    });
  });

  group('distancia', () {
    test('textos iguales: 0', () {
      expect(SimilitudTexto.distancia('agar', 'agar'), 0);
    });

    test('cuenta una letra de diferencia', () {
      expect(SimilitudTexto.distancia('agar', 'agor'), 1);
    });

    test('con un texto vacío es el largo del otro', () {
      expect(SimilitudTexto.distancia('', 'agar'), 4);
      expect(SimilitudTexto.distancia('agar', ''), 4);
    });

    test('es simétrica', () {
      expect(
        SimilitudTexto.distancia('buffer', 'bufer'),
        SimilitudTexto.distancia('bufer', 'buffer'),
      );
    });
  });

  group('entreNombres', () {
    test('nombres iguales una vez normalizados: 1', () {
      expect(SimilitudTexto.entreNombres('Etanol 96%', 'etanol 96 %'), 1);
    });

    test('un error de tipeo da un parecido alto', () {
      // "tubos falcon" contra "tubos falcn": 1 letra de 12.
      expect(
        SimilitudTexto.entreNombres('Tubos Falcon', 'Tubos Falcn'),
        greaterThan(0.85),
      );
    });

    test('nombres distintos dan un parecido bajo', () {
      expect(
        SimilitudTexto.entreNombres('Agar LB', 'Guantes de nitrilo'),
        lessThan(0.5),
      );
    });

    test('si los números difieren, no son parecidos aunque el texto sí', () {
      expect(SimilitudTexto.entreNombres('Ácido acético 1M', 'Ácido acético 2M'), 0);
    });

    test('con los mismos números sí se comparan', () {
      expect(
        SimilitudTexto.entreNombres('Acido acetico 1M', 'Ácido acético 1 M'),
        1,
      );
    });

    test('dos textos vacíos no tienen parecido', () {
      expect(SimilitudTexto.entreNombres('', ' '), 0);
    });
  });
}
