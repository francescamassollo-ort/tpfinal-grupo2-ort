import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/trabajo_practico.dart';
import 'package:tpfinal_grupo2/models/usuario.dart';
import 'package:tpfinal_grupo2/providers/archivo_provider.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/role_provider.dart';
import 'package:tpfinal_grupo2/providers/trabajopractico_provider.dart';
import 'package:tpfinal_grupo2/screens/tp/tp_detalle_screen.dart';
import 'package:tpfinal_grupo2/services/archivo_service.dart';
import 'package:tpfinal_grupo2/services/trabajopractico_service.dart';

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

/// El servicio de TPs sin Firestore: devuelve el TP y dice que del insumo
/// "i1" faltan 3.
class _TpServiceFalso extends Fake implements TpService {
  _TpServiceFalso(this.tp);

  final TrabajoPractico tp;

  @override
  Future<TrabajoPractico?> getById(String id) async => tp;

  @override
  DisponibilidadTP verificarDisponibilidad(
    TrabajoPractico tp,
    Map<String, num> stockPorInsumo,
  ) =>
      DisponibilidadTP(const {'i1': 3});
}

Insumo _insumo(String id, String nombre, String ubicacion, int stock) {
  return Insumo(
    id: id,
    nombre: nombre,
    tipo: InsumoTipo.comprado,
    stock: stock,
    ubicacion: ubicacion,
    umbralMinimo: 2,
  );
}

final _insumos = [
  _insumo('i1', 'Etanol absoluto', 'Heladera 2', 2),
  _insumo('i2', 'Acetona', 'Estante A', 10),
];

const _requeridos = [
  InsumoRequerido(insumoId: 'i1', cantidad: 5, unidad: 'ml'),
  InsumoRequerido(insumoId: 'i2', cantidad: 1, unidad: 'g'),
];

Future<void> _abrir(
  WidgetTester tester, {
  required _ArchivoFalso archivo,
  List<InsumoRequerido> requeridos = _requeridos,
}) async {
  tester.view.physicalSize = const Size(1200, 2700);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final tp = TrabajoPractico(
    id: 'tp1',
    nombre: 'TP Titulaciones',
    descripcion: '',
    fecha: DateTime(2026, 11, 20),
    docente: 'Ana',
    insumos: requeridos,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        roleProvider.overrideWithValue(UserRole.docente),
        tpServiceProvider.overrideWithValue(_TpServiceFalso(tp)),
        insumosProvider.overrideWith((ref) => Stream.value(_insumos)),
        archivoServiceProvider.overrideWithValue(archivo),
      ],
      child: const MaterialApp(home: TpDetalleScreen(tpId: 'tp1')),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Compartir, PDF: comparte un PDF con el nombre del TP y su fecha',
      (tester) async {
    final archivo = _ArchivoFalso();
    await _abrir(tester, archivo: archivo);

    await tester.tap(find.text('Compartir'));
    await tester.pumpAndSettle();
    expect(find.text('Compartir como'), findsOneWidget);

    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();

    expect(archivo.compartidos, hasLength(1));
    expect(archivo.guardados, isEmpty);
    final enviado = archivo.compartidos.single;
    expect(enviado.mimeType, 'application/pdf');
    expect(enviado.nombre, 'tp-tp-titulaciones-2026-11-20.pdf');
    expect(String.fromCharCodes(enviado.bytes.sublist(0, 4)), '%PDF');
  });

  testWidgets('Descargar, Excel: guarda un CSV con ubicación y faltante',
      (tester) async {
    final archivo = _ArchivoFalso();
    await _abrir(tester, archivo: archivo);

    await tester.tap(find.text('Descargar'));
    await tester.pumpAndSettle();
    expect(find.text('Descargar como'), findsOneWidget);
    await tester.tap(find.text('Excel (CSV)'));
    await tester.pumpAndSettle();

    expect(archivo.guardados, hasLength(1));
    expect(archivo.compartidos, isEmpty);
    final guardado = archivo.guardados.single;
    expect(guardado.mimeType, 'text/csv');
    expect(guardado.nombre, 'tp-tp-titulaciones-2026-11-20.csv');
    expect(find.text('Archivo guardado'), findsOneWidget);

    final texto = String.fromCharCodes(guardado.bytes);
    // Ordenado por ubicación: Estante A antes que Heladera 2.
    expect(texto.indexOf('Estante A'), lessThan(texto.indexOf('Heladera 2')));
    expect(texto, contains('Estante A;Acetona;1 g;10;-'));
    expect(texto, contains('Heladera 2;Etanol absoluto;5 ml;2;3'));
    expect(texto, contains('Docente: Ana'));
  });

  testWidgets('cerrar el "Guardar como" sin elegir no avisa nada',
      (tester) async {
    final archivo = _ArchivoFalso(guardaOk: false);
    await _abrir(tester, archivo: archivo);

    await tester.tap(find.text('Descargar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();

    expect(archivo.guardados, hasLength(1));
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('cerrar el selector de formato sin elegir no genera nada',
      (tester) async {
    final archivo = _ArchivoFalso();
    await _abrir(tester, archivo: archivo);

    await tester.tap(find.text('Compartir'));
    await tester.pumpAndSettle();
    // Un punto de la zona oscurecida, arriba del panel.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(archivo.compartidos, isEmpty);
    expect(archivo.guardados, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('sin insumos avisa y no abre el selector ni arma archivo',
      (tester) async {
    final archivo = _ArchivoFalso();
    await _abrir(tester, archivo: archivo, requeridos: const []);

    await tester.tap(find.text('Compartir'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Este trabajo práctico no tiene insumos, no hay nada para exportar',
      ),
      findsOneWidget,
    );
    expect(find.text('Compartir como'), findsNothing);
    expect(archivo.compartidos, isEmpty);
    expect(archivo.guardados, isEmpty);
  });

  testWidgets('si falla al compartir, lo dice', (tester) async {
    final archivo = _ArchivoFalso(falla: true);
    await _abrir(tester, archivo: archivo);

    await tester.tap(find.text('Compartir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo compartir el archivo'), findsOneWidget);
  });

  testWidgets('si falla al guardar, lo dice', (tester) async {
    final archivo = _ArchivoFalso(falla: true);
    await _abrir(tester, archivo: archivo);

    await tester.tap(find.text('Descargar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo guardar el archivo'), findsOneWidget);
  });
}
