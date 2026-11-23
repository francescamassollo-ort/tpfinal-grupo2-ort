import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/alerta.dart';
import 'package:tpfinal_grupo2/models/filtro_alertas.dart';
import 'package:tpfinal_grupo2/providers/alerta_provider.dart';
import 'package:tpfinal_grupo2/screens/alertas/alertas_screen.dart';

/// Reemplazo de las acciones reales: no escribe en Firestore.
class _AccionesFalsas implements AlertasAcciones {
  @override
  Future<void> marcarVista(Alerta alerta) async {}

  @override
  Future<void> marcarNoVista(Alerta alerta) async {}

  @override
  Future<void> limpiarObsoletas() async {}
}

/// Un filtro que ya viene puesto al abrir la pantalla.
class _FiltroInicial extends FiltroAlertasNotifier {
  _FiltroInicial(this._inicial);

  final FiltroAlertas _inicial;

  @override
  FiltroAlertas build() => _inicial;
}

const _sinStock =
    Alerta(productoId: 'p1', productoNombre: 'Etanol', tipo: TipoAlerta.sinStock);
const _stockBajo =
    Alerta(productoId: 'p2', productoNombre: 'Agar LB', tipo: TipoAlerta.stockBajo);
const _vencido =
    Alerta(productoId: 'p3', productoNombre: 'Glicerol', tipo: TipoAlerta.vencido);

Future<void> _abrirPantalla(
  WidgetTester tester, {
  List<Alerta> alertas = const [_sinStock, _stockBajo],
  Set<String> vistas = const {},
  FiltroAlertas? filtroInicial,
}) async {
  // Un celular alto, para que entren las filas y el panel sin desbordar.
  tester.view.physicalSize = const Size(1200, 2700);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        alertasProvider.overrideWithValue(AsyncData(alertas)),
        alertasVistasProvider.overrideWith((ref) => Stream.value(vistas)),
        alertasAccionesProvider.overrideWithValue(_AccionesFalsas()),
        if (filtroInicial != null)
          filtroAlertasProvider.overrideWith(() => _FiltroInicial(filtroInicial)),
      ],
      child: const MaterialApp(home: Scaffold(body: AlertasScreen())),
    ),
  );
  // Deja que llegue el stream de las marcas.
  await tester.pump();
}

Future<void> _abrirPanel(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Filtros'));
  await tester.pumpAndSettle();
}

Future<void> _elegirOpcion(
  WidgetTester tester, {
  required String campo,
  required String opcion,
}) async {
  await tester.tap(find.widgetWithText(InputDecorator, campo));
  await tester.pumpAndSettle();
  await tester.tap(find.text(opcion).last);
  await tester.pumpAndSettle();
}

Future<void> _tocar(WidgetTester tester, String texto) async {
  await tester.tap(find.text(texto));
  await tester.pumpAndSettle();
}

bool _puntoVisible(WidgetTester tester) =>
    tester.widget<Badge>(find.byType(Badge).first).isLabelVisible;

