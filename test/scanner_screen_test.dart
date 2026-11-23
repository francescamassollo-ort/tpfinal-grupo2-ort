import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tpfinal_grupo2/models/datos_escaneados.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/resultado_codigo.dart';
import 'package:tpfinal_grupo2/providers/barcode_provider.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/stock_provider.dart';
import 'package:tpfinal_grupo2/screens/inventario/scanner_screen.dart';
import 'package:tpfinal_grupo2/services/barcode_service.dart';
import 'package:tpfinal_grupo2/services/stock_logica.dart';
import 'package:tpfinal_grupo2/services/stock_service.dart';

final _etanol = Insumo(
  id: 'p1',
  nombre: 'Etanol',
  tipo: InsumoTipo.comprado,
  stock: 12,
  ubicacion: 'Estante 1',
  umbralMinimo: 2,
  unidad: 'ml',
  codigoBarras: '7790001',
);

/// Reemplazo del servicio real: devuelve lo que se le indique y anota qué se le
/// pidió. No sale a internet.
class _BarcodeFalso extends BarcodeService {
  ResultadoCodigo resultado = const CodigoSinResultado();
  Object? error;
  Completer<void>? espera;

  final codigos = <String>[];
  List<Insumo> insumosRecibidos = const [];

  @override
  Future<ResultadoCodigo> buscar(
    String codigo, {
    Iterable<Insumo> insumos = const [],
  }) async {
    codigos.add(codigo);
    insumosRecibidos = insumos.toList();
    if (espera != null) await espera!.future;
    if (error != null) throw error!;
    return resultado;
  }
}

class _StockFalso extends StockService {
  final entradas = <({String insumoId, int cantidad, String motivo})>[];
  Object? error;

  @override
  Future<void> registrarEntrada(String insumoId, int cantidad, String motivo) async {
    entradas.add((insumoId: insumoId, cantidad: cantidad, motivo: motivo));
    if (error != null) throw error!;
  }
}

class _Caso {
  final barcode = _BarcodeFalso();
  final stock = _StockFalso();

  /// Lo que devolvió el escáner al cerrarse.
  DatosEscaneados? devuelto;
  bool volvio = false;
}

// Una "cámara" de mentira: un botón que simula leer el código indicado.
Widget _camaraFalsa(BuildContext context, ValueChanged<String> onCodigo) {
  return Center(
    child: ElevatedButton(
      onPressed: () => onCodigo('7790001'),
      child: const Text('leer'),
    ),
  );
}

