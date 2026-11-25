import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/core/plataforma.dart';

// Corre [cuerpo] como si la app estuviera en [plataforma]. Siempre se vuelve a
// la plataforma real: flutter_test falla si el cambio queda puesto al terminar.
void _en(TargetPlatform plataforma, void Function() cuerpo) {
  debugDefaultTargetPlatformOverride = plataforma;
  try {
    cuerpo();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  group('escanerDisponible', () {
    test('hay escáner en celulares y macOS', () {
      for (final plataforma in [
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      ]) {
        _en(plataforma, () => expect(Plataforma.escanerDisponible, isTrue));
      }
    });

    test('no hay escáner en Windows ni Linux', () {
      for (final plataforma in [TargetPlatform.windows, TargetPlatform.linux]) {
        _en(plataforma, () => expect(Plataforma.escanerDisponible, isFalse));
      }
    });
  });
}