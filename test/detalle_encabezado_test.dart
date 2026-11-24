import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/core/app_strings.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/usuario.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/role_provider.dart';
import 'package:tpfinal_grupo2/screens/inventario/insumo_detalle_screen.dart';
import 'package:tpfinal_grupo2/widgets/app_screen_header.dart';

final _etanol = Insumo(
  id: 'i1',
  nombre: 'Etanol absoluto',
  tipo: InsumoTipo.comprado,
  stock: 10,
  ubicacion: 'Armario 1',
  umbralMinimo: 2,
);

Future<void> _abrir(WidgetTester tester, {List<Insumo> insumos = const [], UserRole rol = UserRole.administrador}) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        insumosProvider.overrideWith((ref) => Stream.value(insumos)),
        rolDeSesionProvider.overrideWith((ref) => Stream.value(rol)),
      ],
      child: const MaterialApp(home: Scaffold(body: InsumoDetalleScreen(insumoId: 'i1'))),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el Detalle usa el mismo encabezado que el resto, con el nombre y volver', (tester) async {
    await _abrir(tester, insumos: [_etanol]);

    expect(find.byType(AppScreenHeader), findsOneWidget);
    expect(find.byTooltip(AppStrings.volver), findsOneWidget);
    expect(find.text('Etanol absoluto'), findsWidgets);
  });

  testWidgets('el administrador ve editar y baja en el encabezado', (tester) async {
    await _abrir(tester, insumos: [_etanol]);

    expect(find.byTooltip('Editar'), findsOneWidget);
    expect(find.byTooltip('Dar de baja'), findsOneWidget);
  });

  testWidgets('el docente no ve editar ni baja', (tester) async {
    await _abrir(tester, insumos: [_etanol], rol: UserRole.docente);

    expect(find.byTooltip('Editar'), findsNothing);
    expect(find.byTooltip('Dar de baja'), findsNothing);
  });

  testWidgets('si el insumo no existe igual se puede volver', (tester) async {
    await _abrir(tester);

    expect(find.text(AppStrings.insumoNoExiste), findsOneWidget);
    expect(find.byTooltip(AppStrings.volver), findsOneWidget);
  });
}
