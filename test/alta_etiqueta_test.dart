import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/ocr_provider.dart';
import 'package:tpfinal_grupo2/screens/inventario/insumo_alta_screen.dart';
import 'package:tpfinal_grupo2/services/ocr_service.dart';

const _textoDeEtiqueta = '''
ETANOL ABSOLUTO
Marca: Cicarelli
Fórmula: C2H6O
PM 46,07 g/mol
Venc: 11/2027
''';

class _LectorFalso implements LectorDeTexto {
  _LectorFalso(this.texto);

  String texto;
  bool falla = false;
  Completer<void>? espera;
  final rutas = <String>[];

  @override
  Future<String> leer(String rutaImagen) async {
    rutas.add(rutaImagen);
    if (espera != null) await espera!.future;
    if (falla) throw Exception('el reconocedor se cayó');
    return texto;
  }
}

class _Caso {
  _Caso(String texto) : lector = _LectorFalso(texto);

  final _LectorFalso lector;

  /// Qué devuelve la cámara: una ruta, null (se canceló) o una excepción.
  String? foto = '/tmp/etiqueta.jpg';
  Object? errorDeCamara;
  int fotosSacadas = 0;
}

Future<void> _abrir(WidgetTester tester, _Caso caso) async {
  tester.view.physicalSize = const Size(1080, 7000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        insumosProvider.overrideWith((ref) => Stream.value(<Insumo>[])),
        capturadorDeFotoProvider.overrideWithValue(() async {
          caso.fotosSacadas++;
          if (caso.errorDeCamara != null) throw caso.errorDeCamara!;
          return caso.foto;
        }),
        ocrServiceProvider.overrideWithValue(
          OcrService(lector: caso.lector, buscarQuimica: (_) async => null),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: InsumoAltaScreen())),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _leer(WidgetTester tester) async {
  await tester.tap(find.text('Leer etiqueta con la cámara'));
  await tester.pumpAndSettle();
}

Future<void> _escribir(WidgetTester tester, String campo, String texto) =>
    tester.enterText(find.widgetWithText(TextFormField, campo), texto);

String _valorDe(WidgetTester tester, String campo) =>
    tester
        .widget<TextFormField>(find.widgetWithText(TextFormField, campo))
        .controller!
        .text;

void main() {
  testWidgets('el Alta ofrece el botón de leer la etiqueta', (tester) async {
    await _abrir(tester, _Caso(_textoDeEtiqueta));

    expect(find.text('Leer etiqueta con la cámara'), findsOneWidget);
  });

  testWidgets('con una foto buena completa el formulario y avisa que se revise',
      (tester) async {
    final caso = _Caso(_textoDeEtiqueta);
    await _abrir(tester, caso);

    await _leer(tester);

    expect(caso.lector.rutas, ['/tmp/etiqueta.jpg']);
    expect(_valorDe(tester, 'Nombre'), 'Etanol absoluto');
    expect(_valorDe(tester, 'Marca'), 'Cicarelli');
    expect(_valorDe(tester, 'Fórmula'), 'C2H6O');
    expect(_valorDe(tester, 'Peso molecular'), '46.07');
    expect(
      find.text('Se completaron los datos de la etiqueta: revisalos antes de guardar'),
      findsOneWidget,
    );
  });

  testWidgets('el vencimiento leído queda en el botón de la fecha', (tester) async {
    await _abrir(tester, _Caso(_textoDeEtiqueta));

    await _leer(tester);

    expect(find.text('Vence: 30/11/2027'), findsOneWidget);
    expect(find.text('Seleccionar fecha de vencimiento'), findsNothing);
  });

  testWidgets('una lectura no pisa lo que ya estaba escrito', (tester) async {
    await _abrir(tester, _Caso(_textoDeEtiqueta));
    await _escribir(tester, 'Nombre', 'Mi etanol');
    await _escribir(tester, 'Fórmula', 'CH3CH2OH');

    await _leer(tester);

    expect(_valorDe(tester, 'Nombre'), 'Mi etanol');
    expect(_valorDe(tester, 'Fórmula'), 'CH3CH2OH');
    // Lo que estaba vacío sí se completa.
    expect(_valorDe(tester, 'Marca'), 'Cicarelli');
  });

  testWidgets('en una solución preparada completa el nombre pero no la química',
      (tester) async {
    await _abrir(tester, _Caso(_textoDeEtiqueta));
    await tester.tap(find.widgetWithText(InputDecorator, 'Tipo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Solución preparada').last);
    await tester.pumpAndSettle();

    await _leer(tester);

    expect(_valorDe(tester, 'Nombre'), 'Etanol absoluto');
    expect(find.widgetWithText(TextFormField, 'Fórmula'), findsNothing);
    // El vencimiento sirve para los dos tipos.
    expect(find.text('Vence: 30/11/2027'), findsOneWidget);
  });

  testWidgets('si se cancela la cámara no pasa nada', (tester) async {
    final caso = _Caso(_textoDeEtiqueta)..foto = null;
    await _abrir(tester, caso);

    await _leer(tester);

    expect(caso.fotosSacadas, 1);
    expect(caso.lector.rutas, isEmpty);
    expect(_valorDe(tester, 'Nombre'), '');
    expect(find.textContaining('No se pudo'), findsNothing);
  });

  testWidgets('si la cámara no abre (sin permiso), lo dice sin detalle técnico',
      (tester) async {
    final caso = _Caso(_textoDeEtiqueta)
      ..errorDeCamara = Exception('camera_access_denied');
    await _abrir(tester, caso);

    await _leer(tester);

    expect(find.text('No se pudo abrir la cámara'), findsOneWidget);
    expect(find.textContaining('camera_access_denied'), findsNothing);
  });

  testWidgets('si la foto no tiene texto, explica cómo sacarla mejor', (tester) async {
    await _abrir(tester, _Caso(''));

    await _leer(tester);

    expect(find.textContaining('No se encontraron datos en la foto'), findsOneWidget);
    expect(_valorDe(tester, 'Nombre'), '');
  });

  testWidgets('si el lector falla, lo dice sin detalle técnico', (tester) async {
    final caso = _Caso(_textoDeEtiqueta)..lector.falla = true;
    await _abrir(tester, caso);

    await _leer(tester);

    expect(find.text('No se pudo leer la etiqueta'), findsOneWidget);
    expect(find.textContaining('se cayó'), findsNothing);
    expect(_valorDe(tester, 'Nombre'), '');
  });

  testWidgets('mientras lee, el botón avisa y no se puede volver a tocar',
      (tester) async {
    final caso = _Caso(_textoDeEtiqueta);
    caso.lector.espera = Completer<void>();
    await _abrir(tester, caso);

    await tester.tap(find.text('Leer etiqueta con la cámara'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Leyendo la etiqueta…'), findsOneWidget);
    expect(find.text('Leer etiqueta con la cámara'), findsNothing);

    caso.lector.espera!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Leer etiqueta con la cámara'), findsOneWidget);
    expect(caso.fotosSacadas, 1);
  });
}
