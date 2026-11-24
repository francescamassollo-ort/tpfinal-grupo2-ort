import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/movimiento_stock.dart';
import 'package:tpfinal_grupo2/providers/archivo_provider.dart';
import 'package:tpfinal_grupo2/providers/historial_provider.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/screens/historial/historial_screen.dart';
import 'package:tpfinal_grupo2/services/archivo_service.dart';

/// Reemplazo del servicio real: no abre ningún menú del sistema, solo anota
/// qué archivo le pidieron compartir o guardar.
class _ArchivoFalso implements ArchivoService {
  _ArchivoFalso({this.guardaOk = true, this.falla = false});

  /// Lo que devuelve guardar: false simula cerrar el "Guardar como".
  final bool guardaOk;
  final bool falla;

  final compartidos = <ArchivoGenerado>[];
  final guardados = <ArchivoGenerado>[];

  @override
  Future<void> compartir(ArchivoGenerado archivo) async {
    if (falla) throw Exception('falló');
    compartidos.add(archivo);
  }

  @override
  Future<bool> guardar(ArchivoGenerado archivo) async {
    if (falla) throw Exception('falló');
    guardados.add(archivo);
    return guardaOk;
  }
}

Insumo _insumo(String id, String nombre, {String ubicacion = 'Estante 1'}) =>
    Insumo(
      id: id,
      nombre: nombre,
      tipo: InsumoTipo.comprado,
      stock: 10,
      ubicacion: ubicacion,
      umbralMinimo: 2,
    );

MovimientoStock _mov(String id, String producto, TipoMovimiento tipo) {
  return MovimientoStock(
    id: id,
    productoId: producto,
    usuarioId: 'u1',
    usuarioNombre: 'Juan Perez',
    tipo: tipo,
    cantidad: 5,
    fecha: DateTime.now().subtract(const Duration(hours: 1)),
  );
}

final _movimientos = [
  _mov('a', 'p1', TipoMovimiento.entrada),
  _mov('b', 'p2', TipoMovimiento.salida),
  _mov('c', 'p1', TipoMovimiento.salida),
];