void main() {
  testWidgets('sin filtro se ven todas las alertas y no hay punto', (tester) async {
    await _abrirPantalla(tester);

    expect(find.text('Etanol'), findsOneWidget);
    expect(find.text('Agar LB'), findsOneWidget);
    expect(_puntoVisible(tester), isFalse);
  });

  testWidgets('el ícono de filtros abre el panel', (tester) async {
    await _abrirPantalla(tester);

    await _abrirPanel(tester);

    expect(find.text('Tipo de alerta'), findsOneWidget);
    expect(find.text('Estado'), findsOneWidget);
  });

  testWidgets('filtrar por tipo deja solo ese tipo y muestra el punto',
      (tester) async {
    await _abrirPantalla(tester);

    await _abrirPanel(tester);
    await _elegirOpcion(tester, campo: 'Tipo de alerta', opcion: 'Sin stock');
    await _tocar(tester, 'Filtrar');

    expect(find.text('Etanol'), findsOneWidget);
    expect(find.text('Agar LB'), findsNothing);
    expect(_puntoVisible(tester), isTrue);
  });

  testWidgets('filtrar por "Sin ver" esconde las ya vistas', (tester) async {
    await _abrirPantalla(tester, vistas: {'p1-sinStock'});

    await _abrirPanel(tester);
    await _elegirOpcion(tester, campo: 'Estado', opcion: 'Sin ver');
    await _tocar(tester, 'Filtrar');

    expect(find.text('Etanol'), findsNothing);
    expect(find.text('Agar LB'), findsOneWidget);
  });

  testWidgets('filtrar por "Vistas" deja solo las vistas', (tester) async {
    await _abrirPantalla(tester, vistas: {'p1-sinStock'});

    await _abrirPanel(tester);
    await _elegirOpcion(tester, campo: 'Estado', opcion: 'Vistas');
    await _tocar(tester, 'Filtrar');

    expect(find.text('Etanol'), findsOneWidget);
    expect(find.text('Agar LB'), findsNothing);
  });

  testWidgets('el panel vuelve a abrir con lo que ya estaba elegido',
      (tester) async {
    await _abrirPantalla(tester);
    await _abrirPanel(tester);
    await _elegirOpcion(tester, campo: 'Tipo de alerta', opcion: 'Sin stock');
    await _tocar(tester, 'Filtrar');

    await _abrirPanel(tester);

    expect(find.text('Sin stock'), findsWidgets);
    expect(find.text('Todos'), findsNothing);
  });

  testWidgets('si ninguna coincide lo dice y ofrece limpiar los filtros',
      (tester) async {
    await _abrirPantalla(tester);

    await _abrirPanel(tester);
    await _elegirOpcion(tester, campo: 'Tipo de alerta', opcion: 'Vencido');
    await _tocar(tester, 'Filtrar');

    expect(find.text('Ninguna alerta coincide con los filtros'), findsOneWidget);
    expect(find.text('Limpiar filtros'), findsOneWidget);
    expect(find.text('No hay alertas por ahora'), findsNothing);
  });

  testWidgets('Limpiar filtros devuelve la lista completa y saca el punto',
      (tester) async {
    await _abrirPantalla(
      tester,
      filtroInicial: const FiltroAlertas(tipo: TipoAlerta.vencido),
    );
    expect(find.text('Limpiar filtros'), findsOneWidget);
    expect(_puntoVisible(tester), isTrue);

    await _tocar(tester, 'Limpiar filtros');

    expect(find.text('Etanol'), findsOneWidget);
    expect(find.text('Agar LB'), findsOneWidget);
    expect(_puntoVisible(tester), isFalse);
  });

  testWidgets('"Limpiar" del panel también saca el filtro', (tester) async {
    await _abrirPantalla(
      tester,
      filtroInicial: const FiltroAlertas(tipo: TipoAlerta.sinStock),
    );
    expect(find.text('Agar LB'), findsNothing);

    await _abrirPanel(tester);
    await _tocar(tester, 'Limpiar');

    expect(find.text('Agar LB'), findsOneWidget);
    expect(_puntoVisible(tester), isFalse);
  });

  testWidgets('si no hay ninguna alerta no ofrece limpiar filtros aunque haya uno',
      (tester) async {
    await _abrirPantalla(
      tester,
      alertas: const [],
      filtroInicial: const FiltroAlertas(tipo: TipoAlerta.vencido),
    );

    expect(find.text('No hay alertas por ahora'), findsOneWidget);
    expect(find.text('Limpiar filtros'), findsNothing);
  });

  testWidgets('el filtro se combina: tipo y estado a la vez', (tester) async {
    await _abrirPantalla(
      tester,
      alertas: const [_sinStock, _stockBajo, _vencido],
      vistas: {'p1-sinStock'},
    );

    await _abrirPanel(tester);
    await _elegirOpcion(tester, campo: 'Tipo de alerta', opcion: 'Sin stock');
    await _elegirOpcion(tester, campo: 'Estado', opcion: 'Sin ver');
    await _tocar(tester, 'Filtrar');

    // Etanol es de sin stock pero ya está vista; el resto no es de ese tipo.
    expect(find.text('Etanol'), findsNothing);
    expect(find.text('Agar LB'), findsNothing);
    expect(find.text('Glicerol'), findsNothing);
    expect(find.text('Ninguna alerta coincide con los filtros'), findsOneWidget);
  });
}
