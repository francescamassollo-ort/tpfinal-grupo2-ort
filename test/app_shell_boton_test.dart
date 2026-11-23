import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/core/app_shell.dart';
import 'package:tpfinal_grupo2/models/alerta.dart';
import 'package:tpfinal_grupo2/models/usuario.dart';
import 'package:tpfinal_grupo2/providers/alerta_provider.dart';
import 'package:tpfinal_grupo2/providers/role_provider.dart';

// Monta el shell en la ruta indicada, sin ir a Firestore.
Future<void> _mostrar(WidgetTester tester, String ruta) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        alertasProvider.overrideWithValue(const AsyncData(<Alerta>[])),
        alertasVistasProvider.overrideWith((ref) => Stream.value(<String>{})),
        rolDeSesionProvider.overrideWith(
          (ref) => Stream.value(UserRole.administrador),
        ),
      ],
      child: MaterialApp(
        home: AppShell(location: ruta, child: const SizedBox()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('botón flotante "+"', () {
    testWidgets('en Inventario lleva a dar de alta un insumo', (tester) async {
      await _mostrar(tester, '/inventario');

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('en el Alta de insumo no está: taparía "Guardar"', (tester) async {
      await _mostrar(tester, '/insumo/alta');

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('en el detalle de un insumo no está: taparía "Registrar consumo"',
        (tester) async {
      await _mostrar(tester, '/insumo/86OLagimTYcYMKZflffo');

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('en Alertas no está, como en el diseño', (tester) async {
      await _mostrar(tester, '/alertas');

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('en la lista de TPs está (crear un TP)', (tester) async {
      await _mostrar(tester, '/tp');

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    for (final ruta in ['/perfil', '/usuarios', '/inventario/filtro']) {
      testWidgets('en $ruta no está', (tester) async {
        await _mostrar(tester, ruta);

        expect(find.byType(FloatingActionButton), findsNothing);
      });
    }

    testWidgets('en el detalle de un TP no está', (tester) async {
      await _mostrar(tester, '/tp/detalle/abc');

      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
}