Future<void> _abrirPantalla(
  WidgetTester tester, {
  required _ArchivoFalso archivo,
  Stream<List<MovimientoStock>>? movimientos,
  List<Insumo>? insumos,
}) async {
  // Un celular alto, para que entren la lista y los botones de abajo sin
  // desbordar.
  tester.view.physicalSize = const Size(1200, 2700);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        movimientosStockProvider.overrideWith(
          (ref) => movimientos ?? Stream.value(_movimientos),
        ),
        insumosConBajasProvider.overrideWith(
          (ref) => Stream.value(
            insumos ?? [_insumo('p1', 'Etanol'), _insumo('p2', 'Pipetas')],
          ),
        ),
        archivoServiceProvider.overrideWithValue(archivo),
      ],
      child: const MaterialApp(home: HistorialScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _exportar(WidgetTester tester, String boton, String formato) async {
  await tester.tap(find.text(boton));
  await tester.pumpAndSettle();
  await tester.tap(find.text(formato));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Compartir, PDF: comparte un PDF con el nombre del día', (tester) async {
    final archivo = _ArchivoFalso();
    await _abrirPantalla(tester, archivo: archivo);

    await tester.tap(find.text('Compartir'));
    await tester.pumpAndSettle();
    expect(find.text('Compartir como'), findsOneWidget);
    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();

    expect(archivo.compartidos, hasLength(1));
    expect(archivo.guardados, isEmpty);
    final enviado = archivo.compartidos.single;
    expect(enviado.mimeType, 'application/pdf');
    expect(
      enviado.nombre,
      matches(r'^historial-de-movimientos-\d{4}-\d{2}-\d{2}\.pdf$'),
    );
    expect(String.fromCharCodes(enviado.bytes.sublist(0, 4)), '%PDF');
  });

  testWidgets('Descargar, Excel: guarda un CSV y avisa que se guardó', (tester) async {
    final archivo = _ArchivoFalso();
    await _abrirPantalla(tester, archivo: archivo);

    await tester.tap(find.text('Descargar'));
    await tester.pumpAndSettle();
    expect(find.text('Descargar como'), findsOneWidget);
    await tester.tap(find.text('Excel (CSV)'));
    await tester.pumpAndSettle();

    expect(archivo.guardados, hasLength(1));
    expect(archivo.compartidos, isEmpty);
    final guardado = archivo.guardados.single;
    expect(guardado.mimeType, 'text/csv');
    expect(guardado.nombre, endsWith('.csv'));
    expect(guardado.bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
    expect(find.text('Archivo guardado'), findsOneWidget);
  });

  testWidgets('el archivo lleva los movimientos con el nombre del insumo', (tester) async {
    final archivo = _ArchivoFalso();
    await _abrirPantalla(tester, archivo: archivo);

    await _exportar(tester, 'Descargar', 'Excel (CSV)');

    final texto = String.fromCharCodes(archivo.guardados.single.bytes);
    expect(texto, contains(';Etanol;Entrada;5;Juan Perez;'));
    expect(texto, contains(';Pipetas;Salida;-5;Juan Perez;'));
    expect(texto, isNot(contains('Con filtros aplicados')));
    // Tres movimientos: título, fecha, línea en blanco, encabezado y tres filas.
    expect(texto.trimRight().split('\r\n'), hasLength(7));
  });

  testWidgets('con un filtro puesto exporta solo lo que se ve y lo aclara', (tester) async {
    final archivo = _ArchivoFalso();
    await _abrirPantalla(tester, archivo: archivo);
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(InputDecorator, 'Tipo de movimiento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salida').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filtrar'));
    await tester.pumpAndSettle();

    await _exportar(tester, 'Descargar', 'Excel (CSV)');

    final texto = String.fromCharCodes(archivo.guardados.single.bytes);
    expect(texto, contains('Con filtros aplicados'));
    expect(texto, contains(';Salida;'));
    expect(texto, isNot(contains(';Entrada;')));
    // Dos salidas: título, fecha, aviso, línea en blanco, encabezado y dos filas.
    expect(texto.trimRight().split('\r\n'), hasLength(7));
  });

  testWidgets('los insumos con el mismo nombre se distinguen por ubicación', (tester) async {
    final archivo = _ArchivoFalso();
    await _abrirPantalla(
      tester,
      archivo: archivo,
      insumos: [
        _insumo('p1', 'Algodon', ubicacion: 'Estante 5'),
        _insumo('p2', 'Algodon', ubicacion: 'Armario 5'),
      ],
    );

    await _exportar(tester, 'Descargar', 'Excel (CSV)');

    final texto = String.fromCharCodes(archivo.guardados.single.bytes);
    expect(texto, contains(';Algodon - Estante 5;'));
    expect(texto, contains(';Algodon - Armario 5;'));
  });

  testWidgets('sin movimientos avisa y no abre el selector', (tester) async {
    final archivo = _ArchivoFalso();
    await _abrirPantalla(
      tester,
      archivo: archivo,
      movimientos: Stream.value(const []),
    );

    await tester.tap(find.text('Compartir'));
    await tester.pumpAndSettle();

    expect(find.text('No hay movimientos para exportar'), findsOneWidget);
    expect(find.text('Compartir como'), findsNothing);
    expect(archivo.compartidos, isEmpty);
  });

  testWidgets('cerrar el "Guardar como" sin elegir no avisa nada', (tester) async {
    final archivo = _ArchivoFalso(guardaOk: false);
    await _abrirPantalla(tester, archivo: archivo);

    await _exportar(tester, 'Descargar', 'PDF');

    expect(archivo.guardados, hasLength(1));
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('cerrar el selector de formato sin elegir no genera nada', (tester) async {
    final archivo = _ArchivoFalso();
    await _abrirPantalla(tester, archivo: archivo);

    await tester.tap(find.text('Compartir'));
    await tester.pumpAndSettle();
    // Un punto de la zona oscurecida, arriba del panel.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(archivo.compartidos, isEmpty);
    expect(archivo.guardados, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('si falla al compartir, lo dice', (tester) async {
    final archivo = _ArchivoFalso(falla: true);
    await _abrirPantalla(tester, archivo: archivo);

    await _exportar(tester, 'Compartir', 'PDF');

    expect(find.text('No se pudo compartir el archivo'), findsOneWidget);
  });

  testWidgets('si falla al guardar, lo dice', (tester) async {
    final archivo = _ArchivoFalso(falla: true);
    await _abrirPantalla(tester, archivo: archivo);

    await _exportar(tester, 'Descargar', 'PDF');

    expect(find.text('No se pudo guardar el archivo'), findsOneWidget);
  });

  testWidgets('mientras el historial carga, los botones no hacen nada', (tester) async {
    final sinTerminar = StreamController<List<MovimientoStock>>();
    addTearDown(sinTerminar.close);
    final archivo = _ArchivoFalso();
    tester.view.physicalSize = const Size(1200, 2700);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          movimientosStockProvider.overrideWith((ref) => sinTerminar.stream),
          insumosConBajasProvider.overrideWith((ref) => Stream.value(const [])),
          archivoServiceProvider.overrideWithValue(archivo),
        ],
        child: const MaterialApp(home: HistorialScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Compartir'));
    await tester.pump();

    expect(find.text('Compartir como'), findsNothing);
    expect(archivo.compartidos, isEmpty);
  });
}
