import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/sinonimos_provider.dart';
import 'package:tpfinal_grupo2/screens/inventario/insumo_alta_screen.dart';
import 'package:tpfinal_grupo2/screens/inventario/sugerencia_de_categoria.dart';
import 'package:tpfinal_grupo2/services/modelo_de_lenguaje.dart';

class _ModeloFalso implements ModeloDeLenguaje {
  _ModeloFalso(this.respuesta);

  String respuesta;
  Completer<void>? espera;
  final consultas = <String>[];

  @override
  Future<String> responder({
    required String instrucciones,
    required String consulta,
  }) async {
    consultas.add(consulta);
    if (espera != null) await espera!.future;
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

Insumo _insumo(String nombre, {String? categoria}) => Insumo(
      id: nombre,
      nombre: nombre,
      tipo: InsumoTipo.comprado,
      stock: 10,
      ubicacion: 'Estante 1',
      umbralMinimo: 2,
      categoria: categoria,
    );

class _Controles {
  final nombre = TextEditingController();
  final formula = TextEditingController();
  final categoria = TextEditingController();
}

// Monta solo el widget, con tres campos de mentira, sin Firebase.
Future<_Controles> _abrir(
  WidgetTester tester, {
  List<Insumo> insumos = const [],
  ModeloDeLenguaje? modelo,
}) async {
  final c = _Controles();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        insumosProvider.overrideWith((ref) => Stream.value(insumos)),
        modeloDeLenguajeProvider.overrideWithValue(modelo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SugerenciaDeCategoria(
            nombreController: c.nombre,
            formulaController: c.formula,
            categoriaController: c.categoria,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return c;
}

Future<void> _escribir(WidgetTester tester, TextEditingController c, String t) async {
  c.text = t;
  await tester.pump();
}

void main() {
  group('lo que se sabe sin internet', () {
    testWidgets('sin nombre no muestra nada', (tester) async {
      await _abrir(tester);

      expect(find.textContaining('Categoría sugerida'), findsNothing);
    });

    testWidgets('con un nombre muy corto no muestra nada', (tester) async {
      final c = await _abrir(tester);

      await _escribir(tester, c.nombre, 'ab');

      expect(find.textContaining('Categoría sugerida'), findsNothing);
    });

    testWidgets('sugiere por las reglas del nombre', (tester) async {
      final c = await _abrir(tester);

      await _escribir(tester, c.nombre, 'Etanol 96%');

      expect(
        find.text('Categoría sugerida: Alcoholes y solventes (por el nombre)'),
        findsOneWidget,
      );
    });

    testWidgets('prefiere la categoría de un insumo parecido', (tester) async {
      final c = await _abrir(
        tester,
        insumos: [_insumo('Agar LB', categoria: 'Medios')],
      );

      await _escribir(tester, c.nombre, 'Agar l b');

      expect(
        find.text('Categoría sugerida: Medios (según un insumo parecido)'),
        findsOneWidget,
      );
    });

    testWidgets('la fórmula también cuenta', (tester) async {
      final c = await _abrir(tester);

      await _escribir(tester, c.nombre, 'Producto X');
      await _escribir(tester, c.formula, 'NaOH');

      expect(
        find.textContaining('Categoría sugerida: Ácidos y bases'),
        findsOneWidget,
      );
    });

    testWidgets('"Usar" copia la categoría al campo y deja de sugerir', (tester) async {
      final c = await _abrir(tester);
      await _escribir(tester, c.nombre, 'Guantes de nitrilo');

      await tester.tap(find.text('Usar'));
      await tester.pump();

      expect(c.categoria.text, 'Material descartable');
      expect(find.textContaining('Categoría sugerida'), findsNothing);
    });

    testWidgets('si ya hay algo escrito en Categoría no sugiere', (tester) async {
      final c = await _abrir(tester);
      c.categoria.text = 'Otra cosa';

      await _escribir(tester, c.nombre, 'Etanol 96%');

      expect(find.textContaining('Categoría sugerida'), findsNothing);
    });

    testWidgets('si se borra la categoría vuelve a sugerir', (tester) async {
      final c = await _abrir(tester);
      c.categoria.text = 'Otra cosa';
      await _escribir(tester, c.nombre, 'Etanol 96%');

      await _escribir(tester, c.categoria, '');

      expect(find.textContaining('Categoría sugerida'), findsOneWidget);
    });
  });

  group('con IA', () {
    testWidgets('si las reglas saben no ofrece IA', (tester) async {
      final c = await _abrir(tester, modelo: _ModeloFalso('{}'));

      await _escribir(tester, c.nombre, 'Etanol 96%');

      expect(find.text('Sugerir categoría con IA'), findsNothing);
    });

    testWidgets('sin modelo configurado no ofrece IA', (tester) async {
      final c = await _abrir(tester);

      await _escribir(tester, c.nombre, 'Equipo raro XJ-9');

      expect(find.text('Sugerir categoría con IA'), findsNothing);
    });

    testWidgets('si nadie sabe y hay modelo, ofrece preguntarle', (tester) async {
      final c = await _abrir(tester, modelo: _ModeloFalso('{}'));

      await _escribir(tester, c.nombre, 'Equipo raro XJ-9');

      expect(find.text('Sugerir categoría con IA'), findsOneWidget);
    });

    testWidgets('mientras no se toca no se consulta nada', (tester) async {
      final modelo = _ModeloFalso('{"categoria": "Equipos"}');
      final c = await _abrir(tester, modelo: modelo);

      await _escribir(tester, c.nombre, 'Equipo raro XJ-9');

      expect(modelo.consultas, isEmpty);
    });

    testWidgets('al tocar, consulta y muestra lo que sugiere, marcado como IA',
        (tester) async {
      final modelo = _ModeloFalso('{"categoria": "Equipos"}');
      final c = await _abrir(tester, modelo: modelo);
      await _escribir(tester, c.nombre, 'Equipo raro XJ-9');

      await tester.tap(find.text('Sugerir categoría con IA'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Categoría sugerida: Equipos (sugerida por la IA)'),
        findsOneWidget,
      );
      expect(modelo.consultas, hasLength(1));
      expect(modelo.consultas.single, contains('Equipo raro XJ-9'));

      await tester.tap(find.text('Usar'));
      await tester.pump();
      expect(c.categoria.text, 'Equipos');
    });

    testWidgets('mientras consulta lo dice', (tester) async {
      final modelo = _ModeloFalso('{"categoria": "Equipos"}')
        ..espera = Completer<void>();
      final c = await _abrir(tester, modelo: modelo);
      await _escribir(tester, c.nombre, 'Equipo raro XJ-9');

      await tester.tap(find.text('Sugerir categoría con IA'));
      await tester.pump();

      expect(find.text('Consultando a la IA…'), findsOneWidget);

      modelo.espera!.complete();
      await tester.pump();
      await tester.pump();
      expect(find.text('Consultando a la IA…'), findsNothing);
    });

    testWidgets('si la IA no sabe lo dice y deja volver a intentar', (tester) async {
      final c = await _abrir(tester, modelo: _ModeloFalso('{"categoria": ""}'));
      await _escribir(tester, c.nombre, 'Equipo raro XJ-9');

      await tester.tap(find.text('Sugerir categoría con IA'));
      await tester.pump();
      await tester.pump();

      expect(find.text('La IA no pudo sugerir una categoría'), findsOneWidget);
      expect(find.text('Sugerir categoría con IA'), findsOneWidget);
    });

    testWidgets('si la IA falla lo avisa sin detalle técnico', (tester) async {
      final c = await _abrir(tester, modelo: _ModeloQueFalla());
      await _escribir(tester, c.nombre, 'Equipo raro XJ-9');

      await tester.tap(find.text('Sugerir categoría con IA'));
      await tester.pump();
      await tester.pump();

      expect(find.text('No se pudo consultar la IA'), findsOneWidget);
      expect(find.textContaining('sin conexión'), findsNothing);
    });

    testWidgets('lo que dijo la IA no vale para otro nombre', (tester) async {
      final c = await _abrir(tester, modelo: _ModeloFalso('{"categoria": "Equipos"}'));
      await _escribir(tester, c.nombre, 'Equipo raro XJ-9');
      await tester.tap(find.text('Sugerir categoría con IA'));
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('Equipos'), findsOneWidget);

      await _escribir(tester, c.nombre, 'Otra cosa rara ZZ-1');

      expect(find.textContaining('Equipos'), findsNothing);
      expect(find.text('Sugerir categoría con IA'), findsOneWidget);
    });
  });

  testWidgets('dentro del Alta aparece debajo del campo Categoría', (tester) async {
    tester.view.physicalSize = const Size(1080, 7000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          insumosProvider.overrideWith((ref) => Stream.value(<Insumo>[])),
          modeloDeLenguajeProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(home: Scaffold(body: InsumoAltaScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre'), 'Etanol 96%');
    await tester.pump();
    expect(
      find.text('Categoría sugerida: Alcoholes y solventes (por el nombre)'),
      findsOneWidget,
    );

    await tester.tap(find.text('Usar'));
    await tester.pump();

    final campo = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Categoría'),
    );
    expect(campo.controller!.text, 'Alcoholes y solventes');
  });
}
