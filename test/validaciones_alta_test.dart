import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/screens/inventario/insumo_alta_screen.dart';
import 'package:tpfinal_grupo2/screens/inventario/validaciones_alta.dart';

void main() {
  group('otros nombres', () {
    test('separa por coma o punto y coma y limpia los espacios', () {
      expect(
        ValidacionesAlta.otrosNombres(' Fenilmetanol ,Alcohol bencílico; Bencenometanol '),
        ['Fenilmetanol', 'Alcohol bencílico', 'Bencenometanol'],
      );
    });

    test('saca los vacíos y los repetidos (sin distinguir mayúsculas)', () {
      expect(
        ValidacionesAlta.otrosNombres('Etanol,, etanol ,ETANOL, '),
        ['Etanol'],
      );
    });

    test('sin texto no hay otros nombres', () {
      expect(ValidacionesAlta.otrosNombres(null), isEmpty);
      expect(ValidacionesAlta.otrosNombres('  '), isEmpty);
    });
  });

  group('números escritos a mano', () {
    test('la coma y el punto son lo mismo', () {
      expect(ValidacionesAlta.numero('0,5'), 0.5);
      expect(ValidacionesAlta.numero('0.5'), 0.5);
      expect(ValidacionesAlta.numero(' 12 '), 12);
    });

    test('lo que no es un número da null', () {
      expect(ValidacionesAlta.numero('abc'), isNull);
      expect(ValidacionesAlta.numero(''), isNull);
      expect(ValidacionesAlta.numero(null), isNull);
      expect(ValidacionesAlta.numero('1,2,3'), isNull);
    });

    test('un entero no admite decimales', () {
      expect(ValidacionesAlta.entero('5'), 5);
      expect(ValidacionesAlta.entero(' 5 '), 5);
      expect(ValidacionesAlta.entero('5,5'), isNull);
      expect(ValidacionesAlta.entero('cinco'), isNull);
    });
  });

  group('nombre y ubicación', () {
    test('no pueden estar vacíos ni ser solo espacios', () {
      expect(ValidacionesAlta.nombre(''), ValidacionesAlta.avisoNombre);
      expect(ValidacionesAlta.nombre('   '), ValidacionesAlta.avisoNombre);
      expect(ValidacionesAlta.nombre(null), ValidacionesAlta.avisoNombre);
      expect(ValidacionesAlta.nombre('Etanol'), isNull);

      expect(ValidacionesAlta.ubicacion(' '), ValidacionesAlta.avisoUbicacion);
      expect(ValidacionesAlta.ubicacion('Estante 1'), isNull);
    });
  });

  group('cantidad inicial', () {
    test('un entero de 0 en adelante está bien', () {
      expect(ValidacionesAlta.cantidadInicial('0'), isNull);
      expect(ValidacionesAlta.cantidadInicial('25'), isNull);
    });

    test('vacía avisa', () {
      expect(ValidacionesAlta.cantidadInicial(''), ValidacionesAlta.avisoCantidadVacia);
      expect(ValidacionesAlta.cantidadInicial(null), ValidacionesAlta.avisoCantidadVacia);
    });

    test('negativa avisa', () {
      expect(
        ValidacionesAlta.cantidadInicial('-3'),
        ValidacionesAlta.avisoCantidadNegativa,
      );
    });

    test('con decimales o letras avisa que tiene que ser entera', () {
      expect(
        ValidacionesAlta.cantidadInicial('2,5'),
        ValidacionesAlta.avisoCantidadEntera,
      );
      expect(
        ValidacionesAlta.cantidadInicial('abc'),
        ValidacionesAlta.avisoCantidadEntera,
      );
    });
  });

  group('stock mínimo', () {
    test('admite decimales con coma o punto', () {
      expect(ValidacionesAlta.stockMinimo('0,5'), isNull);
      expect(ValidacionesAlta.stockMinimo('2.5'), isNull);
      expect(ValidacionesAlta.stockMinimo('0'), isNull);
    });

    test('vacío, negativo y no numérico avisan', () {
      expect(ValidacionesAlta.stockMinimo(''), ValidacionesAlta.avisoMinimoVacio);
      expect(ValidacionesAlta.stockMinimo('-1'), ValidacionesAlta.avisoMinimoNegativo);
      expect(ValidacionesAlta.stockMinimo('poco'), ValidacionesAlta.avisoMinimoNumero);
    });
  });

  group('peso molecular', () {
    test('es opcional', () {
      expect(ValidacionesAlta.pesoMolecular(''), isNull);
      expect(ValidacionesAlta.pesoMolecular('  '), isNull);
      expect(ValidacionesAlta.pesoMolecular(null), isNull);
    });

    test('con un número positivo está bien, con coma o punto', () {
      expect(ValidacionesAlta.pesoMolecular('46.07'), isNull);
      expect(ValidacionesAlta.pesoMolecular('46,07'), isNull);
    });

    test('con letras o cero o negativo avisa', () {
      expect(ValidacionesAlta.pesoMolecular('abc'), ValidacionesAlta.avisoPesoNumero);
      expect(ValidacionesAlta.pesoMolecular('0'), ValidacionesAlta.avisoPesoPositivo);
      expect(ValidacionesAlta.pesoMolecular('-5'), ValidacionesAlta.avisoPesoPositivo);
    });
  });

  group('fechas', () {
    final enero = DateTime(2026, 1, 10);
    final marzo = DateTime(2026, 3, 10);

    test('el vencimiento posterior a la elaboración está bien', () {
      expect(ValidacionesAlta.fechas(elaboracion: enero, vencimiento: marzo), isNull);
    });

    test('el mismo día está bien', () {
      expect(ValidacionesAlta.fechas(elaboracion: enero, vencimiento: enero), isNull);
    });

    test('un vencimiento anterior a la elaboración avisa', () {
      expect(
        ValidacionesAlta.fechas(elaboracion: marzo, vencimiento: enero),
        ValidacionesAlta.avisoFechas,
      );
    });

    test('si falta una de las dos no hay nada que comparar', () {
      expect(ValidacionesAlta.fechas(elaboracion: enero), isNull);
      expect(ValidacionesAlta.fechas(vencimiento: enero), isNull);
      expect(ValidacionesAlta.fechas(), isNull);
    });
  });

  group('en el formulario del Alta', () {
    Future<void> abrir(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 7000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            insumosProvider.overrideWith((ref) => Stream.value(<Insumo>[])),
          ],
          child: const MaterialApp(home: Scaffold(body: InsumoAltaScreen())),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> escribir(WidgetTester tester, String campo, String texto) =>
        tester.enterText(find.widgetWithText(TextFormField, campo), texto);

    // Completa lo obligatorio, con un valor válido en cada uno.
    Future<void> completarLoObligatorio(WidgetTester tester) async {
      await escribir(tester, 'Nombre', 'Etanol');
      await escribir(tester, 'Ubicación', 'Estante 1');
      await escribir(tester, 'Cantidad inicial', '5');
      await escribir(tester, 'Stock mínimo', '1');
    }

    Future<void> guardar(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pump();
    }

    testWidgets('una cantidad negativa avisa y no guarda', (tester) async {
      await abrir(tester);
      await completarLoObligatorio(tester);
      await escribir(tester, 'Cantidad inicial', '-3');

      await guardar(tester);

      expect(find.text('La cantidad no puede ser negativa'), findsOneWidget);
    });

    testWidgets('una cantidad con decimales avisa que tiene que ser entera',
        (tester) async {
      await abrir(tester);
      await completarLoObligatorio(tester);
      await escribir(tester, 'Cantidad inicial', '2,5');

      await guardar(tester);

      expect(find.text('La cantidad tiene que ser un número entero'), findsOneWidget);
    });

    testWidgets('un stock mínimo negativo avisa', (tester) async {
      await abrir(tester);
      await completarLoObligatorio(tester);
      await escribir(tester, 'Stock mínimo', '-1');

      await guardar(tester);

      expect(find.text('El stock mínimo no puede ser negativo'), findsOneWidget);
    });

    testWidgets('un peso molecular que no es número avisa en vez de romper',
        (tester) async {
      await abrir(tester);
      await completarLoObligatorio(tester);
      await escribir(tester, 'Peso molecular', 'abc');

      await guardar(tester);

      expect(find.text('El peso molecular tiene que ser un número'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin ubicación avisa', (tester) async {
      await abrir(tester);
      await completarLoObligatorio(tester);
      await escribir(tester, 'Ubicación', '');

      await guardar(tester);

      expect(find.text('Ingrese una ubicación'), findsOneWidget);
    });

    testWidgets('el stock mínimo con coma decimal se acepta', (tester) async {
      await abrir(tester);
      await completarLoObligatorio(tester);
      await escribir(tester, 'Stock mínimo', '0,5');
      // Se rompe otra regla a propósito para no llegar a guardar de verdad.
      await escribir(tester, 'Cantidad inicial', '-1');

      await guardar(tester);

      expect(find.text('La cantidad no puede ser negativa'), findsOneWidget);
      expect(find.text('El stock mínimo tiene que ser un número'), findsNothing);
    });
  });
}
