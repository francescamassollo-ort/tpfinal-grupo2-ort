import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/trabajo_practico.dart';
import 'package:tpfinal_grupo2/models/usuario.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/role_provider.dart';
import 'package:tpfinal_grupo2/providers/trabajopractico_provider.dart';
import 'package:tpfinal_grupo2/screens/tp/tp_detalle_screen.dart';
import 'package:tpfinal_grupo2/services/trabajopractico_service.dart';

Insumo _insumo(String id, String nombre, String ubicacion) => Insumo(
      id: id,
      nombre: nombre,
      tipo: InsumoTipo.comprado,
      stock: 10,
      ubicacion: ubicacion,
      umbralMinimo: 2,
    );

/// El servicio de TPs sin Firestore: devuelve el TP y dice que alcanza todo.
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
      DisponibilidadTP(const {});
}

Future<void> _abrir(
  WidgetTester tester, {
  required List<InsumoRequerido> requeridos,
  required List<Insumo> insumos,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
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
        insumosProvider.overrideWith((ref) => Stream.value(insumos)),
      ],
      child: const MaterialApp(home: TpDetalleScreen(tpId: 'tp1')),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el detalle muestra la ubicación de cada insumo requerido',
      (tester) async {
    await _abrir(
      tester,
      requeridos: const [
        InsumoRequerido(insumoId: 'i1', cantidad: 2, unidad: 'ml'),
        InsumoRequerido(insumoId: 'i2', cantidad: 1, unidad: 'g'),
      ],
      insumos: [
        _insumo('i1', 'Etanol absoluto', 'Estante A'),
        _insumo('i2', 'Acetona', 'Heladera 2'),
      ],
    );

    expect(find.text('Etanol absoluto'), findsOneWidget);
    expect(find.text('Estante A'), findsOneWidget);
    expect(find.text('Acetona'), findsOneWidget);
    expect(find.text('Heladera 2'), findsOneWidget);
  });

  testWidgets('si el insumo no se encuentra no muestra ubicación',
      (tester) async {
    await _abrir(
      tester,
      requeridos: const [
        InsumoRequerido(insumoId: 'i1', cantidad: 2, unidad: 'ml'),
        InsumoRequerido(insumoId: 'borrado', cantidad: 1, unidad: 'g'),
      ],
      insumos: [_insumo('i1', 'Etanol absoluto', 'Estante A')],
    );

    expect(find.text('Estante A'), findsOneWidget);
    expect(find.text('Insumo no encontrado'), findsOneWidget);
    // Antes aparecía un "-" donde iría la ubicación.
    expect(find.text('-'), findsNothing);
  });
}
