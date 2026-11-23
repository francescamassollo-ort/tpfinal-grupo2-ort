import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/lista_compra.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/lista_compra_provider.dart';
import 'package:tpfinal_grupo2/screens/compras/compras_agregar_dialog.dart';
import 'package:tpfinal_grupo2/screens/compras/compras_screen.dart';
import 'package:tpfinal_grupo2/services/lista_compra_service.dart';
import 'package:tpfinal_grupo2/widgets/insumo_etiquetas.dart';

Insumo _insumo(
  String id,
  String nombre, {
  int stock = 10,
  num umbral = 5,
  String ubicacion = 'Estante A',
}) {
  return Insumo(
    id: id,
    nombre: nombre,
    tipo: InsumoTipo.comprado,
    stock: stock,
    ubicacion: ubicacion,
    umbralMinimo: umbral,
  );
}

ListaCompra _enLista(String productoId) => ListaCompra(
      id: 'item-$productoId',
      productoId: productoId,
      cantidadSugerida: 4,
      cantidadSolicitada: 4,
      generadaEn: DateTime(2026, 11, 1),
    );

/// Reemplazo de las acciones reales: no escribe en Firestore, solo anota qué
/// le pidieron agregar.
class _AccionesFalsas implements ComprasAcciones {
  _AccionesFalsas({this.falla = false});

  final bool falla;
  final agregados = <(String, int)>[];

  @override
  Future<void> agregar(String productoId, int cantidad) async {
    if (falla) throw Exception('sin conexión');
    agregados.add((productoId, cantidad));
  }

  @override
  Future<void> cambiarEstado(String id, EstadoCompra estado) async {}

  @override
  Future<void> incrementar(String id) async {}

  @override
  Future<void> decrementar(String id) async {}

  @override
  Future<int> agregarSugerencias() async => 0;
}

/// Reemplazo del servicio real: anota las escrituras en vez de ir a Firestore.
class _ServicioFalso implements ListaCompraService {
  final agregados = <(String, int)>[];
  final cantidades = <(String, int)>[];

  @override
  Future<String> agregar(String productoId, int cantidadSugerida) async {
    agregados.add((productoId, cantidadSugerida));
    return 'doc-$productoId';
  }

  @override
  Future<void> cambiarCantidad(String id, int cantidad) async {
    cantidades.add((id, cantidad));
  }

  @override
  Stream<List<ListaCompra>> watchPendientes() => const Stream.empty();

  @override
  Future<void> actualizarEstado(String id, EstadoCompra estado) async {}

  @override
  Future<int> importarSugerencias(Iterable<Insumo> insumos) async => 0;
}

