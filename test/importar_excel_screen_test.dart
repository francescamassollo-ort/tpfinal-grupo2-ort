import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tpfinal_grupo2/core/app_strings.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/ubicacion.dart';
import 'package:tpfinal_grupo2/providers/importacion_provider.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/ubicacion_providers.dart';
import 'package:tpfinal_grupo2/screens/importar/importar_excel_screen.dart';
import 'package:tpfinal_grupo2/services/importacion_service.dart';
import 'package:tpfinal_grupo2/services/plan_de_importacion.dart';

/// Un Excel de verdad con una hoja "Heladera" de tres filas.
Uint8List _excel({bool conAviso = false}) {
  final libro = Excel.createExcel();
  libro.delete('Sheet1');
  final hoja = libro['Heladera'];
  hoja.appendRow([TextCellValue('Estante 1')]);
  hoja.appendRow([TextCellValue('Etanol absoluto'), IntCellValue(5)]);
  hoja.appendRow([TextCellValue('Acetona'), TextCellValue('NO HAY')]);
  hoja.appendRow([TextCellValue('Glicerina'), IntCellValue(2)]);
  if (conAviso) hoja.appendRow([TextCellValue('Cerebro'), TextCellValue('Muchas')]);
  return Uint8List.fromList(libro.encode()!);
}

class _ServicioFalso extends Fake implements ImportacionService {
  PlanDeImportacion? recibido;
  bool falla = false;

  @override
  Future<int> importar(
    PlanDeImportacion plan, {
    void Function(int cargados, int total)? alAvanzar,
  }) async {
    if (falla) throw Exception('sin conexión');
    recibido = plan;
    alAvanzar?.call(plan.nuevos.length, plan.nuevos.length);
    return plan.nuevos.length;
  }
}

Future<_ServicioFalso> _abrir(
  WidgetTester tester, {
  Uint8List? archivo,
  List<Insumo>? existentes,
  _ServicioFalso? servicio,
  bool cargado = true,
}) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final fake = servicio ?? _ServicioFalso();
  final router = GoRouter(
    initialLocation: '/importar',
    routes: [
      GoRoute(path: '/importar', builder: (c, s) => const Scaffold(body: ImportarExcelScreen())),
      GoRoute(path: '/inventario', builder: (c, s) => const Scaffold(body: Text('PANTALLA INVENTARIO'))),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        importacionServiceProvider.overrideWithValue(fake),
        selectorDeExcelProvider.overrideWithValue(() async => archivo),
        insumosProvider.overrideWith(
          (ref) => cargado ? Stream.value(existentes ?? const <Insumo>[]) : const Stream<List<Insumo>>.empty(),
        ),
        ubicacionesProvider.overrideWith(
          (ref) => cargado
              ? Stream.value(const <Ubicacion>[Ubicacion(id: 'armario1', nombre: 'Armario 1')])
              : const Stream<List<Ubicacion>>.empty(),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return fake;
}

Future<void> _elegir(WidgetTester tester) async {
  await tester.tap(find.text(AppStrings.importarElegir));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('al entrar explica y ofrece elegir el archivo', (tester) async {
    await _abrir(tester);

    expect(find.text(AppStrings.importarTitulo), findsOneWidget);
    expect(find.text(AppStrings.importarExplicacion), findsOneWidget);
    expect(find.text(AppStrings.importarElegir), findsOneWidget);
  });

  testWidgets('antes de guardar muestra qué se va a cargar', (tester) async {
    await _abrir(tester, archivo: _excel());

    await _elegir(tester);

    expect(find.text(AppStrings.importarNuevos(3)), findsOneWidget);
    expect(find.text(AppStrings.importarSinStock(1)), findsOneWidget);
    // La hoja tiene "Estante 1": la ubicación nueva es Heladera - Estante 1.
    expect(find.text(AppStrings.importarUbicacionesNuevas(1)), findsOneWidget);
    expect(find.text(AppStrings.importarHojas(1)), findsOneWidget);
    expect(find.text(AppStrings.importarBoton(3)), findsOneWidget);
  });

  testWidgets('los que ya están cargados se saltan y se cuentan', (tester) async {
    await _abrir(
      tester,
      archivo: _excel(),
      existentes: [
        Insumo(
          id: 'i1',
          nombre: 'Acetona',
          tipo: InsumoTipo.comprado,
          stock: 1,
          ubicacion: 'Heladera - Estante 1',
          umbralMinimo: 1,
        ),
      ],
    );

    await _elegir(tester);

    expect(find.text(AppStrings.importarNuevos(2)), findsOneWidget);
    expect(find.text(AppStrings.importarRepetidos(1)), findsOneWidget);
  });

  testWidgets('muestra los avisos de lo que no se entendió', (tester) async {
    await _abrir(tester, archivo: _excel(conAviso: true));

    await _elegir(tester);

    expect(find.textContaining('aviso'), findsWidgets);
    expect(find.text(AppStrings.importarAvisosAyuda), findsOneWidget);
  });

  testWidgets('confirmar guarda el plan y dice cuántos se cargaron', (tester) async {
    final servicio = await _abrir(tester, archivo: _excel());
    await _elegir(tester);

    await tester.tap(find.text(AppStrings.importarBoton(3)));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.importarConfirmarTitulo), findsOneWidget);
    expect(servicio.recibido, isNull);

    await tester.tap(find.widgetWithText(TextButton, AppStrings.importarConfirmar));
    await tester.pumpAndSettle();

    expect(servicio.recibido!.nuevos, hasLength(3));
    expect(find.text(AppStrings.importarListo(3)), findsOneWidget);

    await tester.tap(find.text(AppStrings.importarIrAlInventario));
    await tester.pumpAndSettle();
    expect(find.text('PANTALLA INVENTARIO'), findsOneWidget);
  });

  testWidgets('cancelar la confirmación no guarda nada', (tester) async {
    final servicio = await _abrir(tester, archivo: _excel());
    await _elegir(tester);

    await tester.tap(find.text(AppStrings.importarBoton(3)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, AppStrings.cancelar));
    await tester.pumpAndSettle();

    expect(servicio.recibido, isNull);
    expect(find.text(AppStrings.importarBoton(3)), findsOneWidget);
  });

  testWidgets('si no se elige ningún archivo no pasa nada', (tester) async {
    await _abrir(tester, archivo: null);

    await _elegir(tester);

    expect(find.text(AppStrings.importarElegir), findsOneWidget);
  });

  testWidgets('un archivo que no es un Excel lo dice y deja reintentar', (tester) async {
    await _abrir(tester, archivo: Uint8List.fromList([1, 2, 3]));

    await _elegir(tester);

    expect(find.text(AppStrings.importarArchivoInvalido), findsOneWidget);
    expect(find.text(AppStrings.importarElegir), findsOneWidget);
  });

  testWidgets('si falla al guardar lo dice y vuelve al principio', (tester) async {
    final servicio = _ServicioFalso()..falla = true;
    await _abrir(tester, archivo: _excel(), servicio: servicio);
    await _elegir(tester);

    await tester.tap(find.text(AppStrings.importarBoton(3)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, AppStrings.importarConfirmar));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.importarError), findsOneWidget);
    expect(find.text(AppStrings.importarElegir), findsOneWidget);
  });

  testWidgets('mientras no cargaron los insumos pide esperar', (tester) async {
    await _abrir(tester, archivo: _excel(), cargado: false);

    await tester.tap(find.text(AppStrings.importarElegir));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.importarCargandoDatos), findsOneWidget);
  });
}
