import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/alerta.dart';
import 'package:tpfinal_grupo2/providers/alerta_provider.dart';
import 'package:tpfinal_grupo2/screens/alertas/alertas_screen.dart';

/// Reemplazo de las acciones reales: no escribe en Firestore, solo anota qué
/// le pidieron.
class _AccionesFalsas implements AlertasAcciones {
  _AccionesFalsas({this.falla = false});

  /// Si es true, marcar o desmarcar falla, como si no hubiera conexión.
  final bool falla;

  final marcadas = <String>[];
  final desmarcadas = <String>[];
  var limpiezas = 0;

  @override
  Future<void> marcarVista(Alerta alerta) async {
    if (falla) throw Exception('sin conexión');
    marcadas.add(alerta.id);
  }

  @override
  Future<void> marcarNoVista(Alerta alerta) async {
    if (falla) throw Exception('sin conexión');
    desmarcadas.add(alerta.id);
  }

  @override
  Future<void> limpiarObsoletas() async {
    limpiezas++;
  }
}

final _alertas = [
  const Alerta(productoId: 'p1', productoNombre: 'Etanol', tipo: TipoAlerta.sinStock),
  const Alerta(productoId: 'p2', productoNombre: 'Agar LB', tipo: TipoAlerta.stockBajo),
];

Future<void> _abrirPantalla(
  WidgetTester tester, {
  required _AccionesFalsas acciones,
  Set<String> vistas = const {},
  AsyncValue<List<Alerta>>? alertas,
}) async {
  // Un celular alto, para que entren las filas sin desbordar.
  tester.view.physicalSize = const Size(1200, 2700);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        alertasProvider.overrideWithValue(alertas ?? AsyncData(_alertas)),
        alertasVistasProvider.overrideWith((ref) => Stream.value(vistas)),
        alertasAccionesProvider.overrideWithValue(acciones),
      ],
      // Dentro de un Scaffold, como en la app: la pantalla vive en el del
      // AppShell, y de ahí salen los avisos.
      child: const MaterialApp(home: Scaffold(body: AlertasScreen())),
    ),
  );
  // Deja que llegue el stream de las marcas.
  await tester.pump();
}

double _opacidadDeLaFila(WidgetTester tester, String nombre) {
  final fila = find.ancestor(
    of: find.text(nombre),
    matching: find.byType(Opacity),
  );
  return tester.widget<Opacity>(fila.first).opacity;
}

void main() {
  testWidgets('cada alerta trae su botón para marcarla como vista', (tester) async {
    await _abrirPantalla(tester, acciones: _AccionesFalsas());

    expect(find.byTooltip('Marcar como vista'), findsNWidgets(2));
  });

  testWidgets('marcar la primera guarda esa alerta y no la otra', (tester) async {
    final acciones = _AccionesFalsas();
    await _abrirPantalla(tester, acciones: acciones);

    await tester.tap(find.byTooltip('Marcar como vista').first);
    await tester.pump();

    expect(acciones.marcadas, ['p1-sinStock']);
    expect(acciones.desmarcadas, isEmpty);
  });

  testWidgets('una alerta vista se ve atenuada y la otra no', (tester) async {
    await _abrirPantalla(
      tester,
      acciones: _AccionesFalsas(),
      vistas: {'p1-sinStock'},
    );

    expect(_opacidadDeLaFila(tester, 'Etanol'), 0.5);
    expect(_opacidadDeLaFila(tester, 'Agar LB'), 1);
  });

  testWidgets('una alerta vista sigue en la lista', (tester) async {
    await _abrirPantalla(
      tester,
      acciones: _AccionesFalsas(),
      vistas: {'p1-sinStock', 'p2-stockBajo'},
    );

    expect(find.text('Etanol'), findsOneWidget);
    expect(find.text('Agar LB'), findsOneWidget);
  });

  testWidgets('en una vista, el botón la vuelve a marcar como no vista', (tester) async {
    final acciones = _AccionesFalsas();
    await _abrirPantalla(
      tester,
      acciones: acciones,
      vistas: {'p1-sinStock'},
    );

    await tester.tap(find.byTooltip('Marcar como no vista'));
    await tester.pump();

    expect(acciones.desmarcadas, ['p1-sinStock']);
    expect(acciones.marcadas, isEmpty);
  });

  testWidgets('si falla al marcar, lo dice', (tester) async {
    final acciones = _AccionesFalsas(falla: true);
    await _abrirPantalla(tester, acciones: acciones);

    await tester.tap(find.byTooltip('Marcar como vista').first);
    await tester.pump();

    expect(find.text('No se pudo actualizar la alerta'), findsOneWidget);
    expect(acciones.marcadas, isEmpty);
  });

  testWidgets('al abrir la pantalla se limpian las marcas que ya no corresponden', (tester) async {
    final acciones = _AccionesFalsas();
    await _abrirPantalla(tester, acciones: acciones);

    expect(acciones.limpiezas, greaterThan(0));
  });

  testWidgets('mientras cargan las alertas muestra el indicador', (tester) async {
    await _abrirPantalla(
      tester,
      acciones: _AccionesFalsas(),
      alertas: const AsyncLoading<List<Alerta>>(),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byTooltip('Marcar como vista'), findsNothing);
  });

  testWidgets('sin alertas lo dice', (tester) async {
    await _abrirPantalla(
      tester,
      acciones: _AccionesFalsas(),
      alertas: const AsyncData(<Alerta>[]),
    );

    expect(find.text('No hay alertas por ahora'), findsOneWidget);
  });

  testWidgets('si no se pueden leer las alertas, lo dice', (tester) async {
    await _abrirPantalla(
      tester,
      acciones: _AccionesFalsas(),
      alertas: AsyncError<List<Alerta>>('sin permiso', StackTrace.empty),
    );

    expect(find.text('No se pudieron cargar las alertas'), findsOneWidget);
  });
}
