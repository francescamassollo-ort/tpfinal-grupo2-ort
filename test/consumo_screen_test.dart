import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/stock_provider.dart';
import 'package:tpfinal_grupo2/screens/consumo/consumo_screen.dart';
import 'package:tpfinal_grupo2/services/stock_logica.dart';
import 'package:tpfinal_grupo2/services/stock_service.dart';

Insumo _insumo(
  String id,
  String nombre,
  int stock, {
  String? unidad,
  String ubicacion = 'Estante 1',
}) {
  return Insumo(
    id: id,
    nombre: nombre,
    tipo: InsumoTipo.comprado,
    stock: stock,
    ubicacion: ubicacion,
    umbralMinimo: 2,
    unidad: unidad,
  );
}

final _insumos = [
  _insumo('p1', 'Etanol', 12, unidad: 'ml'),
  _insumo('p2', 'Agar LB', 7),
  _insumo('p3', 'Glicerol', 0),
  _insumo('p4', 'Ácido acético', 5),
];

typedef _Llamada = ({List<LineaDeSalida> lineas, String motivo});

/// Reemplazo del servicio real: no toca Firestore, solo anota qué le pidieron.
class _StockFalso extends StockService {
  final llamadas = <_Llamada>[];

  /// Si no es null, registrarSalidas falla con esto.
  Object? error;

  /// Si no es null, registrarSalidas espera a que se complete.
  Completer<void>? espera;

  @override
  Future<void> registrarSalidas(List<LineaDeSalida> lineas, String motivo) async {
    llamadas.add((lineas: lineas, motivo: motivo));
    if (espera != null) await espera!.future;
    if (error != null) throw error!;
  }
}

Future<void> _abrir(
  WidgetTester tester,
  _StockFalso stock, {
  String? insumoId,
  List<Insumo>? insumos,
}) async {
  // Un celular de 360 x 800.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        insumosProvider.overrideWith((ref) => Stream.value(insumos ?? _insumos)),
        stockServiceProvider.overrideWithValue(stock),
      ],
      child: MaterialApp(home: ConsumoScreen(insumoId: insumoId)),
    ),
  );
  // Deja que llegue el stream de los insumos.
  await tester.pump();
}

Future<void> _tocar(WidgetTester tester, String texto) async {
  await tester.tap(find.text(texto));
  await tester.pumpAndSettle();
}

Future<void> _agregarInsumo(WidgetTester tester, String nombre) async {
  await _tocar(tester, '+ Agregar otro insumo');
  await tester.tap(find.text(nombre));
  await tester.pumpAndSettle();
}

Future<void> _sumar(WidgetTester tester, {int veces = 1, int fila = 0}) async {
  for (var i = 0; i < veces; i++) {
    await tester.tap(find.byTooltip('Aumentar cantidad').at(fila));
    await tester.pump();
  }
}

Future<void> _restar(WidgetTester tester, {int veces = 1, int fila = 0}) async {
  for (var i = 0; i < veces; i++) {
    await tester.tap(find.byTooltip('Disminuir cantidad').at(fila));
    await tester.pump();
  }
}

