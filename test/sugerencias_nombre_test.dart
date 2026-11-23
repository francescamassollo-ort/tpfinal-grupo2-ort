import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/screens/inventario/insumo_alta_screen.dart';
import 'package:tpfinal_grupo2/screens/inventario/sugerencias_nombre.dart';

Insumo _insumo(String id, String nombre, {int stock = 10, String? unidad}) {
  return Insumo(
    id: id,
    nombre: nombre,
    tipo: InsumoTipo.comprado,
    stock: stock,
    ubicacion: 'Estante 1',
    umbralMinimo: 2,
    unidad: unidad,
  );
}

final _insumos = [
  _insumo('p1', 'Etanol 96%', stock: 12, unidad: 'ml'),
  _insumo('p2', 'Agar LB'),
  _insumo('p3', 'Ácido acético'),
  _insumo('p4', 'Metanol'),
  _insumo('p5', 'Etanolamina'),
  _insumo('p6', 'Tampón Tris'),
];

List<String> _ids(List<Insumo> lista) => [for (final i in lista) i.id];

void main() {
  group('sugerenciasPorNombre', () {
    test('encuentra los que contienen lo escrito', () {
      expect(_ids(sugerenciasPorNombre('agar', _insumos)), ['p2']);
    });

    test('no distingue mayúsculas, tildes ni espacios', () {
      expect(_ids(sugerenciasPorNombre('ACIDO', _insumos)), ['p3']);
      expect(_ids(sugerenciasPorNombre('tampon tris', _insumos)), ['p6']);
      expect(_ids(sugerenciasPorNombre('etanol 96', _insumos)), ['p1']);
    });

    test('los que empiezan igual van primero, después los demás', () {
      // "etanol" está al principio de dos (en orden alfabético: "Etanol 96%"
      // antes que "Etanolamina") y adentro de "Metanol", que va al final.
      expect(_ids(sugerenciasPorNombre('etanol', _insumos)), ['p1', 'p5', 'p4']);
    });

    test('devuelve como mucho 3', () {
      final muchos = [for (var i = 0; i < 8; i++) _insumo('x$i', 'Etanol $i')];

      expect(sugerenciasPorNombre('etanol', muchos), hasLength(3));
      expect(sugerenciasPorNombre('etanol', muchos, maximo: 5), hasLength(5));
    });

    test('con menos de 2 letras no sugiere nada', () {
      expect(sugerenciasPorNombre('e', _insumos), isEmpty);
      expect(sugerenciasPorNombre('', _insumos), isEmpty);
      expect(sugerenciasPorNombre('  ', _insumos), isEmpty);
    });

    test('si nada coincide, la lista queda vacía', () {
      expect(sugerenciasPorNombre('zzz', _insumos), isEmpty);
    });
  });

  group('dentro del Alta', () {
    Future<void> abrir(
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
            builder: (context, state) =>
                const Scaffold(body: InsumoAltaScreen()),
          ),
          GoRoute(
            path: '/insumo/:id',
            builder: (context, state) =>
                Scaffold(body: Text('DETALLE ${state.pathParameters['id']}')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          retry: (retries, error) => null,
          overrides: [
            insumosProvider.overrideWith(
              (ref) => insumos ?? Stream.value(_insumos),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> escribir(WidgetTester tester, String texto) async {
      await tester.enterText(find.widgetWithText(TextFormField, 'Nombre'), texto);
      await tester.pump();
    }

    testWidgets('sin escribir nada no muestra sugerencias ni avisos', (tester) async {
      await abrir(tester);

      expect(find.text('Ya existe algo parecido:'), findsNothing);
      expect(
        find.text('No hay un insumo con ese nombre: se va a agregar como nuevo'),
        findsNothing,
      );
    });

    testWidgets('al escribir muestra los parecidos con su stock', (tester) async {
      await abrir(tester);

      await escribir(tester, 'etanol');

      expect(find.text('Ya existe algo parecido:'), findsOneWidget);
      expect(find.text('Etanol 96%'), findsOneWidget);
      expect(find.text('Estante 1 · Stock actual: 12 ml'), findsOneWidget);
      expect(find.text('Etanolamina'), findsOneWidget);
      expect(find.text('Metanol'), findsOneWidget);
    });

    testWidgets('las sugerencias se actualizan con cada letra', (tester) async {
      await abrir(tester);

      await escribir(tester, 'etanol');
      expect(find.text('Metanol'), findsOneWidget);

      await escribir(tester, 'etanola');
      expect(find.text('Metanol'), findsNothing);
      expect(find.text('Etanolamina'), findsOneWidget);
    });

    testWidgets('si ninguno se parece, dice que se agrega como nuevo', (tester) async {
      await abrir(tester);

      await escribir(tester, 'Pipeta de vidrio');

      expect(
        find.text('No hay un insumo con ese nombre: se va a agregar como nuevo'),
        findsOneWidget,
      );
      expect(find.text('Ya existe algo parecido:'), findsNothing);
    });

    testWidgets('con una sola letra no dice nada', (tester) async {
      await abrir(tester);

      await escribir(tester, 'e');

      expect(find.text('Ya existe algo parecido:'), findsNothing);
      expect(
        find.text('No hay un insumo con ese nombre: se va a agregar como nuevo'),
        findsNothing,
      );
    });

    testWidgets('tocar una sugerencia abre el detalle de ese insumo', (tester) async {
      await abrir(tester);
      await escribir(tester, 'agar');

      await tester.tap(find.text('Agar LB'));
      await tester.pumpAndSettle();

      expect(find.text('DETALLE p2'), findsOneWidget);
    });

    testWidgets('mientras los insumos no cargaron no afirma nada', (tester) async {
      // Un stream que nunca emite: los insumos siguen cargando.
      await abrir(tester, insumos: const Stream<List<Insumo>>.empty());

      await escribir(tester, 'etanol');

      expect(find.text('Ya existe algo parecido:'), findsNothing);
      expect(
        find.text('No hay un insumo con ese nombre: se va a agregar como nuevo'),
        findsNothing,
      );
    });

    testWidgets('si no se pueden leer los insumos tampoco afirma nada', (tester) async {
      await abrir(tester, insumos: Stream<List<Insumo>>.error('sin permiso'));

      await escribir(tester, 'etanol');

      expect(find.text('Ya existe algo parecido:'), findsNothing);
      expect(
        find.text('No hay un insumo con ese nombre: se va a agregar como nuevo'),
        findsNothing,
      );
    });
  });
}
