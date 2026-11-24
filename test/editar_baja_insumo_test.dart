import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tpfinal_grupo2/core/app_strings.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/ubicacion.dart';
import 'package:tpfinal_grupo2/models/usuario.dart';
import 'package:tpfinal_grupo2/providers/historial_provider.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/role_provider.dart';
import 'package:tpfinal_grupo2/providers/ubicacion_providers.dart';
import 'package:tpfinal_grupo2/screens/inventario/insumo_detalle_screen.dart';
import 'package:tpfinal_grupo2/screens/inventario/insumo_editar_screen.dart';
import 'package:tpfinal_grupo2/services/insumo_service.dart';
import 'package:tpfinal_grupo2/services/ubicacion_service.dart';

final _etanol = Insumo(
  id: 'i1',
  nombre: 'Etanol absoluto',
  tipo: InsumoTipo.comprado,
  stock: 10,
  ubicacion: 'Estante A',
  umbralMinimo: 2.5,
  categoria: 'Alcoholes y solventes',
  marca: 'Cicarelli',
  formula: 'C2H6O',
  pesoMolecular: 46.07,
  unidad: 'ml',
  origen: 'Donación',
  cantidadPorEnvase: 500,
  alarmaVencimiento: true,
  fechaVencimiento: DateTime(2027, 5, 1),
  codigoInterno: 'I3',
  otrosNombres: ['Alcohol etílico'],
  controlado: true,
);

/// El servicio de insumos sin Firestore: anota lo que se le pide.
class _InsumoServiceFalso extends Fake implements InsumoService {
  final actualizados = <Insumo>[];
  final bajas = <String>[];
  bool falla = false;

  @override
  Future<void> actualizarInsumo(Insumo insumo) async {
    if (falla) throw Exception('sin conexión');
    actualizados.add(insumo);
  }

  @override
  Future<void> darDeBaja(String insumoId) async {
    if (falla) throw Exception('sin conexión');
    bajas.add(insumoId);
  }
}

/// El servicio de ubicaciones sin Firestore: anota las que se agregan.
class _UbicacionServiceFalso extends Fake implements UbicacionService {
  final creadas = <String>[];

  @override
  Future<void> crearSiNoExiste(String nombre) async => creadas.add(nombre);
}

class _UbicacionServiceFalsoQueFalla extends _UbicacionServiceFalso {
  @override
  Future<void> crearSiNoExiste(String nombre) async =>
      throw Exception('sin conexión');
}

