import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pone la ventana de la prueba con el tamaño de un celular (360 x 800).
///
/// El tamaño por defecto de flutter_test (800 px de ancho) ya cuenta como
/// escritorio, donde el AppShell muestra un panel lateral en vez de la barra
/// inferior y el menú. Las pruebas que dependen de la barra o del menú de
/// celular lo llaman antes de montar la pantalla. Al terminar la prueba, el
/// tamaño vuelve solo al original.
void usarPantallaDeCelular(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}