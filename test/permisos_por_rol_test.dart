import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/core/app_shell.dart';
import 'package:tpfinal_grupo2/core/app_strings.dart';
import 'package:tpfinal_grupo2/core/permisos.dart';
import 'package:tpfinal_grupo2/models/alerta.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/usuario.dart';
import 'package:tpfinal_grupo2/providers/alerta_provider.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/role_provider.dart';
import 'package:tpfinal_grupo2/screens/inventario/insumo_detalle_screen.dart';
import 'package:tpfinal_grupo2/widgets/solo_con_permiso.dart';

final _insumo = Insumo(
  id: 'i1',
  nombre: 'Etanol absoluto',
  tipo: InsumoTipo.comprado,
  stock: 10,
  ubicacion: 'Estante A',
  umbralMinimo: 2,
);

Override _rol(UserRole rol) =>
    rolDeSesionProvider.overrideWith((ref) => Stream.value(rol));

void main() {
  group('Permisos: qué puede hacer cada rol', () {
    test('dar de alta, editar y dar de baja es solo del administrador', () {
      for (final rol in UserRole.values) {
        final esAdmin = rol == UserRole.administrador;
        expect(Permisos.puedeDarDeAlta(rol), esAdmin, reason: '$rol');
        expect(Permisos.puedeEditarOBaja(rol), esAdmin, reason: '$rol');
      }
    });

    test('registrar consumo es del administrador y del ayudante, no del docente', () {
      expect(Permisos.puedeRegistrarConsumo(UserRole.administrador), isTrue);
      expect(Permisos.puedeRegistrarConsumo(UserRole.ayudante), isTrue);
      expect(Permisos.puedeRegistrarConsumo(UserRole.docente), isFalse);
    });
  });

  group('el botón "+" de Inventario', () {
    Future<void> mostrar(WidgetTester tester, UserRole rol) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            alertasProvider.overrideWithValue(const AsyncData(<Alerta>[])),
            alertasVistasProvider.overrideWith((ref) => Stream.value(<String>{})),
            _rol(rol),
          ],
          child: const MaterialApp(
            home: AppShell(location: '/inventario', child: SizedBox()),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('lo ve el administrador', (tester) async {
      await mostrar(tester, UserRole.administrador);

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('no lo ve el ayudante', (tester) async {
      await mostrar(tester, UserRole.ayudante);

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('no lo ve el docente', (tester) async {
      await mostrar(tester, UserRole.docente);

      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });

  group('el detalle de un insumo', () {
    Future<void> mostrar(WidgetTester tester, UserRole rol) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            insumosProvider.overrideWith((ref) => Stream.value([_insumo])),
            _rol(rol),
          ],
          child: const MaterialApp(
            home: Scaffold(body: InsumoDetalleScreen(insumoId: 'i1')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('el administrador edita, da de baja y registra consumo',
        (tester) async {
      await mostrar(tester, UserRole.administrador);

      expect(find.byTooltip('Editar'), findsOneWidget);
      expect(find.byTooltip('Dar de baja'), findsOneWidget);
      expect(find.text('Registrar consumo'), findsOneWidget);
    });

    testWidgets('el ayudante registra consumo pero no edita ni da de baja',
        (tester) async {
      await mostrar(tester, UserRole.ayudante);

      expect(find.byTooltip('Editar'), findsNothing);
      expect(find.byTooltip('Dar de baja'), findsNothing);
      expect(find.text('Registrar consumo'), findsOneWidget);
    });

    testWidgets('el docente solo mira: ni editar, ni baja, ni consumo',
        (tester) async {
      await mostrar(tester, UserRole.docente);

      expect(find.text('Etanol absoluto'), findsOneWidget);
      expect(find.text('Historial'), findsOneWidget);
      expect(find.byTooltip('Editar'), findsNothing);
      expect(find.byTooltip('Dar de baja'), findsNothing);
      expect(find.text('Registrar consumo'), findsNothing);
    });
  });

  group('SoloConPermiso', () {
    Future<void> mostrar(WidgetTester tester, UserRole rol) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [_rol(rol)],
          child: const MaterialApp(
            home: SoloConPermiso(
              permitido: Permisos.puedeDarDeAlta,
              child: Scaffold(body: Text('Pantalla de alta')),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('con permiso muestra la pantalla', (tester) async {
      await mostrar(tester, UserRole.administrador);

      expect(find.text('Pantalla de alta'), findsOneWidget);
      expect(find.text(AppStrings.sinPermiso), findsNothing);
    });

    testWidgets('sin permiso la reemplaza por un aviso', (tester) async {
      await mostrar(tester, UserRole.ayudante);

      expect(find.text('Pantalla de alta'), findsNothing);
      expect(find.text(AppStrings.sinPermiso), findsOneWidget);
    });
  });
}
