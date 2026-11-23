import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/core/go_router_refresh_stream.dart';

void main() {
  test('avisa al router cada vez que el stream emite', () async {
    final controlador = StreamController<int>();
    final refresco = GoRouterRefreshStream(controlador.stream);
    addTearDown(() async {
      refresco.dispose();
      await controlador.close();
    });

    var avisos = 0;
    refresco.addListener(() => avisos++);

    controlador.add(1);
    await Future<void>.delayed(Duration.zero);
    controlador.add(2);
    await Future<void>.delayed(Duration.zero);

    expect(avisos, 2);
  });

  test('al cerrarlo deja de escuchar el stream', () async {
    final controlador = StreamController<int>();
    final refresco = GoRouterRefreshStream(controlador.stream);

    var avisos = 0;
    refresco.addListener(() => avisos++);
    refresco.dispose();

    controlador.add(1);
    await Future<void>.delayed(Duration.zero);

    expect(avisos, 0);
    await controlador.close();
  });
}
