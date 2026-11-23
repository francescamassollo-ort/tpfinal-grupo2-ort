import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/sugerencia_categoria.dart';
import 'package:tpfinal_grupo2/services/category_suggestion_service.dart';
import 'package:tpfinal_grupo2/services/modelo_de_lenguaje.dart';

Insumo _insumo(String nombre, {String? categoria}) => Insumo(
      id: nombre,
      nombre: nombre,
      tipo: InsumoTipo.comprado,
      stock: 10,
      ubicacion: 'Estante 1',
      umbralMinimo: 2,
      categoria: categoria,
    );

String? _categoria(String nombre, {String? formula, List<Insumo> insumos = const []}) =>
    CategorySuggestionService.sugerir(nombre, formula: formula, insumos: insumos)
        ?.categoria;

class _ModeloFalso implements ModeloDeLenguaje {
  _ModeloFalso(this.respuesta);

  final String respuesta;
  final consultas = <String>[];

  @override
  Future<String> responder({
    required String instrucciones,
    required String consulta,
  }) async {
    consultas.add(consulta);
    return respuesta;
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

void main() {
  group('a partir de insumos parecidos', () {
    final existentes = [
      _insumo('Agar LB', categoria: 'Medios de cultivo'),
      _insumo('Enzima Taq Polimerasa', categoria: 'Enzimas'),
      _insumo('Pipeta sin categoría'),
    ];

    test('el mismo nombre escrito distinto usa la categoría del existente', () {
      final s = CategorySuggestionService.sugerir('Agar l b', insumos: existentes)!;

      expect(s.categoria, 'Medios de cultivo');
      expect(s.origen, OrigenSugerencia.insumoParecido);
      expect(s.confianza, greaterThanOrEqualTo(0.8));
    });

    test('un nombre que contiene al existente también', () {
      expect(_categoria('Enzima Taq', insumos: existentes), 'Enzimas');
      expect(_categoria('Agar LB Miller', insumos: existentes), 'Medios de cultivo');
    });

    test('los insumos sin categoría no aportan nada', () {
      expect(
        CategorySuggestionService.sugerir('Pipeta sin categoría', insumos: existentes)
            ?.origen,
        isNot(OrigenSugerencia.insumoParecido),
      );
    });

    test('si hay varias categorías parecidas gana la más repetida', () {
      final insumos = [
        _insumo('Papel A', categoria: 'Papelería'),
        _insumo('Papel B', categoria: 'Material de oficina'),
        _insumo('Papel C', categoria: 'Material de oficina'),
      ];

      // "Papel" está en los tres: gana la categoría que más insumos aporta.
      expect(_categoria('Papel', insumos: insumos), 'Material de oficina');
    });

    test('lo ya existente tiene prioridad sobre las reglas', () {
      final insumos = [_insumo('Guantes de nitrilo', categoria: 'Bioseguridad')];

      expect(_categoria('Guantes de nitrilo', insumos: insumos), 'Bioseguridad');
    });
  });

  group('por reglas', () {
    const casos = {
      'Etanol 96%': 'Alcoholes y solventes',
      'Alcohol isopropílico': 'Alcoholes y solventes',
      'Glicerol': 'Alcoholes y solventes',
      'Enzima Taq Polimerasa': 'Enzimas',
      'Ligasa T4': 'Enzimas',
      'Agar nutritivo': 'Medios de cultivo',
      'Caldo LB': 'Medios de cultivo',
      'Buffer TAE 1x': 'Buffers y soluciones',
      'Tris-HCl': 'Buffers y soluciones',
      'Buffer para Taq': 'Buffers y soluciones',
      'Ácido acético': 'Ácidos y bases',
      'Hidróxido de sodio': 'Ácidos y bases',
      'Cloruro de sodio': 'Sales',
      'Aluminio Metalico': 'Metales',
      'Guantes de nitrilo': 'Material descartable',
      'Barbijo': 'Material descartable',
      'Cofias': 'Material descartable',
      'Algodon': 'Material descartable',
      'Tubo de ensayo': 'Material de vidrio',
      'Erlenmeyer 250 ml': 'Material de vidrio',
      'Cristal violeta': 'Colorantes',
    };

    for (final entrada in casos.entries) {
      test('"${entrada.key}" es ${entrada.value}', () {
        final s = CategorySuggestionService.sugerir(entrada.key)!;

        expect(s.categoria, entrada.value);
        expect(s.origen, OrigenSugerencia.reglas);
        expect(s.confianza, CategorySuggestionService.confianzaReglas);
      });
    }

    test('no distingue mayúsculas, tildes ni espacios', () {
      expect(_categoria('ÁCIDO   ACÉTICO'), 'Ácidos y bases');
      expect(_categoria('guantes DE nitrilo'), 'Material descartable');
    });

    test('con un nombre que ninguna regla conoce no sugiere nada', () {
      expect(CategorySuggestionService.sugerir('Equipo raro XJ-9'), isNull);
    });

    test('con un nombre muy corto o vacío no sugiere nada', () {
      expect(CategorySuggestionService.sugerir(''), isNull);
      expect(CategorySuggestionService.sugerir('ab'), isNull);
      expect(CategorySuggestionService.sugerir('  '), isNull);
    });

    test('si el laboratorio ya escribe la categoría distinto, usa su grafía', () {
      // Hay un insumo en "Enzima" (singular): no se crea "Enzimas" aparte.
      final insumos = [_insumo('Algo distinto', categoria: 'Enzima')];

      expect(_categoria('Ligasa T4', insumos: insumos), 'Enzima');
    });
  });

  group('por la fórmula', () {
    test('un ácido orgánico (COOH)', () {
      final s = CategorySuggestionService.sugerir('Producto X', formula: 'CH3COOH')!;

      expect(s.categoria, 'Ácidos y bases');
      expect(s.confianza, CategorySuggestionService.confianzaFormula);
    });

    test('una base (NaOH, KOH)', () {
      expect(_categoria('Producto X', formula: 'NaOH'), 'Ácidos y bases');
      expect(_categoria('Producto X', formula: 'KOH'), 'Ácidos y bases');
    });

    test('un ácido mineral (H2SO4, HCl)', () {
      expect(_categoria('Producto X', formula: 'H2SO4'), 'Ácidos y bases');
      expect(_categoria('Producto X', formula: 'HCl'), 'Ácidos y bases');
    });

    test('un alcohol (C2H5OH)', () {
      expect(_categoria('Producto X', formula: 'C2H5OH'), 'Alcoholes y solventes');
    });

    test('una fórmula que no dice nada no sugiere', () {
      expect(_categoria('Producto X', formula: 'NaCl'), isNull);
      expect(_categoria('Producto X', formula: ''), isNull);
    });

    test('el nombre manda sobre la fórmula', () {
      expect(_categoria('Agar nutritivo', formula: 'NaOH'), 'Medios de cultivo');
    });
  });

  group('con IA', () {
    test('sin modelo no hay IA', () async {
      final servicio = CategorySuggestionService();

      expect(servicio.tieneIa, isFalse);
      await expectLater(
        servicio.sugerirConIa('Algo'),
        throwsA(isA<ModeloDeLenguajeException>()),
      );
    });

    test('devuelve la categoría que elige el modelo', () async {
      final modelo = _ModeloFalso('{"categoria": "Material descartable"}');
      final servicio = CategorySuggestionService(modelo);

      final s = (await servicio.sugerirConIa('Tips 200 ul'))!;

      expect(servicio.tieneIa, isTrue);
      expect(s.categoria, 'Material descartable');
      expect(s.origen, OrigenSugerencia.ia);
      expect(s.confianza, CategorySuggestionService.confianzaIa);
    });

    test('le manda el nombre, la fórmula y las categorías existentes, sin repetir', () async {
      final modelo = _ModeloFalso('{"categoria": "Enzimas"}');

      await CategorySuggestionService(modelo).sugerirConIa(
        'Ligasa',
        formula: 'XYZ',
        categoriasExistentes: ['Enzimas', 'enzimas', 'Sales', ' '],
      );

      final consulta = modelo.consultas.single;
      expect(consulta, contains('Insumo: Ligasa'));
      expect(consulta, contains('Formula: XYZ'));
      expect(consulta, contains('Categorias existentes: Enzimas, Sales'));
    });

    test('si todavía no hay categorías lo dice', () async {
      final modelo = _ModeloFalso('{"categoria": "Sales"}');

      await CategorySuggestionService(modelo).sugerirConIa('Cloruro');

      expect(modelo.consultas.single, contains('(ninguna)'));
    });

    test('usa la grafía de la categoría que ya existe', () async {
      final modelo = _ModeloFalso('{"categoria": "enzimas"}');

      final s = await CategorySuggestionService(modelo).sugerirConIa(
        'Ligasa',
        categoriasExistentes: ['Enzimas'],
      );

      expect(s!.categoria, 'Enzimas');
    });

    test('si el modelo no sabe (categoría vacía) no sugiere nada', () async {
      final s = await CategorySuggestionService(_ModeloFalso('{"categoria": ""}'))
          .sugerirConIa('Algo');

      expect(s, isNull);
    });

    test('una categoría larguísima se descarta', () async {
      final larga = 'a' * 60;
      final s = await CategorySuggestionService(_ModeloFalso('{"categoria": "$larga"}'))
          .sugerirConIa('Algo');

      expect(s, isNull);
    });

    test('una respuesta que no es JSON es un error', () async {
      await expectLater(
        CategorySuggestionService(_ModeloFalso('no sé')).sugerirConIa('Algo'),
        throwsA(isA<ModeloDeLenguajeException>()),
      );
    });

    test('si el modelo falla, el error sale tal cual', () async {
      await expectLater(
        CategorySuggestionService(_ModeloQueFalla()).sugerirConIa('Algo'),
        throwsA(
          isA<ModeloDeLenguajeException>()
              .having((e) => e.mensaje, 'mensaje', 'sin conexión'),
        ),
      );
    });
  });
}
