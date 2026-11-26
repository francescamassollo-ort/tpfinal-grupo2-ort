import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/core/app_strings.dart';
import 'package:tpfinal_grupo2/core/permisos.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/usuario.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/role_provider.dart';
import 'package:tpfinal_grupo2/providers/stock_provider.dart';
import 'package:tpfinal_grupo2/screens/inventario/insumo_detalle_screen.dart';
import 'package:tpfinal_grupo2/services/stock_logica.dart';
import 'package:tpfinal_grupo2/services/stock_service.dart';

final _etanol = Insumo(
  id: 'i1',
  nombre: 'Etanol absoluto',
  tipo: InsumoTipo.comprado,
  stock: 10,
  ubicacion: 'Armario 1',
  umbralMinimo: 2,
);

/// El servicio de stock sin Firestore: anota las entradas que se le piden.
class _StockFalso extends Fake implements StockService {
  final entradas = <(String, int, String)>[];
  Object? falla;

  @override
  Future<void> registrarEntrada(
    String insumoId,
    int cantidad,
    String motivo, {
    void Function(Transaction transaccion)? junto,
  }) async {
    if (falla != null) throw falla!;
    entradas.add((insumoId, cantidad, motivo));
  }
}

Future<_StockFalso> _abrir(
  WidgetTester tester, {
  UserRole rol = UserRole.administrador,
  _StockFalso? stock,
}) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final fake = stock ?? _StockFalso();
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        stockServiceProvider.overrideWithValue(fake),
        insumosProvider.overrideWith((ref) => Stream.value([_etanol])),
        rolDeSesionProvider.overrideWith((ref) => Stream.value(rol)),
      ],
      child: const MaterialApp(
        home: Scaffold(body: InsumoDetalleScreen(insumoId: 'i1')),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  test('el permiso de sumar stock es del administrador y el ayudante, no del docente', () {
    expect(Permisos.puedeSumarStock(UserRole.administrador), isTrue);
    expect(Permisos.puedeSumarStock(UserRole.ayudante), isTrue);
    expect(Permisos.puedeSumarStock(UserRole.docente), isFalse);
  });

  testWidgets('el administrador ve "Sumar stock"', (tester) async {
    await _abrir(tester, rol: UserRole.administrador);

    expect(find.text(AppStrings.detalleSumarStock), findsOneWidget);
  });

  testWidgets('el docente no ve "Sumar stock"', (tester) async {
    await _abrir(tester, rol: UserRole.docente);

    expect(find.text(AppStrings.detalleSumarStock), findsNothing);
  });

  testWidgets('el ayudante también lo ve', (tester) async {
    await _abrir(tester, rol: UserRole.ayudante);

    expect(find.text(AppStrings.detalleSumarStock), findsOneWidget);
  });

  testWidgets('sumar registra una entrada de "Reposición" con la cantidad elegida', (tester) async {
    final stock = await _abrir(tester);

    await tester.tap(find.text(AppStrings.detalleSumarStock));
    await tester.pumpAndSettle();
    // Se abrió el cuadro para elegir la cantidad.
    expect(find.text(AppStrings.sumarStockConfirmar), findsOneWidget);

    // Sube la cantidad de 1 a 3 con el "+" del selector.
    await tester.tap(find.byTooltip(AppStrings.aumentarCantidad));
    await tester.tap(find.byTooltip(AppStrings.aumentarCantidad));
    await tester.pump();
    await tester.tap(find.text(AppStrings.sumarStockConfirmar));
    await tester.pumpAndSettle();

    expect(stock.entradas, [('i1', 3, 'Reposición')]);
    expect(find.text(AppStrings.escanerStockSumado(3, 'Etanol absoluto')), findsOneWidget);
    // Se queda en el detalle.
    expect(find.text('Etanol absoluto'), findsWidgets);
  });

  testWidgets('cancelar no suma nada', (tester) async {
    final stock = await _abrir(tester);

    await tester.tap(find.text(AppStrings.detalleSumarStock));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.cancelar));
    await tester.pumpAndSettle();

    expect(stock.entradas, isEmpty);
  });

  testWidgets('si el servicio rechaza la entrada muestra su mensaje', (tester) async {
    final stock = _StockFalso()..falla = const StockException('No se puede sumar ahora');
    await _abrir(tester, stock: stock);

    await tester.tap(find.text(AppStrings.detalleSumarStock));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.sumarStockConfirmar));
    await tester.pumpAndSettle();

    expect(find.text('No se puede sumar ahora'), findsOneWidget);
  });

  testWidgets('si falla por otra causa (sin conexión) dice que no se pudo', (tester) async {
    final stock = _StockFalso()..falla = Exception('sin conexión');
    await _abrir(tester, stock: stock);

    await tester.tap(find.text(AppStrings.detalleSumarStock));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.sumarStockConfirmar));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.escanerErrorSumar), findsOneWidget);
  });
}
