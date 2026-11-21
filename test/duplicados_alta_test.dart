import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/screens/inventario/duplicados_dialog.dart';
import 'package:tpfinal_grupo2/screens/inventario/insumo_alta_screen.dart';

Insumo _insumo(
  String id,
  String nombre, {
  int stock = 10,
  String? unidad,
  String? marca,
  String? codigoBarras,
  InsumoTipo tipo = InsumoTipo.comprado,
}) {
  return Insumo(
    id: id,
    nombre: nombre,
    tipo: tipo,
    stock: stock,
    ubicacion: 'Estante 1',
    umbralMinimo: 2,
    unidad: unidad,
    marca: marca,
    codigoBarras: codigoBarras,
  );
}

final _existentes = [
  _insumo('p1', 'Etanol', stock: 12, unidad: 'ml', codigoBarras: '7790001'),
  _insumo('p2', 'Agar LB', stock: 7),
];

// Monta Alta dentro de un router de mentira: '/consumo' solo anota a qué
// insumo se quiso ir. Sin Firebase.
Future<void> _abrirAlta(
  WidgetTester tester, {
  Stream<List<Insumo>>? insumos,
}) async {
  // Un celular bien alto, para que entre todo el formulario sin desplazar.
  tester.view.physicalSize = const Size(1080, 7000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/alta',
    routes: [
      GoRoute(
        path: '/alta',
        builder: (context, state) => const Scaffold(body: InsumoAltaScreen()),
      ),
      GoRoute(
        path: '/consumo',
        builder: (context, state) => Scaffold(
          body: Text('CONSUMO ${state.uri.queryParameters['insumo']}'),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      // Sin reintentos: un error de carga tiene que verse enseguida.
      retry: (retries, error) => null,
      overrides: [
        insumosProvider.overrideWith(
          (ref) => insumos ?? Stream.value(_existentes),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _escribir(WidgetTester tester, String campo, String texto) async {
  await tester.enterText(find.widgetWithText(TextFormField, campo), texto);
}

Future<void> _tocarBuscar(WidgetTester tester) async {
  await tester.tap(find.text('Buscar duplicados'));
  await tester.pumpAndSettle();
}

void main() {
  group('ventana de duplicados', () {
    Future<void> abrir(
      WidgetTester tester,
      List<InsumoParecido> parecidos,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => DuplicadosDialog.mostrar(context, parecidos),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('sin coincidencias lo dice y ofrece cerrar', (tester) async {
      await abrir(tester, const []);

      expect(find.text('No se encontraron duplicados'), findsOneWidget);
      expect(find.text('Cargarle un consumo'), findsNothing);

      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      expect(find.text('No se encontraron duplicados'), findsNothing);
    });

    testWidgets('lista cada insumo con su nombre, marca y stock', (tester) async {
      await abrir(tester, [
        (
          insumo: _insumo('p1', 'Etanol', stock: 12, unidad: 'ml', marca: 'Cicarelli'),
          mismoCodigoDeBarras: false,
        ),
        (insumo: _insumo('p2', 'Agar LB', stock: 7), mismoCodigoDeBarras: true),
      ]);

      expect(find.text('Ya hay insumos parecidos'), findsOneWidget);
      expect(find.text('Etanol · Cicarelli'), findsOneWidget);
      expect(find.text('Stock actual: 12 ml'), findsOneWidget);
      expect(find.text('Agar LB'), findsOneWidget);
      // Sin unidad cargada se dice "unidades".
      expect(find.text('Stock actual: 7 unidades'), findsOneWidget);
      expect(find.text('Nombre muy parecido'), findsOneWidget);
      expect(find.text('Mismo código de barras'), findsOneWidget);
      expect(find.text('Cargarle un consumo'), findsNWidgets(2));
    });

    testWidgets('seguir cargando cierra sin elegir ningún insumo', (tester) async {
      await abrir(tester, [
        (insumo: _insumo('p1', 'Etanol'), mismoCodigoDeBarras: false),
      ]);

      await tester.tap(find.text('Es distinto, seguir cargando'));
      await tester.pumpAndSettle();

      expect(find.text('Ya hay insumos parecidos'), findsNothing);
    });
  });

  group('Buscar duplicados en Alta', () {
    testWidgets('sin nombre pide escribirlo y no abre la ventana', (tester) async {
      await _abrirAlta(tester);

      await _tocarBuscar(tester);

      expect(find.text('Escribí un nombre primero'), findsOneWidget);
      expect(find.text('Ya hay insumos parecidos'), findsNothing);
      expect(find.text('No se encontraron duplicados'), findsNothing);
    });

    testWidgets('con un nombre parecido a uno existente lo muestra', (tester) async {
      await _abrirAlta(tester);
      await _escribir(tester, 'Nombre', 'etanol');

      await _tocarBuscar(tester);

      expect(find.text('Ya hay insumos parecidos'), findsOneWidget);
      expect(find.text('Stock actual: 12 ml'), findsOneWidget);
      // Solo el parecido, no el otro insumo.
      expect(find.text('Agar LB'), findsNothing);
    });

    testWidgets('con un nombre que no se parece a nada lo dice', (tester) async {
      await _abrirAlta(tester);
      await _escribir(tester, 'Nombre', 'Pipeta de vidrio');

      await _tocarBuscar(tester);

      expect(find.text('No se encontraron duplicados'), findsOneWidget);
    });

    testWidgets('el mismo código de barras cuenta aunque el nombre sea otro',
        (tester) async {
      await _abrirAlta(tester);
      await _escribir(tester, 'Nombre', 'Alcohol etílico');
      await _escribir(tester, 'Código de barras', '7790001');

      await _tocarBuscar(tester);

      expect(find.text('Mismo código de barras'), findsOneWidget);
      expect(find.text('Etanol'), findsOneWidget);
    });

    testWidgets('cargarle un consumo abre Consumo con ese insumo', (tester) async {
      await _abrirAlta(tester);
      await _escribir(tester, 'Nombre', 'etanol');
      await _tocarBuscar(tester);

      await tester.tap(find.text('Cargarle un consumo'));
      await tester.pumpAndSettle();

      expect(find.text('CONSUMO p1'), findsOneWidget);
    });

    testWidgets('seguir cargando deja el formulario como estaba', (tester) async {
      await _abrirAlta(tester);
      await _escribir(tester, 'Nombre', 'etanol');
      await _tocarBuscar(tester);

      await tester.tap(find.text('Es distinto, seguir cargando'));
      await tester.pumpAndSettle();

      expect(find.text('Ya hay insumos parecidos'), findsNothing);
      expect(find.text('Alta de insumo'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'etanol'), findsOneWidget);
    });

    testWidgets('mientras cargan los insumos pide esperar', (tester) async {
      await _abrirAlta(
        tester,
        // Un stream que nunca emite: los insumos siguen cargando.
        insumos: StreamController<List<Insumo>>().stream,
      );
      await _escribir(tester, 'Nombre', 'etanol');

      await _tocarBuscar(tester);

      expect(find.textContaining('todavía se están cargando'), findsOneWidget);
      expect(find.text('No se encontraron duplicados'), findsNothing);
    });

    testWidgets('si no se pueden leer los insumos, lo avisa', (tester) async {
      await _abrirAlta(
        tester,
        insumos: Stream<List<Insumo>>.error('sin permiso'),
      );
      await _escribir(tester, 'Nombre', 'etanol');

      await _tocarBuscar(tester);

      expect(find.text('No se pudo buscar duplicados'), findsOneWidget);
      expect(find.text('Ya hay insumos parecidos'), findsNothing);
    });
  });
}
