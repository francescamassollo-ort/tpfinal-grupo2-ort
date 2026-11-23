import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/alerta.dart';
import 'package:tpfinal_grupo2/models/filtro_alertas.dart';
import 'package:tpfinal_grupo2/screens/alertas/alertas_filtro_dialog.dart';

// Lo que el panel devolvió al cerrarse. Queda null si se cerró sin elegir.
class _Resultado {
  FiltroAlertas? filtro;
}

// Abre el panel como lo hace la pantalla real: con showDialog.
Future<_Resultado> _abrir(
  WidgetTester tester, {
  FiltroAlertas actual = const FiltroAlertas(),
}) async {
  // Un celular alto para que el desplegable abierto entre sin desbordar.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final resultado = _Resultado();
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                resultado.filtro =
                    await AlertasFiltroDialog.mostrar(context, actual);
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
  testWidgets('sin nada elegido muestra "Todos" y "Todas"', (tester) async {
    await _abrir(tester);

    expect(find.text('Tipo de alerta'), findsOneWidget);
    expect(find.text('Estado'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Todas'), findsOneWidget);
  });

  testWidgets('abre con lo que ya estaba elegido', (tester) async {
    await _abrir(
      tester,
      actual: const FiltroAlertas(
        tipo: TipoAlerta.vencido,
        estado: EstadoVistaAlerta.sinVer,
      ),
    );

    expect(find.text('Vencido'), findsOneWidget);
    expect(find.text('Sin ver'), findsOneWidget);
  });

  testWidgets('Filtrar sin cambiar nada devuelve el mismo filtro', (tester) async {
    const actual = FiltroAlertas(
      tipo: TipoAlerta.stockBajo,
      estado: EstadoVistaAlerta.vistas,
    );
    final resultado = await _abrir(tester, actual: actual);

    await _tocar(tester, 'Filtrar');

    expect(resultado.filtro, actual);
  });

  testWidgets('elegir un tipo y Filtrar lo devuelve', (tester) async {
    final resultado = await _abrir(tester);

    await _elegirOpcion(tester, campo: 'Tipo de alerta', opcion: 'Sin stock');
    await _tocar(tester, 'Filtrar');

    expect(resultado.filtro, const FiltroAlertas(tipo: TipoAlerta.sinStock));
  });

  testWidgets('elegir un estado y Filtrar lo devuelve', (tester) async {
    final resultado = await _abrir(tester);

    await _elegirOpcion(tester, campo: 'Estado', opcion: 'Sin ver');
    await _tocar(tester, 'Filtrar');

    expect(
      resultado.filtro,
      const FiltroAlertas(estado: EstadoVistaAlerta.sinVer),
    );
  });

  testWidgets('tipo y estado se devuelven juntos', (tester) async {
    final resultado = await _abrir(tester);

    await _elegirOpcion(tester, campo: 'Tipo de alerta', opcion: 'Vencimiento cercano');
    await _elegirOpcion(tester, campo: 'Estado', opcion: 'Vistas');
    await _tocar(tester, 'Filtrar');

    expect(
      resultado.filtro,
      const FiltroAlertas(
        tipo: TipoAlerta.vencimientoCercano,
        estado: EstadoVistaAlerta.vistas,
      ),
    );
  });

  testWidgets('el desplegable de tipo ofrece todos los tipos de alerta',
      (tester) async {
    await _abrir(tester);

    await tester.tap(find.widgetWithText(InputDecorator, 'Tipo de alerta'));
    await tester.pumpAndSettle();

    for (final tipo in TipoAlerta.values) {
      expect(
        find.text(AlertasFiltroDialog.nombreDelTipo(tipo)),
        findsWidgets,
        reason: 'falta ${tipo.name}',
      );
    }
    expect(find.text('Todos'), findsWidgets);
  });

  testWidgets('volver a "Todos" quita el tipo', (tester) async {
    final resultado = await _abrir(
      tester,
      actual: const FiltroAlertas(tipo: TipoAlerta.vencido),
    );

    await _elegirOpcion(tester, campo: 'Tipo de alerta', opcion: 'Todos');
    await _tocar(tester, 'Filtrar');

    expect(resultado.filtro, const FiltroAlertas());
    expect(resultado.filtro!.tipo, isNull);
  });

  testWidgets('Limpiar devuelve un filtro vacío', (tester) async {
    final resultado = await _abrir(
      tester,
      actual: const FiltroAlertas(
        tipo: TipoAlerta.vencido,
        estado: EstadoVistaAlerta.vistas,
      ),
    );

    await _tocar(tester, 'Limpiar');

    expect(resultado.filtro, const FiltroAlertas());
    expect(resultado.filtro!.estaVacio, isTrue);
  });

  testWidgets('cerrar tocando afuera no cambia nada (devuelve null)', (tester) async {
    final resultado = await _abrir(tester);

    await _elegirOpcion(tester, campo: 'Tipo de alerta', opcion: 'Vencido');
    // Se toca fuera del panel, sobre la barrera.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.text('Filtrar'), findsNothing);
    expect(resultado.filtro, isNull);
  });
}
