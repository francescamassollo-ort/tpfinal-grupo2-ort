import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/providers/archivo_provider.dart';
import 'package:tpfinal_grupo2/providers/lista_compra_provider.dart';
import 'package:tpfinal_grupo2/screens/compras/compras_screen.dart';
import 'package:tpfinal_grupo2/screens/compras/item_compra.dart';
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

const _items = [
  ItemCompra(id: '1', nombre: 'Guantes de nitrilo', stock: 3, cantidadSolicitada: 8),
  ItemCompra(id: '2', nombre: 'Agar LB', stock: 0, cantidadSolicitada: 5),
];

Future<void> _abrirPantalla(
  WidgetTester tester, {
  required _ArchivoFalso archivo,
  AsyncValue<List<ItemCompra>> items = const AsyncData(_items),
}) async {
  // Un celular alto, para que entren la lista, el botón flotante y los
  // botones de abajo sin desbordar.
  tester.view.physicalSize = const Size(1200, 2700);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        itemsCompraProvider.overrideWith((ref) => items),
        archivoServiceProvider.overrideWithValue(archivo),
      ],
      child: const MaterialApp(home: ComprasScreen()),
    ),
  );
  await tester.pump();
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
    expect(enviado.nombre, matches(r'^lista-de-compras-\d{4}-\d{2}-\d{2}\.pdf$'));
    // Todo PDF válido empieza con "%PDF".
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

  testWidgets('el archivo lleva los ítems que muestra la pantalla', (tester) async {
    final archivo = _ArchivoFalso();
    await _abrirPantalla(tester, archivo: archivo);

    await tester.tap(find.text('Descargar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excel (CSV)'));
    await tester.pumpAndSettle();

    final texto = String.fromCharCodes(archivo.guardados.single.bytes);
    expect(texto, contains('Guantes de nitrilo;3;8'));
    expect(texto, contains('Agar LB;0;5'));
  });

  testWidgets('cerrar el "Guardar como" sin elegir no avisa nada', (tester) async {
    final archivo = _ArchivoFalso(guardaOk: false);
    await _abrirPantalla(tester, archivo: archivo);

    await tester.tap(find.text('Descargar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();

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

  testWidgets('con la lista vacía avisa y no abre el selector', (tester) async {
    final archivo = _ArchivoFalso();
    await _abrirPantalla(
      tester,
      archivo: archivo,
      items: const AsyncData(<ItemCompra>[]),
    );

    await tester.tap(find.text('Compartir'));
    await tester.pumpAndSettle();

    expect(find.text('La lista está vacía, no hay nada para exportar'), findsOneWidget);
    expect(find.text('Compartir como'), findsNothing);
    expect(archivo.compartidos, isEmpty);
  });

  testWidgets('si falla al compartir, lo dice', (tester) async {
    final archivo = _ArchivoFalso(falla: true);
    await _abrirPantalla(tester, archivo: archivo);

    await tester.tap(find.text('Compartir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo compartir el archivo'), findsOneWidget);
  });

  testWidgets('si falla al guardar, lo dice', (tester) async {
    final archivo = _ArchivoFalso(falla: true);
    await _abrirPantalla(tester, archivo: archivo);

    await tester.tap(find.text('Descargar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo guardar el archivo'), findsOneWidget);
  });

  testWidgets('mientras la lista carga, los botones no hacen nada', (tester) async {
    final archivo = _ArchivoFalso();
    await _abrirPantalla(
      tester,
      archivo: archivo,
      items: const AsyncLoading<List<ItemCompra>>(),
    );

    await tester.tap(find.text('Compartir'));
    await tester.pump();

    expect(find.text('Compartir como'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });
}
