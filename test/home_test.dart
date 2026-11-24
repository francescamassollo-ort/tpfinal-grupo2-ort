import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tpfinal_grupo2/core/app_shell.dart';
import 'package:tpfinal_grupo2/models/alerta.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/movimiento_stock.dart';
import 'package:tpfinal_grupo2/models/usuario.dart';
import 'package:tpfinal_grupo2/providers/alerta_provider.dart';
import 'package:tpfinal_grupo2/providers/historial_provider.dart';
import 'package:tpfinal_grupo2/providers/home_provider.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/role_provider.dart';
import 'package:tpfinal_grupo2/screens/historial/movimiento_item.dart';
import 'package:tpfinal_grupo2/screens/home/home_screen.dart';

Insumo _insumo(String id, String nombre, {int stock = 10, int umbral = 2}) =>
    Insumo(
      id: id,
      nombre: nombre,
      tipo: InsumoTipo.comprado,
      stock: stock,
      ubicacion: 'Estante 1',
      umbralMinimo: umbral,
    );

MovimientoStock _mov(String id, String producto, DateTime fecha) =>
    MovimientoStock(
      id: id,
      productoId: producto,
      usuarioId: 'u1',
      usuarioNombre: 'Juan Perez',
      tipo: TipoMovimiento.salida,
      cantidad: 5,
      fecha: fecha,
    );

void main() {
  group('lo que cuenta el tablero', () {
    test('cuenta los insumos en el mínimo o por debajo, incluso sin stock', () {
      final insumos = [
        _insumo('a', 'Alcohol', stock: 10, umbral: 2),
        _insumo('b', 'Etanol', stock: 2, umbral: 2),
        _insumo('c', 'Acetona', stock: 0, umbral: 2),
      ];

      expect(contarStockBajo(insumos), 2);
      expect(contarStockBajo(const []), 0);
    });

    test('el último movimiento es el primero de la lista, con el nombre del insumo',
        () async {
      final c = ProviderContainer(
        overrides: [
          movimientosStockProvider.overrideWith(
            (ref) => Stream.value([
              _mov('nuevo', 'p2', DateTime(2026, 11, 10, 12)),
              _mov('viejo', 'p1', DateTime(2026, 11, 1, 9)),
            ]),
          ),
          insumosConBajasProvider.overrideWith(
            (ref) => Stream.value([
              _insumo('p1', 'Alcohol'),
              _insumo('p2', 'Etanol'),
            ]),
          ),
        ],
      );
      addTearDown(c.dispose);
      c.listen(homeUltimoMovimientoProvider, (_, _) {});
      await c.read(movimientosStockProvider.future);
      await c.read(insumosConBajasProvider.future);

      final ultimo = c.read(homeUltimoMovimientoProvider).requireValue;
      expect(ultimo?.id, 'nuevo');
      expect(ultimo?.elementoNombre, 'Etanol');
      expect(ultimo?.deltaTexto, '-5');
    });

    test('sin movimientos no hay último movimiento', () async {
      final c = ProviderContainer(
        overrides: [
          movimientosStockProvider.overrideWith((ref) => Stream.value([])),
          insumosConBajasProvider.overrideWith((ref) => Stream.value([])),
        ],
      );
      addTearDown(c.dispose);
      c.listen(homeUltimoMovimientoProvider, (_, _) {});
      await c.read(movimientosStockProvider.future);

      expect(c.read(homeUltimoMovimientoProvider).requireValue, isNull);
    });
  });

  group('pantalla Inicio', () {
    Future<GoRouter> abrir(
      WidgetTester tester, {
      AsyncValue<int> stockBajo = const AsyncData(3),
      AsyncValue<ResumenAlertas> alertas =
          const AsyncData((activas: 5, sinVer: 2)),
      AsyncValue<MovimientoItem?> ultimo = const AsyncData(
        MovimientoItem(
          id: 'm1',
          elementoNombre: 'Etanol',
          usuarioNombre: 'Juan Perez',
          fechaEtiqueta: 'Hoy 14:32',
          delta: -10,
        ),
      ),
    }) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/inventario',
            builder: (context, state) => const Text('PANTALLA INVENTARIO'),
          ),
          GoRoute(
            path: '/alertas',
            builder: (context, state) => const Text('PANTALLA ALERTAS'),
          ),
          GoRoute(
            path: '/historial',
            builder: (context, state) => const Text('PANTALLA HISTORIAL'),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeStockBajoProvider.overrideWithValue(stockBajo),
            homeAlertasProvider.overrideWithValue(alertas),
            homeUltimoMovimientoProvider.overrideWithValue(ultimo),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('muestra stock bajo, alertas y el último movimiento', (tester) async {
      await abrir(tester);

      expect(find.text('3'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('2 sin ver'), findsOneWidget);
      expect(find.text('Etanol'), findsOneWidget);
      expect(find.text('-10 · Juan Perez · Hoy 14:32'), findsOneWidget);
    });

    testWidgets('sin movimientos lo dice', (tester) async {
      await abrir(tester, ultimo: const AsyncData(null));

      expect(find.text('Todavía no hay movimientos'), findsOneWidget);
    });

    testWidgets('mientras cargan muestra puntos y si fallan lo avisa sin inventar un número',
        (tester) async {
      await abrir(
        tester,
        stockBajo: const AsyncLoading(),
        alertas: AsyncError('sin permiso', StackTrace.empty),
      );

      expect(find.text('...'), findsOneWidget);
      expect(find.text('No se pudo cargar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('los atajos llevan a Inventario, Alertas e Historial', (tester) async {
      final router = await abrir(tester);

      await tester.tap(find.widgetWithText(InkWell, 'Alertas').last);
      await tester.pumpAndSettle();
      expect(find.text('PANTALLA ALERTAS'), findsOneWidget);

      router.go('/home');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, 'Historial').last);
      await tester.pumpAndSettle();
      expect(find.text('PANTALLA HISTORIAL'), findsOneWidget);

      router.go('/home');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, 'Inventario').last);
      await tester.pumpAndSettle();
      expect(find.text('PANTALLA INVENTARIO'), findsOneWidget);
    });
  });

  group('barra inferior', () {
    Future<void> mostrar(WidgetTester tester, String ruta, UserRole rol) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            alertasProvider.overrideWithValue(const AsyncData(<Alerta>[])),
            alertasVistasProvider.overrideWith((ref) => Stream.value(<String>{})),
            rolDeSesionProvider.overrideWith((ref) => Stream.value(rol)),
          ],
          child: MaterialApp(
            home: AppShell(location: ruta, child: const SizedBox()),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('tiene el ícono de Inicio', (tester) async {
      await mostrar(tester, '/inventario', UserRole.docente);

      expect(find.byTooltip('Inicio'), findsOneWidget);
    });

    for (final rol in UserRole.values) {
      testWidgets('en /home no hay botón flotante para ${rol.name}', (tester) async {
        await mostrar(tester, '/home', rol);

        expect(find.byType(FloatingActionButton), findsNothing);
      });
    }
  });
}
