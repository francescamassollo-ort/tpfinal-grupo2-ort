import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tpfinal_grupo2/models/datos_escaneados.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/screens/inventario/insumo_alta_screen.dart';

// Lo que devuelve la "cámara" de mentira en cada botón.
const _completo = DatosEscaneados(
  codigo: '7790001',
  nombre: 'Etanol 96%',
  marca: 'Merck',
  formula: 'C2H6O',
  pesoMolecular: 46.07,
);
const _soloCodigo = DatosEscaneados(codigo: '7790002');

// Monta el Alta con un escáner de mentira: una pantalla con tres botones que
// vuelven con datos completos, con solo el código o sin nada.
Future<void> _abrirAlta(WidgetTester tester) async {
  // Un celular bien alto, para que entre todo el formulario sin desplazar.
  tester.view.physicalSize = const Size(1080, 7000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/alta',
    routes: [
      GoRoute(
        path: '/alta',
        builder: (context, state) => const Scaffold(body: InsumoAltaScreen()),
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) => Scaffold(
          body: Column(
            children: [
              ElevatedButton(
                onPressed: () => context.pop(_completo),
                child: const Text('devolver todo'),
              ),
              ElevatedButton(
                onPressed: () => context.pop(_soloCodigo),
                child: const Text('devolver solo código'),
              ),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('volver sin nada'),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        insumosProvider.overrideWith((ref) => Stream.value(<Insumo>[])),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _escanear(WidgetTester tester, String boton) async {
  await tester.tap(find.text('Escanear código de barras'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(boton));
  await tester.pumpAndSettle();
}

Future<void> _escribir(WidgetTester tester, String campo, String texto) async {
  await tester.enterText(find.widgetWithText(TextFormField, campo), texto);
}

String _valorDe(WidgetTester tester, String campo) {
  final field = tester.widget<TextFormField>(
    find.widgetWithText(TextFormField, campo),
  );
  return field.controller!.text;
}

Future<void> _elegirTipoSolucion(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(InputDecorator, 'Tipo'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Solución preparada').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el Alta ofrece el botón de escanear y el campo Fórmula',
      (tester) async {
    await _abrirAlta(tester);

    expect(find.text('Escanear código de barras'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Fórmula'), findsOneWidget);
  });

  testWidgets('con todos los datos completa el formulario', (tester) async {
    await _abrirAlta(tester);

    await _escanear(tester, 'devolver todo');

    expect(_valorDe(tester, 'Código de barras'), '7790001');
    expect(_valorDe(tester, 'Nombre'), 'Etanol 96%');
    expect(_valorDe(tester, 'Marca'), 'Merck');
    expect(_valorDe(tester, 'Fórmula'), 'C2H6O');
    expect(_valorDe(tester, 'Peso molecular'), '46.07');
    expect(find.text('Se completaron los datos con el código escaneado'), findsOneWidget);
  });

  testWidgets('con solo el código, completa el código y nada más', (tester) async {
    await _abrirAlta(tester);

    await _escanear(tester, 'devolver solo código');

    expect(_valorDe(tester, 'Código de barras'), '7790002');
    expect(_valorDe(tester, 'Nombre'), '');
    expect(_valorDe(tester, 'Marca'), '');
    // No hay datos que avisar: solo se leyó el código.
    expect(find.text('Se completaron los datos con el código escaneado'), findsNothing);
  });

  testWidgets('volver sin nada no cambia el formulario', (tester) async {
    await _abrirAlta(tester);
    await _escribir(tester, 'Nombre', 'Algo que ya escribí');

    await _escanear(tester, 'volver sin nada');

    expect(_valorDe(tester, 'Nombre'), 'Algo que ya escribí');
    expect(_valorDe(tester, 'Código de barras'), '');
  });

  testWidgets('un escaneo no pisa lo que ya se escribió', (tester) async {
    await _abrirAlta(tester);
    await _escribir(tester, 'Nombre', 'Mi etanol');
    await _escribir(tester, 'Marca', 'Cicarelli');

    await _escanear(tester, 'devolver todo');

    expect(_valorDe(tester, 'Nombre'), 'Mi etanol');
    expect(_valorDe(tester, 'Marca'), 'Cicarelli');
    // Lo que estaba vacío sí se completa.
    expect(_valorDe(tester, 'Fórmula'), 'C2H6O');
  });

  testWidgets('el código leído reemplaza al que había', (tester) async {
    await _abrirAlta(tester);
    await _escribir(tester, 'Código de barras', '111');

    await _escanear(tester, 'devolver todo');

    expect(_valorDe(tester, 'Código de barras'), '7790001');
  });

  testWidgets('en una solución preparada completa el nombre pero no la química',
      (tester) async {
    await _abrirAlta(tester);
    await _elegirTipoSolucion(tester);

    expect(find.widgetWithText(TextFormField, 'Fórmula'), findsNothing);
    await _escanear(tester, 'devolver todo');

    expect(_valorDe(tester, 'Nombre'), 'Etanol 96%');
    expect(_valorDe(tester, 'Código de barras'), '7790001');
    expect(find.widgetWithText(TextFormField, 'Marca'), findsNothing);
  });
}
