import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/lista_compra.dart';
import 'package:tpfinal_grupo2/providers/lista_compra_provider.dart';
import 'package:tpfinal_grupo2/screens/compras/compra_tile.dart';
import 'package:tpfinal_grupo2/screens/compras/compras_screen.dart';
import 'package:tpfinal_grupo2/screens/compras/item_compra.dart';

/// Reemplazo de las acciones reales: no escribe en Firestore, solo anota qué
/// cambios de estado le pidieron.
class _AccionesFalsas implements ComprasAcciones {
  _AccionesFalsas({this.falla = false});

  /// Si es true, cambiar el estado falla, como si no hubiera conexión.
  final bool falla;

  final cambios = <(String, EstadoCompra)>[];

  @override
  Future<void> cambiarEstado(String id, EstadoCompra estado) async {
    if (falla) throw Exception('sin conexión');
    cambios.add((id, estado));
  }

  @override
  Future<void> incrementar(String id) async {}

  @override
  Future<void> decrementar(String id) async {}

  @override
  Future<void> agregar(String productoId, int cantidad) async {}

  @override
  Future<void> eliminar(Iterable<String> ids) async {}

  @override
  Future<int> agregarSugerencias() async => 0;
}

const _items = [
  ItemCompra(id: '1', nombre: 'Guantes de nitrilo', stock: 3, cantidadSolicitada: 8),
  ItemCompra(id: '2', nombre: 'Agar LB', stock: 0, cantidadSolicitada: 5),
];

Future<void> _abrirPantalla(
  WidgetTester tester,
  _AccionesFalsas acciones,
) async {
  // Un celular alto, para que entren la lista, el botón flotante y los
  // botones de abajo sin desbordar.
  tester.view.physicalSize = const Size(1200, 2700);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        itemsCompraProvider.overrideWith((ref) => const AsyncData(_items)),
        comprasAccionesProvider.overrideWithValue(acciones),
      ],
      child: const MaterialApp(home: ComprasScreen()),
    ),
  );
  await tester.pump();
}

Future<void> _elegir(WidgetTester tester, int fila, String opcion) async {
  await tester.tap(find.byTooltip('Cambiar estado').at(fila));
  await tester.pumpAndSettle();
  await tester.tap(find.text(opcion));
  await tester.pumpAndSettle();
}

void main() {
  group('la fila', () {
    Future<void> mostrar(
      WidgetTester tester, {
      ValueChanged<EstadoCompra>? onCambiarEstado,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompraTile(item: _items.first, onCambiarEstado: onCambiarEstado),
          ),
        ),
      );
    }

    testWidgets('sin callback no hay menú', (tester) async {
      await mostrar(tester);

      expect(find.byTooltip('Cambiar estado'), findsNothing);
    });

    testWidgets('el menú ofrece comprado y descartar', (tester) async {
      await mostrar(tester, onCambiarEstado: (_) {});

      await tester.tap(find.byTooltip('Cambiar estado'));
      await tester.pumpAndSettle();

      expect(find.text('Marcar como comprado'), findsOneWidget);
      expect(find.text('Descartar'), findsOneWidget);
    });

    testWidgets('elegir una opción avisa el estado elegido', (tester) async {
      final elegidos = <EstadoCompra>[];
      await mostrar(tester, onCambiarEstado: elegidos.add);

      await tester.tap(find.byTooltip('Cambiar estado'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();

      expect(elegidos, [EstadoCompra.descartado]);
    });
  });

  group('la pantalla', () {
    testWidgets('marcar como comprado cambia el estado del ítem elegido', (tester) async {
      final acciones = _AccionesFalsas();
      await _abrirPantalla(tester, acciones);

      await _elegir(tester, 0, 'Marcar como comprado');

      expect(acciones.cambios, [('1', EstadoCompra.comprado)]);
      expect(
        find.text('Guantes de nitrilo: comprado, se sumaron 8 u. al stock'),
        findsOneWidget,
      );
    });

    testWidgets('descartar el segundo ítem cambia el de esa fila', (tester) async {
      final acciones = _AccionesFalsas();
      await _abrirPantalla(tester, acciones);

      await _elegir(tester, 1, 'Descartar');

      expect(acciones.cambios, [('2', EstadoCompra.descartado)]);
      expect(find.text('Agar LB: descartado'), findsOneWidget);
    });

    testWidgets('Deshacer vuelve el ítem a pendiente', (tester) async {
      final acciones = _AccionesFalsas();
      await _abrirPantalla(tester, acciones);
      await _elegir(tester, 0, 'Marcar como comprado');

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();

      expect(acciones.cambios, [
        ('1', EstadoCompra.comprado),
        ('1', EstadoCompra.pendiente),
      ]);
    });

    testWidgets('si falla, avisa el error y no ofrece deshacer', (tester) async {
      final acciones = _AccionesFalsas(falla: true);
      await _abrirPantalla(tester, acciones);

      await _elegir(tester, 0, 'Marcar como comprado');

      expect(find.text('No se pudo cambiar el estado'), findsOneWidget);
      expect(find.text('Deshacer'), findsNothing);
      expect(acciones.cambios, isEmpty);
    });
  });
}
