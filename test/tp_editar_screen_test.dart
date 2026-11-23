import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/trabajo_practico.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/trabajopractico_provider.dart';
import 'package:tpfinal_grupo2/providers/usuario_provider.dart';
import 'package:tpfinal_grupo2/screens/tp/tp_editar_screen.dart';
import 'package:tpfinal_grupo2/services/trabajopractico_service.dart';
import 'package:tpfinal_grupo2/services/usuario_actual_service.dart';

Insumo _insumo(String id, String nombre, {int stock = 10}) => Insumo(
      id: id,
      nombre: nombre,
      tipo: InsumoTipo.comprado,
      stock: stock,
      ubicacion: 'Estante A',
      umbralMinimo: 2,
    );

/// El servicio de TPs sin Firestore: guarda lo que se le pide guardar.
class _TpServiceFalso extends Fake implements TpService {
  final creados = <TrabajoPractico>[];
  final actualizados = <TrabajoPractico>[];
  TrabajoPractico? existente;
  bool falla = false;

  @override
  Future<List<TrabajoPractico>> getAll() async => [];

  @override
  Future<TrabajoPractico?> getById(String id) async => existente;

  @override
  Future<String> create(TrabajoPractico tp) async {
    if (falla) throw Exception('sin conexión');
    creados.add(tp);
    return 'nuevo';
  }

  @override
  Future<void> update(TrabajoPractico tp) async {
    if (falla) throw Exception('sin conexión');
    actualizados.add(tp);
  }

  // La misma regla que el servicio de verdad: falta lo que pide de más.
  @override
  DisponibilidadTP verificarDisponibilidad(
    TrabajoPractico tp,
    Map<String, num> stockPorInsumo,
  ) {
    final faltantes = <String, double>{};
    for (final i in tp.insumos) {
      final stock = stockPorInsumo[i.insumoId] ?? 0;
      if (stock < i.cantidad) faltantes[i.insumoId] = i.cantidad - stock;
    }
    return DisponibilidadTP(faltantes);
  }
}

final _etanol = _insumo('i1', 'Etanol absoluto');
final _acetona = _insumo('i2', 'Acetona', stock: 1);