Future<GoRouter> _abrir(
  WidgetTester tester,
  _InsumoServiceFalso servicio, {
  required String ruta,
  UserRole rol = UserRole.administrador,
  List<String> ubicaciones = const [],
  _UbicacionServiceFalso? ubicacionServicio,
}) async {
  tester.view.physicalSize = const Size(1080, 7000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/inventario',
    routes: [
      GoRoute(
        path: '/inventario',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('PANTALLA INVENTARIO'))),
      ),
      GoRoute(
        path: '/historial',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('PANTALLA HISTORIAL'))),
      ),
      GoRoute(
        path: '/insumo/editar/:id',
        builder: (context, state) => Scaffold(
          body: InsumoEditarScreen(insumoId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/insumo/:id',
        builder: (context, state) => Scaffold(
          body: InsumoDetalleScreen(insumoId: state.pathParameters['id']!),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        insumoServiceProvider.overrideWithValue(servicio),
        ubicacionServiceProvider.overrideWithValue(
          ubicacionServicio ?? _UbicacionServiceFalso(),
        ),
        ubicacionesProvider.overrideWith(
          (ref) => Stream.value([
            for (final n in ubicaciones) Ubicacion(id: n.toLowerCase(), nombre: n),
          ]),
        ),
        insumosProvider.overrideWith((ref) => Stream.value([_etanol])),
        rolDeSesionProvider.overrideWith((ref) => Stream.value(rol)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  // Se entra con push para que la pantalla tenga a dónde volver.
  router.push(ruta);
  await tester.pumpAndSettle();
  return router;
}

String _valorDe(WidgetTester tester, String campo) => tester
    .widget<TextFormField>(find.widgetWithText(TextFormField, campo))
    .controller!
    .text;

void main() {
  group('editar un insumo', () {
    testWidgets('abre con los datos del insumo', (tester) async {
      await _abrir(tester, _InsumoServiceFalso(), ruta: '/insumo/editar/i1');

      expect(find.text(AppStrings.editarInsumoTitulo), findsOneWidget);
      expect(_valorDe(tester, 'Nombre'), 'Etanol absoluto');
      expect(_valorDe(tester, 'Categoría'), 'Alcoholes y solventes');
      expect(_valorDe(tester, 'Ubicación'), 'Estante A');
      expect(_valorDe(tester, AppStrings.codigoInterno), 'I3');
      expect(_valorDe(tester, AppStrings.otrosNombres), 'Alcohol etílico');
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);
      expect(_valorDe(tester, 'Stock mínimo'), '2.5');
      expect(_valorDe(tester, 'Marca'), 'Cicarelli');
      expect(_valorDe(tester, 'Fórmula'), 'C2H6O');
      expect(_valorDe(tester, 'Peso molecular'), '46.07');
      expect(find.text('Vence: 1/5/2027'), findsOneWidget);
    });

    testWidgets('el stock no se edita: se explica cómo cambiarlo', (tester) async {
      await _abrir(tester, _InsumoServiceFalso(), ruta: '/insumo/editar/i1');

      expect(find.widgetWithText(TextFormField, 'Cantidad inicial'), findsNothing);
      expect(find.text(AppStrings.editarInsumoStock(10)), findsOneWidget);
    });

    testWidgets('no ofrece buscar duplicados ni sugerir nombres', (tester) async {
      await _abrir(tester, _InsumoServiceFalso(), ruta: '/insumo/editar/i1');

      expect(find.text(AppStrings.duplicadosBuscar), findsNothing);
    });

    testWidgets('el tipo no se puede cambiar', (tester) async {
      await _abrir(tester, _InsumoServiceFalso(), ruta: '/insumo/editar/i1');

      final tipo = tester.widget<DropdownButtonFormField<InsumoTipo>>(
        find.byType(DropdownButtonFormField<InsumoTipo>),
      );
      expect(tipo.onChanged, isNull);
    });

    testWidgets('guardar actualiza lo cambiado y conserva lo demás', (tester) async {
      final servicio = _InsumoServiceFalso();
      await _abrir(tester, servicio, ruta: '/insumo/editar/i1');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ubicación'),
        'Heladera 2',
      );

      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      final guardado = servicio.actualizados.single;
      expect(guardado.id, 'i1');
      expect(guardado.ubicacion, 'Heladera 2');
      // Lo que no se tocó queda igual, también lo que el formulario no muestra.
      expect(guardado.nombre, 'Etanol absoluto');
      expect(guardado.stock, 10);
      expect(guardado.umbralMinimo, 2.5);
      expect(guardado.marca, 'Cicarelli');
      expect(guardado.origen, 'Donación');
      expect(guardado.cantidadPorEnvase, 500);
      expect(guardado.alarmaVencimiento, isTrue);
      expect(guardado.codigoInterno, 'I3');
      expect(guardado.otrosNombres, ['Alcohol etílico']);
      expect(guardado.controlado, isTrue);
      expect(guardado.fechaVencimiento, DateTime(2027, 5, 1));
      // Vuelve a la pantalla anterior y lo avisa.
      expect(find.text('PANTALLA INVENTARIO'), findsOneWidget);
      expect(find.text(AppStrings.editarInsumoGuardado), findsOneWidget);
    });

    testWidgets('una ubicación que ya está se guarda con su escritura de la lista',
        (tester) async {
      final servicio = _InsumoServiceFalso();
      await _abrir(
        tester,
        servicio,
        ruta: '/insumo/editar/i1',
        ubicaciones: ['Heladera Pañol'],
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ubicación'),
        ' heladera  panol ',
      );

      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(servicio.actualizados.single.ubicacion, 'Heladera Pañol');
    });

    testWidgets('una ubicación nueva se guarda y se suma a la lista',
        (tester) async {
      final servicio = _InsumoServiceFalso();
      final ubicaciones = _UbicacionServiceFalso();
      await _abrir(
        tester,
        servicio,
        ruta: '/insumo/editar/i1',
        ubicaciones: ['Heladera Pañol'],
        ubicacionServicio: ubicaciones,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ubicación'),
        'Armario  7',
      );

      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(servicio.actualizados.single.ubicacion, 'Armario 7');
      expect(ubicaciones.creadas, ['Armario 7']);
    });

    testWidgets(
        'si no se puede sumar la ubicación a la lista, el insumo igual se guarda',
        (tester) async {
      final servicio = _InsumoServiceFalso();
      await _abrir(
        tester,
        servicio,
        ruta: '/insumo/editar/i1',
        ubicacionServicio: _UbicacionServiceFalsoQueFalla(),
      );

      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(servicio.actualizados, hasLength(1));
      expect(find.text(AppStrings.editarInsumoGuardado), findsOneWidget);
    });

    testWidgets('sin ubicación no guarda', (tester) async {
      final servicio = _InsumoServiceFalso();
      await _abrir(tester, servicio, ruta: '/insumo/editar/i1');
      await tester.enterText(find.widgetWithText(TextFormField, 'Ubicación'), '');

      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(servicio.actualizados, isEmpty);
      expect(find.text('Ingrese una ubicación'), findsOneWidget);
    });

    testWidgets('si falla al guardar lo dice y se queda en el formulario',
        (tester) async {
      final servicio = _InsumoServiceFalso()..falla = true;
      await _abrir(tester, servicio, ruta: '/insumo/editar/i1');

      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error:'), findsOneWidget);
      expect(find.text('PANTALLA INVENTARIO'), findsNothing);
    });

    testWidgets('un insumo que no existe lo dice', (tester) async {
      await _abrir(tester, _InsumoServiceFalso(), ruta: '/insumo/editar/no-existe');

      expect(find.text(AppStrings.editarInsumoNoExiste), findsOneWidget);
    });
  });

  group('el detalle: editar, baja e historial', () {
    testWidgets('"Editar" abre el formulario con el insumo', (tester) async {
      await _abrir(tester, _InsumoServiceFalso(), ruta: '/insumo/i1');

      await tester.tap(find.byTooltip('Editar'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.editarInsumoTitulo), findsOneWidget);
    });

    testWidgets('dar de baja pide confirmar y después lo hace', (tester) async {
      final servicio = _InsumoServiceFalso();
      await _abrir(tester, servicio, ruta: '/insumo/i1');

      await tester.tap(find.byTooltip('Dar de baja'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.bajaInsumoTitulo), findsOneWidget);
      expect(servicio.bajas, isEmpty);

      await tester.tap(find.widgetWithText(TextButton, AppStrings.bajaInsumoConfirmar));
      await tester.pumpAndSettle();

      expect(servicio.bajas, ['i1']);
      expect(find.text(AppStrings.bajaInsumoHecha('Etanol absoluto')), findsOneWidget);
      // Vuelve a donde estaba.
      expect(find.text('PANTALLA INVENTARIO'), findsOneWidget);
    });

    testWidgets('cancelar la baja no hace nada', (tester) async {
      final servicio = _InsumoServiceFalso();
      await _abrir(tester, servicio, ruta: '/insumo/i1');

      await tester.tap(find.byTooltip('Dar de baja'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, AppStrings.cancelar));
      await tester.pumpAndSettle();

      expect(servicio.bajas, isEmpty);
      expect(find.text('Etanol absoluto'), findsOneWidget);
    });

    testWidgets('si falla la baja lo dice y se queda', (tester) async {
      final servicio = _InsumoServiceFalso()..falla = true;
      await _abrir(tester, servicio, ruta: '/insumo/i1');

      await tester.tap(find.byTooltip('Dar de baja'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, AppStrings.bajaInsumoConfirmar));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.bajaInsumoError), findsOneWidget);
      expect(find.text('PANTALLA INVENTARIO'), findsNothing);
    });

    testWidgets('"Historial" abre solo los movimientos de este insumo y limpia el '
        'filtro al volver', (tester) async {
      final router = await _abrir(tester, _InsumoServiceFalso(), ruta: '/insumo/i1');
      final contenedor = ProviderScope.containerOf(
        tester.element(find.byType(InsumoDetalleScreen)),
      );

      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();

      expect(find.text('PANTALLA HISTORIAL'), findsOneWidget);
      expect(contenedor.read(filtroHistorialProvider).productoId, 'i1');

      router.pop();
      await tester.pumpAndSettle();

      expect(contenedor.read(filtroHistorialProvider).estaVacio, isTrue);
    });
  });
}
