import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/movimiento_stock.dart';
import 'package:tpfinal_grupo2/providers/historial_provider.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/screens/historial/historial_screen.dart';

Insumo _insumo(String id, String nombre) => Insumo(
      id: id,
      nombre: nombre,
      tipo: InsumoTipo.comprado,
      stock: 10,
      ubicacion: 'Estante 1',
      umbralMinimo: 2,
    );

MovimientoStock _mov(String id, String producto, TipoMovimiento tipo) {
  return MovimientoStock(
    id: id,
    productoId: producto,
    usuarioId: 'u1',
    usuarioNombre: 'Juan Perez',
    tipo: tipo,
    cantidad: 5,
    fecha: DateTime.now().subtract(const Duration(hours: 1)),
  );
}

// Monta la pantalla con movimientos e insumos de mentira, sin Firebase.
Future<void> _abrirPantalla(
  WidgetTester tester, {
  List<MovimientoStock>? movimientos,
}) async {
  // Tamaño de un celular: 360 x 800.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        movimientosStockProvider.overrideWith(
          (ref) => Stream.value(
            movimientos ??
                [
                  _mov('a', 'p1', TipoMovimiento.entrada),
                  _mov('b', 'p2', TipoMovimiento.salida),
                  _mov('c', 'p1', TipoMovimiento.salida),
                ],
          ),
        ),
        insumosProvider.overrideWith(
          (ref) =>
              Stream.value([_insumo('p1', 'Etanol'), _insumo('p2', 'Pipetas')]),
        ),
      ],
      child: const MaterialApp(home: HistorialScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _filtrarPorTipo(WidgetTester tester, String tipo) async {
  await tester.tap(find.byIcon(Icons.tune));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(InputDecorator, 'Tipo de movimiento'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(tipo).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Filtrar'));
  await tester.pumpAndSettle();
}

bool _puntoVisible(WidgetTester tester) =>
    tester.widget<Badge>(find.byType(Badge)).isLabelVisible;

void main() {
  testWidgets('sin filtro muestra todos los movimientos y ningún indicador',
      (tester) async {
    await _abrirPantalla(tester);

    expect(find.text('Etanol'), findsNWidgets(2));
    expect(find.text('Pipetas'), findsOneWidget);
    expect(_puntoVisible(tester), isFalse);
  });

  testWidgets('el ícono de filtros abre el panel', (tester) async {
    await _abrirPantalla(tester);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    expect(find.text('Tipo de movimiento'), findsOneWidget);
    expect(find.text('Filtrar'), findsOneWidget);
    expect(find.text('Limpiar'), findsOneWidget);
  });

  testWidgets('filtrar por tipo deja solo esos movimientos y marca el ícono',
      (tester) async {
    await _abrirPantalla(tester);

    await _filtrarPorTipo(tester, 'Entrada');

    expect(find.text('Etanol'), findsOneWidget);
    expect(find.text('Pipetas'), findsNothing);
    expect(_puntoVisible(tester), isTrue);
  });

  testWidgets('sin coincidencias avisa y permite sacar el filtro',
      (tester) async {
    await _abrirPantalla(tester);

    await _filtrarPorTipo(tester, 'Ajuste');

    expect(find.text('Ningún movimiento coincide con los filtros'), findsOneWidget);
    expect(find.text('Todavía no hay movimientos registrados'), findsNothing);

    await tester.tap(find.text('Limpiar filtros'));
    await tester.pumpAndSettle();

    expect(find.text('Etanol'), findsNWidgets(2));
    expect(find.text('Ningún movimiento coincide con los filtros'), findsNothing);
    expect(_puntoVisible(tester), isFalse);
  });

  testWidgets('el botón Limpiar del panel saca el filtro', (tester) async {
    await _abrirPantalla(tester);
    await _filtrarPorTipo(tester, 'Entrada');

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpiar'));
    await tester.pumpAndSettle();

    expect(find.text('Pipetas'), findsOneWidget);
    expect(_puntoVisible(tester), isFalse);
  });

  testWidgets('sin movimientos y sin filtro dice que todavía no hay',
      (tester) async {
    await _abrirPantalla(tester, movimientos: const []);

    expect(find.text('Todavía no hay movimientos registrados'), findsOneWidget);
    expect(find.text('Limpiar filtros'), findsNothing);
  });
}