Future<void> _abrir(
  WidgetTester tester,
  _TpServiceFalso servicio, {
  String? tpId,
  List<Insumo>? insumos,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: tpId == null ? '/tp/nuevo' : '/tp/editar/$tpId',
    routes: [
      GoRoute(
        path: '/tp',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Lista de TPs'))),
      ),
      GoRoute(
        path: '/tp/nuevo',
        builder: (context, state) => const TpEditarScreen(),
      ),
      GoRoute(
        path: '/tp/editar/:id',
        builder: (context, state) =>
            TpEditarScreen(tpId: state.pathParameters['id']),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tpServiceProvider.overrideWithValue(servicio),
        insumosProvider.overrideWith(
          (ref) => Stream.value(insumos ?? [_etanol, _acetona]),
        ),
        // Quien inició sesión: Ana, sin ir a Firebase.
        usuarioActualServiceProvider.overrideWithValue(
          UsuarioActualService(
            sesion: () => (uid: 'u1', nombre: 'Ana', email: 'ana@ort.edu.ar'),
            buscarUsuario: (_) async => null,
          ),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _campoNombre => find.byType(TextFormField).first;

Future<void> _agregarInsumo(WidgetTester tester, String nombre) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ListTile, nombre));
  await tester.pumpAndSettle();
}

Future<void> _guardar(WidgetTester tester) async {
  await tester.tap(find.text('Generar lista'));
  await tester.pumpAndSettle();
}

final _tpExistente = TrabajoPractico(
  id: 't1',
  nombre: 'TP de enzimas',
  descripcion: 'Digestión con enzimas',
  fecha: DateTime(2026, 12, 3),
  docente: 'Prof. Original',
  insumos: const [InsumoRequerido(insumoId: 'i1', cantidad: 3, unidad: 'u')],
);

void main() {
  group('crear un TP', () {
    testWidgets('sin nombre avisa y no guarda', (tester) async {
      final servicio = _TpServiceFalso();
      await _abrir(tester, servicio);
      await _agregarInsumo(tester, 'Etanol absoluto');

      await _guardar(tester);

      expect(find.text('Ingresá un nombre'), findsOneWidget);
      expect(servicio.creados, isEmpty);
    });

    testWidgets('sin insumos avisa y no guarda', (tester) async {
      final servicio = _TpServiceFalso();
      await _abrir(tester, servicio);
      await tester.enterText(_campoNombre, 'TP de prueba');

      await _guardar(tester);

      expect(find.text('Agregá al menos un insumo'), findsOneWidget);
      expect(servicio.creados, isEmpty);
    });

    testWidgets('el insumo agregado no se vuelve a ofrecer', (tester) async {
      await _abrir(tester, _TpServiceFalso());
      await _agregarInsumo(tester, 'Etanol absoluto');

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Etanol absoluto'), findsNothing);
      expect(find.widgetWithText(ListTile, 'Acetona'), findsOneWidget);
    });

    testWidgets('guarda con el nombre de quien lo crea como docente y vuelve',
        (tester) async {
      final servicio = _TpServiceFalso();
      await _abrir(tester, servicio);
      await tester.enterText(_campoNombre, '  TP de prueba  ');
      await _agregarInsumo(tester, 'Etanol absoluto');
      await tester.tap(find.byTooltip('Aumentar cantidad'));
      await tester.pump();

      await _guardar(tester);

      final tp = servicio.creados.single;
      expect(tp.nombre, 'TP de prueba');
      expect(tp.docente, 'Ana');
      expect(tp.insumos, [
        const InsumoRequerido(insumoId: 'i1', cantidad: 2, unidad: 'u'),
      ]);
      // Sin pantalla anterior, vuelve a la lista de TPs.
      expect(find.text('Lista de TPs'), findsOneWidget);
    });

    testWidgets('si falla al guardar lo dice y se queda para reintentar',
        (tester) async {
      final servicio = _TpServiceFalso()..falla = true;
      await _abrir(tester, servicio);
      await tester.enterText(_campoNombre, 'TP de prueba');
      await _agregarInsumo(tester, 'Etanol absoluto');

      await _guardar(tester);

      expect(find.text('No se pudo guardar el trabajo práctico'), findsOneWidget);
      expect(find.text('Lista de TPs'), findsNothing);
      // El botón vuelve a estar disponible.
      final boton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(boton.onPressed, isNotNull);
    });
  });

  group('los insumos del TP', () {
    testWidgets('la cantidad sube y baja, y no baja de 1', (tester) async {
      await _abrir(tester, _TpServiceFalso());
      await _agregarInsumo(tester, 'Etanol absoluto');

      IconButton menos() =>
          tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.remove));
      expect(menos().onPressed, isNull);

      await tester.tap(find.byTooltip('Aumentar cantidad'));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
      expect(menos().onPressed, isNotNull);

      await tester.tap(find.byTooltip('Disminuir cantidad'));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('avisa cuando el stock no alcanza', (tester) async {
      await _abrir(tester, _TpServiceFalso());
      await _agregarInsumo(tester, 'Acetona');
      expect(find.byIcon(Icons.error), findsNothing);

      await tester.tap(find.byTooltip('Aumentar cantidad'));
      await tester.pump();

      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('deslizar la tarjeta lo quita', (tester) async {
      await _abrir(tester, _TpServiceFalso());
      await _agregarInsumo(tester, 'Etanol absoluto');
      expect(find.text('Etanol absoluto'), findsOneWidget);

      await tester.drag(find.byType(Dismissible), const Offset(-700, 0));
      await tester.pumpAndSettle();

      expect(find.text('Etanol absoluto'), findsNothing);
    });
  });

  group('editar un TP', () {
    testWidgets('abre con los datos del TP', (tester) async {
      final servicio = _TpServiceFalso()..existente = _tpExistente;
      await _abrir(tester, servicio, tpId: 't1');

      expect(find.text('TP de enzimas'), findsOneWidget);
      expect(find.text('Digestión con enzimas'), findsOneWidget);
      expect(find.text('03/12/2026'), findsOneWidget);
      expect(find.text('Etanol absoluto'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('al guardar conserva el docente original y el id',
        (tester) async {
      final servicio = _TpServiceFalso()..existente = _tpExistente;
      await _abrir(tester, servicio, tpId: 't1');
      await tester.enterText(_campoNombre, 'TP de enzimas 2');

      await _guardar(tester);

      final tp = servicio.actualizados.single;
      expect(tp.id, 't1');
      expect(tp.nombre, 'TP de enzimas 2');
      expect(tp.docente, 'Prof. Original');
      expect(tp.insumos.single.cantidad, 3);
      expect(servicio.creados, isEmpty);
    });

    testWidgets('si el TP no existe lo dice', (tester) async {
      await _abrir(tester, _TpServiceFalso(), tpId: 'no-existe');

      expect(find.text('No se encontró el trabajo práctico'), findsOneWidget);
    });
  });
}