void main() {
  group('etiquetas de insumos', () {
    test('un nombre único va solo', () {
      final etiquetas = etiquetasDeInsumos([_insumo('a', 'Etanol')]);

      expect(etiquetas['a'], 'Etanol');
    });

    test('los nombres repetidos suman la ubicación, sin mirar mayúsculas', () {
      final etiquetas = etiquetasDeInsumos([
        _insumo('a', 'Algodon', ubicacion: 'Estante 5'),
        _insumo('b', 'algodon', ubicacion: 'Armario 5'),
        _insumo('c', 'Etanol'),
      ]);

      expect(etiquetas['a'], 'Algodon - Estante 5');
      expect(etiquetas['b'], 'algodon - Armario 5');
      expect(etiquetas['c'], 'Etanol');
    });
  });

  group('el panel', () {
    final insumos = [
      _insumo('z', 'Zinc', stock: 2, umbral: 5),
      _insumo('a', 'Agar LB', stock: 20, umbral: 5),
    ];

    // Abre el panel desde un botón y guarda lo que devuelve.
    Future<NuevoItemCompra?> Function() abrir(
      WidgetTester tester,
      List<Insumo> lista,
    ) {
      NuevoItemCompra? resultado;
      var cerrado = false;
      return () async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    resultado = await showDialog<NuevoItemCompra>(
                      context: context,
                      builder: (_) => ComprasAgregarDialog(insumos: lista),
                    );
                    cerrado = true;
                  },
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('abrir'));
        await tester.pumpAndSettle();
        return cerrado ? resultado : null;
      };
    }

    Future<void> elegir(WidgetTester tester, String nombre) async {
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(nombre).last);
      await tester.pumpAndSettle();
    }

    testWidgets('ofrece los insumos ordenados por nombre', (tester) async {
      await abrir(tester, insumos)();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      final agar = tester.getTopLeft(find.text('Agar LB').last).dy;
      final zinc = tester.getTopLeft(find.text('Zinc').last).dy;
      expect(agar, lessThan(zinc));
    });

    testWidgets('Agregar no se puede tocar hasta elegir un insumo', (tester) async {
      await abrir(tester, insumos)();

      final boton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Agregar'));

      expect(boton.onPressed, isNull);
    });

    testWidgets('al elegir un insumo muestra su stock y propone la cantidad', (tester) async {
      await abrir(tester, insumos)();

      await elegir(tester, 'Zinc');

      // Stock 2, umbral 5: para volver al doble del umbral faltan 8.
      expect(find.text('Stock actual: 2 u.'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('la cantidad se puede subir y no baja de 1', (tester) async {
      await abrir(tester, [_insumo('a', 'Agar LB', stock: 10, umbral: 5)])();
      await elegir(tester, 'Agar LB');
      // Stock 10, umbral 5: no falta nada, y la cantidad mínima es 1.
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byTooltip('Aumentar cantidad'));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.byTooltip('Disminuir cantidad'));
      await tester.tap(find.byTooltip('Disminuir cantidad'));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('Agregar devuelve el insumo y la cantidad elegidos', (tester) async {
      NuevoItemCompra? resultado;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => resultado = await showDialog<NuevoItemCompra>(
                  context: context,
                  builder: (_) => ComprasAgregarDialog(insumos: insumos),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await elegir(tester, 'Zinc');
      await tester.tap(find.byTooltip('Aumentar cantidad'));
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar'));
      await tester.pumpAndSettle();

      expect(resultado, (productoId: 'z', cantidad: 9));
    });

    testWidgets('Cancelar cierra sin devolver nada', (tester) async {
      NuevoItemCompra? resultado = (productoId: 'x', cantidad: 1);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => resultado = await showDialog<NuevoItemCompra>(
                  context: context,
                  builder: (_) => ComprasAgregarDialog(insumos: insumos),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(resultado, isNull);
      expect(find.byType(ComprasAgregarDialog), findsNothing);
    });

    testWidgets('los insumos con el mismo nombre se distinguen por ubicación', (tester) async {
      await abrir(tester, [
        _insumo('a', 'Algodon', ubicacion: 'Estante 5'),
        _insumo('b', 'Algodon', ubicacion: 'Armario 5'),
      ])();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('Algodon - Estante 5'), findsWidgets);
      expect(find.text('Algodon - Armario 5'), findsWidgets);
    });
  });

  group('la pantalla', () {
    Future<void> abrirPantalla(
      WidgetTester tester, {
      required _AccionesFalsas acciones,
      required List<Insumo> insumos,
      List<ListaCompra> enLista = const [],
    }) async {
      // Un celular alto, para que entren la lista, el botón flotante y los
      // botones de abajo sin desbordar.
      tester.view.physicalSize = const Size(1200, 2700);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Sin reemplazar itemsCompraProvider: como en la app, la pantalla
            // escucha los dos streams y los mantiene vivos.
            insumosProvider.overrideWith((ref) => Stream.value(insumos)),
            listaCompraStreamProvider.overrideWith((ref) => Stream.value(enLista)),
            comprasAccionesProvider.overrideWithValue(acciones),
          ],
          child: const MaterialApp(home: ComprasScreen()),
        ),
      );
      // Deja que lleguen los streams.
      await tester.pump();
      await tester.pump();
    }

    testWidgets('el botón + agrega el insumo elegido con su cantidad', (tester) async {
      final acciones = _AccionesFalsas();
      await abrirPantalla(
        tester,
        acciones: acciones,
        insumos: [_insumo('z', 'Zinc', stock: 2, umbral: 5)],
      );

      await tester.tap(find.byTooltip('Agregar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zinc').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar'));
      await tester.pumpAndSettle();

      expect(acciones.agregados, [('z', 8)]);
      expect(find.text('Zinc agregado a la lista'), findsOneWidget);
    });

    testWidgets('no ofrece los insumos que ya están en la lista', (tester) async {
      final acciones = _AccionesFalsas();
      await abrirPantalla(
        tester,
        acciones: acciones,
        insumos: [_insumo('z', 'Zinc'), _insumo('a', 'Agar LB')],
        enLista: [_enLista('z')],
      );

      await tester.tap(find.byTooltip('Agregar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('Agar LB'), findsWidgets);
      // Zinc aparece una sola vez: es la fila que ya está en la lista, no una
      // opción del desplegable.
      expect(find.text('Zinc'), findsOneWidget);
    });

    testWidgets('si ya están todos en la lista, avisa y no abre el panel', (tester) async {
      final acciones = _AccionesFalsas();
      await abrirPantalla(
        tester,
        acciones: acciones,
        insumos: [_insumo('z', 'Zinc')],
        enLista: [_enLista('z')],
      );

      await tester.tap(find.byTooltip('Agregar'));
      await tester.pumpAndSettle();

      expect(find.text('Todos los insumos ya están en la lista'), findsOneWidget);
      expect(find.byType(ComprasAgregarDialog), findsNothing);
    });

    testWidgets('si falla al agregar, lo dice', (tester) async {
      final acciones = _AccionesFalsas(falla: true);
      await abrirPantalla(
        tester,
        acciones: acciones,
        insumos: [_insumo('z', 'Zinc')],
      );

      await tester.tap(find.byTooltip('Agregar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zinc').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo agregar a la lista'), findsOneWidget);
      expect(acciones.agregados, isEmpty);
    });

    testWidgets('cancelar no agrega nada ni avisa', (tester) async {
      final acciones = _AccionesFalsas();
      await abrirPantalla(
        tester,
        acciones: acciones,
        insumos: [_insumo('z', 'Zinc')],
      );

      await tester.tap(find.byTooltip('Agregar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(acciones.agregados, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('la acción agregar', () {
    ProviderContainer contenedor(
      _ServicioFalso servicio,
      List<Insumo> insumos,
    ) {
      final container = ProviderContainer(
        overrides: [
          listaCompraServiceProvider.overrideWithValue(servicio),
          insumosProvider.overrideWith((ref) => Stream.value(insumos)),
        ],
      );
      addTearDown(container.dispose);
      // Como la pantalla real, el test tiene que escuchar el stream: en
      // Riverpod 3 uno que nadie escucha queda pausado.
      container.listen(insumosProvider, (previous, next) {});
      return container;
    }

    test('con la cantidad que propone el sistema, escribe una sola vez', () async {
      final servicio = _ServicioFalso();
      final container = contenedor(servicio, [_insumo('z', 'Zinc', stock: 2, umbral: 5)]);
      await container.read(insumosProvider.future);

      await container.read(comprasAccionesProvider).agregar('z', 8);

      expect(servicio.agregados, [('z', 8)]);
      expect(servicio.cantidades, isEmpty);
    });

    test('con otra cantidad, la sugerida sigue siendo la del sistema', () async {
      final servicio = _ServicioFalso();
      final container = contenedor(servicio, [_insumo('z', 'Zinc', stock: 2, umbral: 5)]);
      await container.read(insumosProvider.future);

      await container.read(comprasAccionesProvider).agregar('z', 20);

      // La sugerida es 8 (la del sistema); lo que se tipeó va como cantidad a
      // comprar.
      expect(servicio.agregados, [('z', 8)]);
      expect(servicio.cantidades, [('doc-z', 20)]);
    });

    test('si no encuentra el insumo, usa la cantidad elegida como sugerida', () async {
      final servicio = _ServicioFalso();
      final container = contenedor(servicio, const []);
      await container.read(insumosProvider.future);

      await container.read(comprasAccionesProvider).agregar('x', 5);

      expect(servicio.agregados, [('x', 5)]);
      expect(servicio.cantidades, isEmpty);
    });
  });
}
