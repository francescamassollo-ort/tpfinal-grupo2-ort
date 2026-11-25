import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/core/app_shell.dart';
import 'package:tpfinal_grupo2/core/app_strings.dart';
import 'package:tpfinal_grupo2/models/alerta.dart';
import 'package:tpfinal_grupo2/models/usuario.dart';
import 'package:tpfinal_grupo2/providers/alerta_provider.dart';
import 'package:tpfinal_grupo2/providers/role_provider.dart';

const double _anchoCelular = 360;
const double _anchoEscritorio = 1200;

// Monta el shell con el ancho de ventana indicado, sin Firebase.
Future<void> _mostrar(
  WidgetTester tester, {
  required double ancho,
  String ruta = '/inventario',
  UserRole rol = UserRole.administrador,
  List<Alerta> alertas = const [],
}) async {
  tester.view.physicalSize = Size(ancho, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        alertasProvider.overrideWithValue(AsyncData(alertas)),
        alertasVistasProvider.overrideWith((ref) => Stream.value(<String>{})),
        // El rol de la persona, sin ir a Firebase.
        rolDeSesionProvider.overrideWith((ref) => Stream.value(rol)),
      ],
      child: MaterialApp(
        home: AppShell(
          location: ruta,
          child: const Center(child: Text('contenido')),
        ),
      ),
    ),
  );
  // Un pump deja que llegue el rol y otro que se redibuje con él.
  await tester.pump();
  await tester.pump();
}

ListTile _destino(WidgetTester tester, String texto) =>
    tester.widget<ListTile>(find.widgetWithText(ListTile, texto));

void main() {
  group('ancho de celular', () {
    testWidgets('usa la barra inferior y el botón de menú', (tester) async {
      await _mostrar(tester, ancho: _anchoCelular);

      expect(find.byType(BottomAppBar), findsOneWidget);
      expect(find.byTooltip(AppStrings.menuAbrir), findsOneWidget);
      expect(find.text('contenido'), findsOneWidget);
    });

    testWidgets('no muestra el panel lateral', (tester) async {
      await _mostrar(tester, ancho: _anchoCelular);

      expect(find.text(AppStrings.menuCerrarSesion), findsNothing);
      expect(find.byType(VerticalDivider), findsNothing);
    });
  });

  group('ancho de escritorio', () {
    testWidgets('usa el panel lateral y no la barra inferior ni el menú',
        (tester) async {
      await _mostrar(tester, ancho: _anchoEscritorio);

      expect(find.byType(BottomAppBar), findsNothing);
      expect(find.byTooltip(AppStrings.menuAbrir), findsNothing);
      expect(find.text(AppStrings.homeTitulo), findsOneWidget);
      expect(find.text(AppStrings.menuInventario), findsOneWidget);
      expect(find.text(AppStrings.menuHistorial), findsOneWidget);
      expect(find.text(AppStrings.menuTps), findsOneWidget);
      expect(find.text(AppStrings.alertasTitulo), findsOneWidget);
      expect(find.text(AppStrings.perfilTitulo), findsOneWidget);
      expect(find.text(AppStrings.menuCerrarSesion), findsOneWidget);
      expect(find.text('contenido'), findsOneWidget);
    });

    testWidgets('muestra el rol de la persona arriba del panel',
        (tester) async {
      await _mostrar(tester, ancho: _anchoEscritorio, rol: UserRole.docente);

      expect(find.text(AppStrings.usuariosRol(UserRole.docente)), findsOneWidget);
    });

    testWidgets('el administrador ve todos los destinos', (tester) async {
      await _mostrar(tester, ancho: _anchoEscritorio);

      expect(find.text(AppStrings.menuCompras), findsOneWidget);
      expect(find.text(AppStrings.menuUsuarios), findsOneWidget);
      expect(find.text(AppStrings.menuImportar), findsOneWidget);
      expect(find.text(AppStrings.insumosDeBajaMenu), findsOneWidget);
    });

    testWidgets('el ayudante ve Compras pero no los destinos de administrador',
        (tester) async {
      await _mostrar(tester, ancho: _anchoEscritorio, rol: UserRole.ayudante);

      expect(find.text(AppStrings.menuCompras), findsOneWidget);
      expect(find.text(AppStrings.menuUsuarios), findsNothing);
      expect(find.text(AppStrings.menuImportar), findsNothing);
      expect(find.text(AppStrings.insumosDeBajaMenu), findsNothing);
    });

    testWidgets('el docente no ve Compras ni los destinos de administrador',
        (tester) async {
      await _mostrar(tester, ancho: _anchoEscritorio, rol: UserRole.docente);

      expect(find.text(AppStrings.menuCompras), findsNothing);
      expect(find.text(AppStrings.menuUsuarios), findsNothing);
    });

    testWidgets('marca como seleccionada la sección actual', (tester) async {
      await _mostrar(tester, ancho: _anchoEscritorio, ruta: '/perfil');

      expect(_destino(tester, AppStrings.perfilTitulo).selected, isTrue);
      expect(_destino(tester, AppStrings.menuInventario).selected, isFalse);
    });

    testWidgets('el detalle de un insumo cuenta como Inventario',
        (tester) async {
      await _mostrar(tester, ancho: _anchoEscritorio, ruta: '/insumo/abc');

      expect(_destino(tester, AppStrings.menuInventario).selected, isTrue);
    });

    testWidgets('el detalle de un TP cuenta como la lista de TPs',
        (tester) async {
      await _mostrar(tester, ancho: _anchoEscritorio, ruta: '/tp/detalle/abc');

      expect(_destino(tester, AppStrings.menuTps).selected, isTrue);
    });

    testWidgets('la campana del panel muestra cuántas alertas hay',
        (tester) async {
      await _mostrar(
        tester,
        ancho: _anchoEscritorio,
        alertas: const [
          Alerta(
            productoId: 'a',
            productoNombre: 'Insumo a',
            tipo: TipoAlerta.stockBajo,
          ),
          Alerta(
            productoId: 'b',
            productoNombre: 'Insumo b',
            tipo: TipoAlerta.sinStock,
          ),
        ],
      );

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('el botón flotante sigue las mismas reglas que en celular',
        (tester) async {
      await _mostrar(tester, ancho: _anchoEscritorio, ruta: '/inventario');
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await _mostrar(tester, ancho: _anchoEscritorio, ruta: '/alertas');
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });

  testWidgets('al agrandar la ventana cambia de barra inferior a panel',
      (tester) async {
    await _mostrar(tester, ancho: _anchoCelular);
    expect(find.byType(BottomAppBar), findsOneWidget);

    tester.view.physicalSize = const Size(_anchoEscritorio, 800);
    await tester.pump();

    expect(find.byType(BottomAppBar), findsNothing);
    expect(find.text(AppStrings.perfilTitulo), findsOneWidget);
  });
}