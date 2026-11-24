import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tpfinal_grupo2/core/app_strings.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/ubicacion.dart';
import 'package:tpfinal_grupo2/providers/archivo_provider.dart';
import 'package:tpfinal_grupo2/providers/importacion_provider.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/ubicacion_providers.dart';
import 'package:tpfinal_grupo2/screens/importar/importar_excel_screen.dart';
import 'package:tpfinal_grupo2/services/archivo_service.dart';
import 'package:tpfinal_grupo2/services/importacion_service.dart';
import 'package:tpfinal_grupo2/services/plan_de_importacion.dart';
import 'package:tpfinal_grupo2/services/plantilla_de_insumos.dart';

/// Un Excel de verdad con la plantilla completada: tres insumos y, si se pide,
/// una fila con un error (sin nombre).
Uint8List _excel({bool conError = false, bool sinPlantilla = false}) {
  final libro = Excel.createExcel();
  libro.delete('Sheet1');
  final hoja = libro['Insumos'];
  if (sinPlantilla) {
    hoja.appendRow([TextCellValue('Cosa'), TextCellValue('Otra cosa')]);
    return Uint8List.fromList(libro.encode()!);
  }
  hoja.appendRow([TextCellValue('Nombre'), TextCellValue('Ubicación'), TextCellValue('Cantidad')]);
  hoja.appendRow([TextCellValue('Etanol absoluto'), TextCellValue('Armario 1'), IntCellValue(5)]);
  hoja.appendRow([TextCellValue('Acetona'), TextCellValue('Armario 1'), IntCellValue(0)]);
  hoja.appendRow([TextCellValue('Glicerina'), TextCellValue('Armario 2'), IntCellValue(2)]);
  if (conError) {
    hoja.appendRow([TextCellValue(''), TextCellValue('Armario 1'), IntCellValue(1)]);
  }
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

/// El guardado de archivos sin abrir nada: anota lo que se le pide guardar.
class _ArchivoFalso extends Fake implements ArchivoService {
  final guardados = <ArchivoGenerado>[];
  bool guardaDeVerdad = true;
  bool falla = false;

  @override
  Future<bool> guardar(ArchivoGenerado archivo) async {
    if (falla) throw Exception('sin permiso');
    guardados.add(archivo);
    return guardaDeVerdad;
  }
}

Future<_ServicioFalso> _abrir(
  WidgetTester tester, {
  _ArchivoFalso? archivoService,
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
        archivoServiceProvider.overrideWithValue(archivoService ?? _ArchivoFalso()),
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
    // "Armario 1" ya está en la lista; "Armario 2" es nueva.
    expect(find.text(AppStrings.importarUbicacionesNuevas(1)), findsOneWidget);
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
          ubicacion: 'Armario 1',
          umbralMinimo: 1,
        ),
      ],
    );

    await _elegir(tester);

    expect(find.text(AppStrings.importarNuevos(2)), findsOneWidget);
    expect(find.text(AppStrings.importarRepetidos(1)), findsOneWidget);
  });

  testWidgets('muestra las filas con errores, que no se cargan, y deja cargar las demás',
      (tester) async {
    await _abrir(tester, archivo: _excel(conError: true));

    await _elegir(tester);

    expect(find.text(AppStrings.importarErrores(1)), findsOneWidget);
    expect(find.text(AppStrings.importarBoton(3)), findsOneWidget);
    await tester.tap(find.text(AppStrings.importarVerErrores));
    await tester.pumpAndSettle();
    expect(find.textContaining('Fila 5: falta el nombre'), findsOneWidget);
  });

  testWidgets('un Excel que no es la plantilla lo dice', (tester) async {
    await _abrir(tester, archivo: _excel(sinPlantilla: true));

    await _elegir(tester);

    expect(find.text(PlantillaDeInsumos.avisoSinHoja), findsOneWidget);
    expect(find.text(AppStrings.importarElegir), findsOneWidget);
  });

  group('descargar la plantilla', () {
    testWidgets('guarda el Excel de la plantilla con las ubicaciones que existen',
        (tester) async {
      final archivo = _ArchivoFalso();
      await _abrir(tester, archivoService: archivo);

      await tester.tap(find.text(AppStrings.importarPlantilla));
      await tester.pumpAndSettle();

      final guardado = archivo.guardados.single;
      expect(guardado.nombre, 'plantilla-de-insumos.xlsx');
      expect(guardado.mimeType, contains('spreadsheetml'));
      expect(find.text(AppStrings.importarPlantillaGuardada), findsOneWidget);
    });

    testWidgets('si se cierra el "Guardar como" no avisa nada', (tester) async {
      final archivo = _ArchivoFalso()..guardaDeVerdad = false;
      await _abrir(tester, archivoService: archivo);

      await tester.tap(find.text(AppStrings.importarPlantilla));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.importarPlantillaGuardada), findsNothing);
      expect(find.text(AppStrings.importarPlantillaError), findsNothing);
    });

    testWidgets('si falla el guardado lo dice', (tester) async {
      final archivo = _ArchivoFalso()..falla = true;
      await _abrir(tester, archivoService: archivo);

      await tester.tap(find.text(AppStrings.importarPlantilla));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.importarPlantillaError), findsOneWidget);
    });
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
