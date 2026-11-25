import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/core/app_colors.dart';
import 'package:tpfinal_grupo2/core/app_shell.dart';
import 'package:tpfinal_grupo2/models/alerta.dart';
import 'package:tpfinal_grupo2/models/usuario.dart';
import 'package:tpfinal_grupo2/providers/alerta_provider.dart';
import 'package:tpfinal_grupo2/providers/role_provider.dart';

import 'helpers/pantalla_celular.dart';

Alerta _alerta(String id, TipoAlerta tipo) =>
    Alerta(productoId: id, productoNombre: 'Insumo $id', tipo: tipo);

Future<void> _mostrar(
  WidgetTester tester,
  AsyncValue<List<Alerta>> alertas, {
  Set<String> vistas = const {},
}) async {
  usarPantallaDeCelular(tester);
  // Tamaño de un celular (360 x 800): estas pruebas son de la barra inferior,
  // que solo se usa en ancho angosto. El de escritorio se prueba en
  // app_shell_responsive_test.dart.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        alertasProvider.overrideWithValue(alertas),
        // Las marcas de "vista" de la persona, sin ir a Firestore.
        alertasVistasProvider.overrideWith((ref) => Stream.value(vistas)),
        // El rol de la persona, sin ir a Firebase.
        rolDeSesionProvider.overrideWith(
          (ref) => Stream.value(UserRole.administrador),
        ),
      ],
      child: const MaterialApp(
        home: AppShell(location: '/inventario', child: SizedBox()),
      ),
    ),
  );
  // Deja que llegue el stream de las marcas.
  await tester.pump();
}

Badge _campana(WidgetTester tester) {
  return tester.widget<Badge>(
    find.descendant(
      of: find.byType(BottomAppBar),
      matching: find.byType(Badge),
    ),
  );
}

void main() {
  testWidgets('sin alertas la campana va sin número', (tester) async {
    await _mostrar(tester, const AsyncData(<Alerta>[]));

    expect(_campana(tester).isLabelVisible, isFalse);
    expect(find.byTooltip('Alertas'), findsOneWidget);
  });

  testWidgets('con alertas muestra cuántas hay', (tester) async {
    await _mostrar(
      tester,
      AsyncData([
        _alerta('a', TipoAlerta.stockBajo),
        _alerta('b', TipoAlerta.agotamientoProximo),
        _alerta('c', TipoAlerta.tpSinCobertura),
      ]),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.byTooltip('Alertas (3)'), findsOneWidget);
  });

  testWidgets('con más de 99 alertas dice 99+', (tester) async {
    await _mostrar(
      tester,
      AsyncData([
        for (var i = 0; i < 120; i++) _alerta('$i', TipoAlerta.stockBajo),
      ]),
    );

    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('va en rojo si alguna alerta es crítica', (tester) async {
    await _mostrar(
      tester,
      AsyncData([
        _alerta('a', TipoAlerta.agotamientoProximo),
        _alerta('b', TipoAlerta.sinStock),
      ]),
    );

    expect(_campana(tester).backgroundColor, AppColors.stockDanger);
  });

  testWidgets('va en naranja si son solo avisos', (tester) async {
    await _mostrar(
      tester,
      AsyncData([
        _alerta('a', TipoAlerta.agotamientoProximo),
        _alerta('b', TipoAlerta.vencimientoCercano),
      ]),
    );

    expect(_campana(tester).backgroundColor, AppColors.stockWarning);
  });

  testWidgets('mientras cargan las alertas no muestra número', (tester) async {
    await _mostrar(tester, const AsyncLoading<List<Alerta>>());

    expect(_campana(tester).isLabelVisible, isFalse);
  });

  testWidgets('si las alertas fallan no muestra número ni se cae', (tester) async {
    await _mostrar(
      tester,
      AsyncError<List<Alerta>>('sin permiso', StackTrace.empty),
    );

    expect(_campana(tester).isLabelVisible, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('las alertas que ya vio no cuentan', (tester) async {
    await _mostrar(
      tester,
      AsyncData([
        _alerta('a', TipoAlerta.stockBajo),
        _alerta('b', TipoAlerta.agotamientoProximo),
        _alerta('c', TipoAlerta.tpSinCobertura),
      ]),
      vistas: {'a-stockBajo'},
    );

    expect(find.text('2'), findsOneWidget);
    expect(find.byTooltip('Alertas (2)'), findsOneWidget);
  });

  testWidgets('si vio todas, la campana va sin número', (tester) async {
    await _mostrar(
      tester,
      AsyncData([_alerta('a', TipoAlerta.stockBajo)]),
      vistas: {'a-stockBajo'},
    );

    expect(_campana(tester).isLabelVisible, isFalse);
  });

  testWidgets('el color mira solo las que no vio: una crítica vista no lo pone rojo', (tester) async {
    await _mostrar(
      tester,
      AsyncData([
        _alerta('a', TipoAlerta.sinStock),
        _alerta('b', TipoAlerta.agotamientoProximo),
      ]),
      vistas: {'a-sinStock'},
    );

    expect(_campana(tester).backgroundColor, AppColors.stockWarning);
  });
}
