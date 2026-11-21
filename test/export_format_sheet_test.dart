import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/widgets/export_format_sheet.dart';

/// Pantalla de prueba con un botón que abre el selector y guarda lo que
/// devuelve.
class _Pantalla extends StatefulWidget {
  const _Pantalla();

  @override
  State<_Pantalla> createState() => _PantallaState();
}

class _PantallaState extends State<_Pantalla> {
  FormatoExportacion? elegido;
  bool volvio = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () async {
            final resultado = await elegirFormatoExportacion(
              context,
              titulo: 'Compartir como',
            );
            setState(() {
              elegido = resultado;
              volvio = true;
            });
          },
          child: const Text('Abrir'),
        ),
      ),
    );
  }
}

Future<_PantallaState> _abrirSelector(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: _Pantalla()));
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
  return tester.state<_PantallaState>(find.byType(_Pantalla));
}

void main() {
  testWidgets('muestra el título y las dos opciones', (tester) async {
    await _abrirSelector(tester);

    expect(find.text('Compartir como'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('Excel (CSV)'), findsOneWidget);
  });

  testWidgets('elegir PDF devuelve pdf y cierra el panel', (tester) async {
    final pantalla = await _abrirSelector(tester);

    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();

    expect(pantalla.elegido, FormatoExportacion.pdf);
    expect(find.text('Excel (CSV)'), findsNothing);
  });

  testWidgets('elegir Excel devuelve csv', (tester) async {
    final pantalla = await _abrirSelector(tester);

    await tester.tap(find.text('Excel (CSV)'));
    await tester.pumpAndSettle();

    expect(pantalla.elegido, FormatoExportacion.csv);
  });

  testWidgets('toda la opción responde, no solo el texto', (tester) async {
    final pantalla = await _abrirSelector(tester);

    // Un punto de la tarjeta de PDF lejos del texto: cerca del borde izquierdo.
    final tarjeta = find.ancestor(
      of: find.text('PDF'),
      matching: find.byType(InkWell),
    );
    await tester.tapAt(tester.getTopLeft(tarjeta) + const Offset(6, 6));
    await tester.pumpAndSettle();

    expect(pantalla.elegido, FormatoExportacion.pdf);
  });

  testWidgets('cerrar tocando afuera devuelve null', (tester) async {
    final pantalla = await _abrirSelector(tester);

    // Un punto de la zona oscurecida, arriba del panel.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(pantalla.volvio, isTrue);
    expect(pantalla.elegido, isNull);
  });
}
