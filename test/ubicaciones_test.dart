import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/core/app_strings.dart';
import 'package:tpfinal_grupo2/models/ubicacion.dart';
import 'package:tpfinal_grupo2/providers/ubicacion_providers.dart';
import 'package:tpfinal_grupo2/screens/inventario/sugerencias_ubicacion.dart';
import 'package:tpfinal_grupo2/services/ubicaciones_logica.dart';

const _lista = [
  'Armario 1',
  'Armario 2',
  'Heladera Pañol',
  'Laboratorio 404 - Armario 1',
];

void main() {
  group('UbicacionesLogica', () {
    test('el id no depende de mayúsculas, tildes, espacios ni signos', () {
      final ids = {
        for (final n in ['Armario N°1', 'armario n° 1', ' ARMARIO  N1 '])
          UbicacionesLogica.idDe(n),
      };
      expect(ids, hasLength(1));
      expect(
        UbicacionesLogica.idDe('Heladera Pañol'),
        UbicacionesLogica.idDe('heladera panol'),
      );
    });

    test('limpia los espacios de más', () {
      expect(UbicacionesLogica.limpiar('  Armario   1 '), 'Armario 1');
    });

    test('si ya existe usa la escritura de la lista', () {
      expect(UbicacionesLogica.canonica('armario 1 ', _lista), 'Armario 1');
      expect(
        UbicacionesLogica.canonica('HELADERA PANOL', _lista),
        'Heladera Pañol',
      );
    });

    test('si es nueva la deja limpia', () {
      expect(UbicacionesLogica.canonica('  Armario  3 ', _lista), 'Armario 3');
    });

    test('existe distingue lo que está y lo que no', () {
      expect(UbicacionesLogica.existe('armario 2', _lista), isTrue);
      expect(UbicacionesLogica.existe('Armario 3', _lista), isFalse);
      expect(UbicacionesLogica.existe('  ', _lista), isFalse);
    });

    test('ofrece las parecidas: un error de tipeo o un texto que está contenido', () {
      expect(UbicacionesLogica.parecidas('Armrio 1', _lista), contains('Armario 1'));
      expect(UbicacionesLogica.parecidas('Helader', _lista), ['Heladera Pañol']);
    });

    test('un número distinto es otro lugar: no se ofrece', () {
      expect(UbicacionesLogica.parecidas('Armario 3', _lista), isNot(contains('Armario 1')));
      expect(UbicacionesLogica.parecidas('Armario 3', _lista), isNot(contains('Armario 2')));
    });

    test('con muy poco texto no sugiere nada', () {
      expect(UbicacionesLogica.parecidas('A', _lista), isEmpty);
      expect(UbicacionesLogica.parecidas('', _lista), isEmpty);
    });

    test('las que empiezan igual van primero y son como mucho 3', () {
      final r = UbicacionesLogica.parecidas(
        'Armario',
        [..._lista, 'Armario 3', 'Armario 4'],
      );
      expect(r, hasLength(3));
      expect(r.first, startsWith('Armario'));
    });
  });

  group('SugerenciasUbicacion', () {
    Future<TextEditingController> mostrar(
      WidgetTester tester, {
      List<String>? ubicaciones = _lista,
      String texto = '',
    }) async {
      final controller = TextEditingController(text: texto);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ubicacionesProvider.overrideWith(
              (ref) => ubicaciones == null
                  ? const Stream<List<Ubicacion>>.empty()
                  : Stream.value([
                      for (final n in ubicaciones)
                        Ubicacion(id: UbicacionesLogica.idDe(n), nombre: n),
                    ]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: SugerenciasUbicacion(controller: controller)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return controller;
    }

    testWidgets('sin texto no dice nada', (tester) async {
      await mostrar(tester);

      expect(find.text(AppStrings.ubicacionNueva), findsNothing);
      expect(find.text(AppStrings.ubicacionExistente), findsNothing);
    });

    testWidgets('confirma una ubicación que ya está, aunque se escriba distinto',
        (tester) async {
      await mostrar(tester, texto: ' armario 1');

      expect(find.text(AppStrings.ubicacionExistente), findsOneWidget);
      expect(find.text(AppStrings.ubicacionNueva), findsNothing);
    });

    testWidgets('avisa que una ubicación nueva se va a agregar', (tester) async {
      await mostrar(tester, texto: 'Armario 9');

      expect(find.text(AppStrings.ubicacionNueva), findsOneWidget);
      expect(find.byType(ActionChip), findsNothing);
    });

    testWidgets('ofrece las parecidas y al tocar una reemplaza lo escrito',
        (tester) async {
      final controller = await mostrar(tester, texto: 'Helader');

      expect(find.text(AppStrings.ubicacionQuisisteDecir), findsOneWidget);
      await tester.tap(find.widgetWithText(ActionChip, 'Heladera Pañol'));
      await tester.pump();

      expect(controller.text, 'Heladera Pañol');
      expect(find.text(AppStrings.ubicacionExistente), findsOneWidget);
    });

    testWidgets('mientras no se sabe qué ubicaciones hay, no afirma nada',
        (tester) async {
      await mostrar(tester, ubicaciones: null, texto: 'Armario 1');

      expect(find.text(AppStrings.ubicacionNueva), findsNothing);
      expect(find.text(AppStrings.ubicacionExistente), findsNothing);
    });
  });
}
