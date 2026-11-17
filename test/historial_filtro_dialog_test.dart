import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/filtro_historial.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/movimiento_stock.dart';
import 'package:tpfinal_grupo2/screens/historial/historial_filtro_dialog.dart';

Insumo _insumo(String id, String nombre) => Insumo(
      id: id,
      nombre: nombre,
      tipo: InsumoTipo.comprado,
      stock: 10,
      ubicacion: 'Estante 1',
      umbralMinimo: 2,
    );

final _insumos = [_insumo('p1', 'Etanol'), _insumo('p2', 'Pipetas')];

// Lo que el panel devolvió al cerrarse. Queda null si se cerró sin elegir.
class _Resultado {
  FiltroHistorial? filtro;
}

// Abre el panel como lo hace la pantalla real: con showDialog.
Future<_Resultado> _abrir(
  WidgetTester tester, {
  FiltroHistorial actual = const FiltroHistorial(),
}) async {
  final resultado = _Resultado();
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                resultado.filtro = await showDialog<FiltroHistorial>(
                  context: context,
                  builder: (_) => HistorialFiltroDialog(
                    filtroActual: actual,
                    insumos: _insumos,
                  ),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return resultado;
}

Future<void> _elegirOpcion(
  WidgetTester tester, {
  required String campo,
  required String opcion,
}) async {
  // Se toca el desplegable entero, no solo el texto de su etiqueta.
  await tester.tap(find.widgetWithText(InputDecorator, campo));
  await tester.pumpAndSettle();
  await tester.tap(find.text(opcion).last);
  await tester.pumpAndSettle();
}

Future<void> _tocar(WidgetTester tester, String texto) async {
  await tester.tap(find.text(texto));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('abre con lo que ya estaba elegido', (tester) async {
    await _abrir(
      tester,
      actual: FiltroHistorial(
        tipo: TipoMovimiento.salida,
        productoId: 'p2',
        desde: DateTime(2026, 11, 3),
        hasta: DateTime(2026, 11, 10),
      ),
    );

    expect(find.text('Salida'), findsOneWidget);
    expect(find.text('Pipetas'), findsOneWidget);
    expect(find.text('03/11/2026'), findsOneWidget);
    expect(find.text('10/11/2026'), findsOneWidget);
  });

  testWidgets('sin nada elegido muestra "Todos" y "Cualquier fecha"',
      (tester) async {
    await _abrir(tester);

    expect(find.text('Todos'), findsNWidgets(2));
    expect(find.text('Cualquier fecha'), findsNWidgets(2));
  });

  testWidgets('Filtrar sin cambiar nada devuelve el mismo filtro, con la persona',
      (tester) async {
    const actual = FiltroHistorial(
      tipo: TipoMovimiento.ajuste,
      productoId: 'p1',
      usuarioId: 'u7',
    );
    final resultado = await _abrir(tester, actual: actual);

    await _tocar(tester, 'Filtrar');

    expect(resultado.filtro, actual);
  });

  testWidgets('elegir tipo e insumo los devuelve en el filtro', (tester) async {
    final resultado = await _abrir(tester);

    await _elegirOpcion(tester, campo: 'Tipo de movimiento', opcion: 'Entrada');
    await _elegirOpcion(tester, campo: 'Insumo', opcion: 'Pipetas');
    await _tocar(tester, 'Filtrar');

    expect(
      resultado.filtro,
      const FiltroHistorial(tipo: TipoMovimiento.entrada, productoId: 'p2'),
    );
  });

  testWidgets('Limpiar devuelve un filtro vacío', (tester) async {
    final resultado = await _abrir(
      tester,
      actual: const FiltroHistorial(tipo: TipoMovimiento.salida, productoId: 'p1'),
    );

    await _tocar(tester, 'Limpiar');

    expect(resultado.filtro, isNotNull);
    expect(resultado.filtro!.estaVacio, isTrue);
  });

  testWidgets('un insumo que ya no existe vuelve a "Todos"', (tester) async {
    final resultado = await _abrir(
      tester,
      actual: const FiltroHistorial(productoId: 'borrado'),
    );

    await _tocar(tester, 'Filtrar');

    expect(resultado.filtro!.productoId, isNull);
  });

  testWidgets('elegir una fecha con el calendario la guarda como "desde"',
      (tester) async {
    final resultado = await _abrir(tester);

    // Se toca el campo entero, no solo el texto de su etiqueta.
    await tester.tap(find.widgetWithText(InkWell, 'Desde'));
    await tester.pumpAndSettle();
    // El calendario abre en hoy; confirmar deja esa fecha.
    await _tocar(tester, 'OK');
    await _tocar(tester, 'Filtrar');

    final hoy = DateTime.now();
    expect(
      resultado.filtro!.desde,
      DateTime(hoy.year, hoy.month, hoy.day),
    );
    expect(resultado.filtro!.hasta, isNull);
  });

  testWidgets('la cruz borra una fecha elegida', (tester) async {
    final resultado = await _abrir(
      tester,
      actual: FiltroHistorial(
        desde: DateTime(2026, 11, 3),
        hasta: DateTime(2026, 11, 10),
      ),
    );

    // Hay una cruz por cada fecha puesta; se borra la primera ("Desde").
    await tester.tap(find.byIcon(Icons.clear).first);
    await tester.pumpAndSettle();
    await _tocar(tester, 'Filtrar');

    expect(resultado.filtro!.desde, isNull);
    expect(resultado.filtro!.hasta, DateTime(2026, 11, 10));
  });

  testWidgets('cerrar tocando afuera no devuelve nada', (tester) async {
    final resultado = await _abrir(
      tester,
      actual: const FiltroHistorial(tipo: TipoMovimiento.salida),
    );

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(resultado.filtro, isNull);
  });
}