Future<void> _elegirMotivo(WidgetTester tester, String motivo) async {
  await tester.tap(find.widgetWithText(InputDecorator, 'Motivo'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(motivo).last);
  await tester.pumpAndSettle();
}

void main() {
  group('la pantalla', () {
    testWidgets('muestra el título, la consigna y el botón del diseño',
        (tester) async {
      await _abrir(tester, _StockFalso());

      expect(find.text('Registro de consumo'), findsOneWidget);
      expect(find.text('Seleccionar la cantidad de insumos a retirar'), findsOneWidget);
      expect(find.text('+ Agregar otro insumo'), findsOneWidget);
      expect(find.text('Confirmar salida'), findsOneWidget);
    });

    testWidgets('sin insumo elegido arranca sin filas ni motivo', (tester) async {
      await _abrir(tester, _StockFalso());

      expect(find.textContaining('Disponible'), findsNothing);
      expect(find.text('Motivo'), findsNothing);
    });

    testWidgets('con un insumo elegido arranca con su fila y 1 a retirar',
        (tester) async {
      await _abrir(tester, _StockFalso(), insumoId: 'p1');

      expect(find.text('Etanol'), findsOneWidget);
      expect(find.text('Disponible: 12 ml'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Motivo'), findsOneWidget);
    });

    testWidgets('sin unidad cargada dice "u."', (tester) async {
      await _abrir(tester, _StockFalso(), insumoId: 'p2');

      expect(find.text('Disponible: 7 u.'), findsOneWidget);
    });

    testWidgets('un id que no corresponde a ningún insumo se ignora',
        (tester) async {
      await _abrir(tester, _StockFalso(), insumoId: 'no-existe');

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Disponible'), findsNothing);
    });
  });

  group('la cantidad', () {
    testWidgets('sube y baja de a una', (tester) async {
      await _abrir(tester, _StockFalso(), insumoId: 'p1');

      await _sumar(tester, veces: 3);
      expect(find.text('4'), findsOneWidget);

      await _restar(tester);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('nunca baja de 1', (tester) async {
      await _abrir(tester, _StockFalso(), insumoId: 'p1');

      await _restar(tester, veces: 3);

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('nunca pasa de lo disponible', (tester) async {
      await _abrir(tester, _StockFalso(), insumoId: 'p4');

      await _sumar(tester, veces: 9);

      // El stock es 5.
      expect(find.text('5'), findsOneWidget);
    });
  });

  group('agregar otro insumo', () {
    testWidgets('abre el buscador y suma la fila elegida con 1 a retirar',
        (tester) async {
      await _abrir(tester, _StockFalso(), insumoId: 'p1');

      await _agregarInsumo(tester, 'Agar LB');

      expect(find.text('Agar LB'), findsOneWidget);
      expect(find.text('Disponible: 7 u.'), findsOneWidget);
      expect(find.text('Etanol'), findsOneWidget);
    });

    testWidgets('no ofrece los que ya están en la lista ni los sin stock',
        (tester) async {
      await _abrir(tester, _StockFalso(), insumoId: 'p1');

      await _tocar(tester, '+ Agregar otro insumo');

      expect(find.text('Agregar insumo'), findsOneWidget);
      // En la lista de la pantalla ya está Etanol: en el panel no se repite.
      expect(find.text('Etanol'), findsOneWidget);
      expect(find.text('Agar LB'), findsOneWidget);
      expect(find.text('Ácido acético'), findsOneWidget);
      expect(find.text('Glicerol'), findsNothing);
    });

    testWidgets('el buscador filtra sin mirar mayúsculas ni tildes',
        (tester) async {
      await _abrir(tester, _StockFalso());
      await _tocar(tester, '+ Agregar otro insumo');

      await tester.enterText(find.byType(TextField), 'ACIDO');
      await tester.pump();

      expect(find.text('Ácido acético'), findsOneWidget);
      expect(find.text('Etanol'), findsNothing);
      expect(find.text('Agar LB'), findsNothing);
    });

    testWidgets('si nada coincide con la búsqueda lo dice', (tester) async {
      await _abrir(tester, _StockFalso());
      await _tocar(tester, '+ Agregar otro insumo');

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();

      expect(find.text('Ningún insumo coincide con la búsqueda'), findsOneWidget);
    });

    testWidgets('cancelar no agrega nada', (tester) async {
      await _abrir(tester, _StockFalso());
      await _tocar(tester, '+ Agregar otro insumo');

      await _tocar(tester, 'Cancelar');

      expect(find.textContaining('Disponible'), findsNothing);
      expect(find.text('Agregar insumo'), findsNothing);
    });

    testWidgets('si ya no queda ninguno con stock lo avisa', (tester) async {
      final insumos = [_insumo('p1', 'Etanol', 12), _insumo('p3', 'Glicerol', 0)];
      await _abrir(tester, _StockFalso(), insumoId: 'p1', insumos: insumos);

      await _tocar(tester, '+ Agregar otro insumo');

      expect(find.text('No hay más insumos con stock para agregar'), findsOneWidget);
      expect(find.text('Agregar insumo'), findsNothing);
    });
  });

  testWidgets('deslizar una fila hacia la izquierda la saca de la lista',
      (tester) async {
    await _abrir(tester, _StockFalso(), insumoId: 'p1');
    await _agregarInsumo(tester, 'Agar LB');

    await tester.drag(find.text('Agar LB'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Agar LB'), findsNothing);
    expect(find.text('Etanol'), findsOneWidget);
  });

  group('confirmar', () {
    testWidgets('sin insumos no hace nada', (tester) async {
      final stock = _StockFalso();
      await _abrir(tester, stock);

      await _tocar(tester, 'Confirmar salida');

      expect(stock.llamadas, isEmpty);
    });

    testWidgets('manda todas las líneas con su cantidad y el motivo "TP"',
        (tester) async {
      final stock = _StockFalso();
      await _abrir(tester, stock, insumoId: 'p1');
      await _sumar(tester, veces: 2);
      await _agregarInsumo(tester, 'Agar LB');
      await _sumar(tester, fila: 1);

      await _tocar(tester, 'Confirmar salida');

      expect(stock.llamadas, hasLength(1));
      expect(stock.llamadas.single.motivo, 'TP');
      expect(stock.llamadas.single.lineas, [
        (insumoId: 'p1', cantidad: 3),
        (insumoId: 'p2', cantidad: 2),
      ]);
    });

    testWidgets('si sale bien avisa y deja la lista vacía', (tester) async {
      await _abrir(tester, _StockFalso(), insumoId: 'p1');

      await _tocar(tester, 'Confirmar salida');

      expect(find.text('Consumo registrado correctamente'), findsOneWidget);
      expect(find.text('Etanol'), findsNothing);
      expect(find.text('Motivo'), findsNothing);
    });

    testWidgets('con otro motivo manda el que se eligió', (tester) async {
      final stock = _StockFalso();
      await _abrir(tester, stock, insumoId: 'p1');

      await _elegirMotivo(tester, 'Clase');
      await _tocar(tester, 'Confirmar salida');

      expect(stock.llamadas.single.motivo, 'Clase');
    });

    testWidgets('"Otro" pide un detalle y no registra sin él', (tester) async {
      final stock = _StockFalso();
      await _abrir(tester, stock, insumoId: 'p1');

      await _elegirMotivo(tester, 'Otro');
      await _tocar(tester, 'Confirmar salida');

      expect(find.text('Escribí el detalle del motivo'), findsOneWidget);
      expect(stock.llamadas, isEmpty);
    });

    testWidgets('"Otro" manda el detalle escrito como motivo', (tester) async {
      final stock = _StockFalso();
      await _abrir(tester, stock, insumoId: 'p1');

      await _elegirMotivo(tester, 'Otro');
      await tester.enterText(
        find.widgetWithText(TextField, 'Detalle del motivo'),
        '  Práctica libre  ',
      );
      await _tocar(tester, 'Confirmar salida');

      expect(stock.llamadas.single.motivo, 'Práctica libre');
    });

    testWidgets('si falta stock de un insumo dice cuál y no vacía la lista',
        (tester) async {
      final stock = _StockFalso()
        ..error = const StockException('Stock insuficiente', insumoId: 'p2');
      await _abrir(tester, stock, insumoId: 'p1');
      await _agregarInsumo(tester, 'Agar LB');

      await _tocar(tester, 'Confirmar salida');

      expect(find.text('No hay stock suficiente de Agar LB'), findsOneWidget);
      // Se puede corregir y volver a intentar.
      expect(find.text('Etanol'), findsOneWidget);
      expect(find.text('Agar LB'), findsOneWidget);
    });

    testWidgets('si un insumo ya no existe dice cuál', (tester) async {
      final stock = _StockFalso()
        ..error = const StockException('Insumo no encontrado', insumoId: 'p1');
      await _abrir(tester, stock, insumoId: 'p1');

      await _tocar(tester, 'Confirmar salida');

      expect(find.text('Etanol ya no existe'), findsOneWidget);
    });

    testWidgets('un error inesperado se avisa sin mostrar el detalle técnico',
        (tester) async {
      final stock = _StockFalso()..error = Exception('permission-denied');
      await _abrir(tester, stock, insumoId: 'p1');

      await _tocar(tester, 'Confirmar salida');

      expect(find.text('No se pudo registrar el consumo'), findsOneWidget);
      expect(find.textContaining('permission-denied'), findsNothing);
      expect(find.text('Etanol'), findsOneWidget);
    });

    testWidgets('un doble toque mientras guarda registra una sola vez',
        (tester) async {
      final stock = _StockFalso()..espera = Completer<void>();
      await _abrir(tester, stock, insumoId: 'p1');

      await tester.tap(find.text('Confirmar salida'));
      await tester.pump();
      await tester.tap(find.text('Confirmar salida'));
      await tester.pump();

      expect(stock.llamadas, hasLength(1));

      stock.espera!.complete();
      await tester.pumpAndSettle();
    });
  });
}