// Abre el escáner como lo hace el Alta: con push y esperando lo que devuelve.
Future<_Caso> _abrir(WidgetTester tester, {_Caso? caso}) async {
  final c = caso ?? _Caso();

  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                c.devuelto = await context.push<DatosEscaneados>('/scanner');
                c.volvio = true;
              },
              child: const Text('abrir escáner'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) =>
            const ScannerScreen(camaraBuilder: _camaraFalsa),
      ),
      GoRoute(
        path: '/insumo/:id',
        builder: (context, state) =>
            Scaffold(body: Text('DETALLE ${state.pathParameters['id']}')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        insumosProvider.overrideWith((ref) => Stream.value([_etanol])),
        barcodeServiceProvider.overrideWithValue(c.barcode),
        stockServiceProvider.overrideWithValue(c.stock),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.tap(find.text('abrir escáner'));
  await tester.pumpAndSettle();
  return c;
}

Future<void> _leer(WidgetTester tester) async {
  await tester.tap(find.text('leer'));
  await tester.pumpAndSettle();
}

Future<void> _tocar(WidgetTester tester, String texto) async {
  await tester.tap(find.text(texto));
  await tester.pumpAndSettle();
}

void main() {
  group('antes de leer', () {
    testWidgets('muestra la cámara y la indicación', (tester) async {
      await _abrir(tester);

      expect(find.text('leer'), findsOneWidget);
      expect(find.text('Apuntá la cámara al código de barras del producto'), findsOneWidget);
    });

    testWidgets('la flecha de volver cierra el escáner sin devolver nada',
        (tester) async {
      final caso = await _abrir(tester);

      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();

      expect(caso.volvio, isTrue);
      expect(caso.devuelto, isNull);
    });
  });

  group('al leer un código', () {
    testWidgets('busca ese código con los insumos cargados y avisa que busca',
        (tester) async {
      final caso = _Caso()..barcode.espera = Completer<void>();
      await _abrir(tester, caso: caso);

      await tester.tap(find.text('leer'));
      await tester.pump();

      expect(find.text('Buscando datos del código…'), findsOneWidget);
      expect(caso.barcode.codigos, ['7790001']);
      expect(caso.barcode.insumosRecibidos.map((i) => i.id), ['p1']);

      caso.barcode.espera!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('si el servicio falla, no queda colgado en "buscando"', (tester) async {
      final caso = _Caso()..barcode.error = Exception('boom');
      await _abrir(tester, caso: caso);

      await _leer(tester);

      expect(find.text('Buscando datos del código…'), findsNothing);
      expect(find.text('No encontramos este código'), findsOneWidget);
    });
  });

  group('un insumo que ya tenemos', () {
    _Caso casoEnInventario() =>
        _Caso()..barcode.resultado = CodigoEnInventario(_etanol);

    testWidgets('muestra su nombre y su stock con "Editar" y "Sumar stock"',
        (tester) async {
      await _abrir(tester, caso: casoEnInventario());
      await _leer(tester);

      expect(find.text('CÓDIGO DETECTADO · AUTOCOMPLETADO'), findsOneWidget);
      expect(find.text('Etanol'), findsOneWidget);
      expect(find.text('Stock actual: 12 ml'), findsOneWidget);
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Sumar stock'), findsOneWidget);
    });

    testWidgets('"Editar" abre el detalle del insumo', (tester) async {
      await _abrir(tester, caso: casoEnInventario());
      await _leer(tester);

      await _tocar(tester, 'Editar');

      expect(find.text('DETALLE p1'), findsOneWidget);
    });

    testWidgets('"Sumar stock" pide la cantidad, la registra y avisa', (tester) async {
      final caso = casoEnInventario();
      await _abrir(tester, caso: caso);
      await _leer(tester);

      await _tocar(tester, 'Sumar stock');
      await tester.tap(find.byTooltip('Aumentar cantidad'));
      await tester.tap(find.byTooltip('Aumentar cantidad'));
      await tester.pump();
      await _tocar(tester, 'Sumar');

      expect(caso.stock.entradas, [(insumoId: 'p1', cantidad: 3, motivo: 'Reposición')]);
      expect(find.text('Se sumaron 3 a Etanol'), findsOneWidget);
      // Vuelve a la pantalla anterior.
      expect(caso.volvio, isTrue);
    });

    testWidgets('la cantidad a sumar nunca baja de 1', (tester) async {
      final caso = casoEnInventario();
      await _abrir(tester, caso: caso);
      await _leer(tester);

      await _tocar(tester, 'Sumar stock');
      await tester.tap(find.byTooltip('Disminuir cantidad'));
      await tester.tap(find.byTooltip('Disminuir cantidad'));
      await tester.pump();
      await _tocar(tester, 'Sumar');

      expect(caso.stock.entradas.single.cantidad, 1);
    });

    testWidgets('cancelar el panel no suma nada', (tester) async {
      final caso = casoEnInventario();
      await _abrir(tester, caso: caso);
      await _leer(tester);

      await _tocar(tester, 'Sumar stock');
      await _tocar(tester, 'Cancelar');

      expect(caso.stock.entradas, isEmpty);
      expect(find.text('Sumar stock'), findsOneWidget);
    });

    testWidgets('si no se puede sumar, lo dice y se queda en el escáner',
        (tester) async {
      final caso = casoEnInventario()
        ..stock.error = const StockException('Insumo no encontrado');
      await _abrir(tester, caso: caso);
      await _leer(tester);

      await _tocar(tester, 'Sumar stock');
      await _tocar(tester, 'Sumar');

      expect(find.text('Insumo no encontrado'), findsOneWidget);
      expect(caso.volvio, isFalse);
    });

    testWidgets('un error inesperado se avisa sin el detalle técnico', (tester) async {
      final caso = casoEnInventario()..stock.error = Exception('permission-denied');
      await _abrir(tester, caso: caso);
      await _leer(tester);

      await _tocar(tester, 'Sumar stock');
      await _tocar(tester, 'Sumar');

      expect(find.text('No se pudo sumar el stock'), findsOneWidget);
      expect(find.textContaining('permission-denied'), findsNothing);
    });
  });

  group('un producto que conoce una base externa', () {
    _Caso casoConocido({
      String? marca = 'Merck',
      String? formula = 'C2H6O',
      double? peso = 46.07,
    }) =>
        _Caso()
          ..barcode.resultado = CodigoConocido(
            nombre: 'Ethanol 96% 1L',
            marca: marca,
            formula: formula,
            pesoMolecular: peso,
          );

    testWidgets('muestra el nombre editable y lo que sabe', (tester) async {
      await _abrir(tester, caso: casoConocido());
      await _leer(tester);

      expect(find.text('CÓDIGO DETECTADO · AUTOCOMPLETADO'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Ethanol 96% 1L'), findsOneWidget);
      expect(find.text('Merck · Fórmula: C2H6O · Peso molecular: 46,07'), findsOneWidget);
    });

    testWidgets('"Usar estos datos" devuelve todo, con el nombre corregido',
        (tester) async {
      final caso = casoConocido();
      await _abrir(tester, caso: caso);
      await _leer(tester);

      await tester.enterText(find.byType(TextField), '  Etanol 96%  ');
      await _tocar(tester, 'Usar estos datos');

      expect(
        caso.devuelto,
        const DatosEscaneados(
          codigo: '7790001',
          nombre: 'Etanol 96%',
          marca: 'Merck',
          formula: 'C2H6O',
          pesoMolecular: 46.07,
        ),
      );
    });

    testWidgets('si se borra el nombre, no devuelve nombre', (tester) async {
      final caso = casoConocido();
      await _abrir(tester, caso: caso);
      await _leer(tester);

      await tester.enterText(find.byType(TextField), '   ');
      await _tocar(tester, 'Usar estos datos');

      expect(caso.devuelto?.nombre, isNull);
      expect(caso.devuelto?.codigo, '7790001');
    });

    testWidgets('sin fórmula ni marca muestra solo lo que hay', (tester) async {
      await _abrir(
        tester,
        caso: casoConocido(marca: null, formula: null, peso: null),
      );
      await _leer(tester);

      expect(find.textContaining('Fórmula'), findsNothing);
      expect(find.textContaining('Peso molecular'), findsNothing);
    });
  });

  group('un código que nadie conoce', () {
    testWidgets('lo dice y "Cargar a mano" devuelve solo el código', (tester) async {
      final caso = _Caso();
      await _abrir(tester, caso: caso);
      await _leer(tester);

      expect(find.text('No encontramos este código'), findsOneWidget);
      await _tocar(tester, 'Cargar a mano');

      expect(caso.devuelto, const DatosEscaneados(codigo: '7790001'));
    });

    testWidgets('si la búsqueda en internet no se pudo hacer, dice por qué',
        (tester) async {
      final caso = _Caso()
        ..barcode.resultado =
            const CodigoSinResultado(aviso: BarcodeService.avisoSinConexion);
      await _abrir(tester, caso: caso);
      await _leer(tester);

      expect(find.text(BarcodeService.avisoSinConexion), findsOneWidget);
    });

    testWidgets('sin aviso no inventa uno', (tester) async {
      await _abrir(tester);
      await _leer(tester);

      expect(find.textContaining('Sin conexión'), findsNothing);
    });
  });

  testWidgets('"Escanear de nuevo" vuelve a la cámara y permite leer otro código',
      (tester) async {
    final caso = _Caso();
    await _abrir(tester, caso: caso);
    await _leer(tester);

    await _tocar(tester, 'Escanear de nuevo');

    expect(find.text('Apuntá la cámara al código de barras del producto'), findsOneWidget);
    expect(find.text('No encontramos este código'), findsNothing);

    await _leer(tester);
    expect(caso.barcode.codigos, ['7790001', '7790001']);
  });
}
