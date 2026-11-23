import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/alerta.dart';
import 'package:tpfinal_grupo2/models/alerta_vista.dart';
import 'package:tpfinal_grupo2/models/filtro_alertas.dart';
import 'package:tpfinal_grupo2/providers/alerta_provider.dart';

Alerta _alerta(String producto, TipoAlerta tipo) =>
    Alerta(productoId: producto, productoNombre: 'Insumo $producto', tipo: tipo);

final _sinStock = _alerta('p1', TipoAlerta.sinStock);
final _stockBajo = _alerta('p2', TipoAlerta.stockBajo);
final _vencido = _alerta('p3', TipoAlerta.vencido);
final _agotaria = _alerta('p4', TipoAlerta.agotamientoProximo);
final _otroSinStock = _alerta('p5', TipoAlerta.sinStock);

final _todas = [_sinStock, _stockBajo, _vencido, _agotaria, _otroSinStock];

void main() {
  group('FiltroAlertas', () {
    test('un filtro vacío deja pasar todas, en el mismo orden', () {
      const filtro = FiltroAlertas();

      expect(filtro.estaVacio, isTrue);
      expect(filtro.aplicar(_todas, const {}), _todas);
    });

    test('por tipo deja solo las de ese tipo', () {
      const filtro = FiltroAlertas(tipo: TipoAlerta.sinStock);

      expect(filtro.estaVacio, isFalse);
      expect(filtro.aplicar(_todas, const {}), [_sinStock, _otroSinStock]);
    });

    test('un tipo sin alertas da una lista vacía', () {
      const filtro = FiltroAlertas(tipo: TipoAlerta.tpSinCobertura);

      expect(filtro.aplicar(_todas, const {}), isEmpty);
    });

    test('sin ver deja las que no están marcadas', () {
      const filtro = FiltroAlertas(estado: EstadoVistaAlerta.sinVer);
      final vistas = {_stockBajo.id, _agotaria.id};

      expect(filtro.estaVacio, isFalse);
      expect(filtro.aplicar(_todas, vistas), [_sinStock, _vencido, _otroSinStock]);
    });

    test('vistas deja solo las marcadas', () {
      const filtro = FiltroAlertas(estado: EstadoVistaAlerta.vistas);
      final vistas = {_stockBajo.id, _agotaria.id};

      expect(filtro.aplicar(_todas, vistas), [_stockBajo, _agotaria]);
    });

    test('todas ignora las marcas', () {
      const filtro = FiltroAlertas();

      expect(filtro.aplicar(_todas, {_sinStock.id}), _todas);
    });

    test('tipo y estado se combinan', () {
      const filtro = FiltroAlertas(
        tipo: TipoAlerta.sinStock,
        estado: EstadoVistaAlerta.sinVer,
      );

      expect(filtro.aplicar(_todas, {_sinStock.id}), [_otroSinStock]);
    });

    test('una marca de otra alerta no afecta', () {
      const filtro = FiltroAlertas(estado: EstadoVistaAlerta.vistas);

      expect(filtro.aplicar(_todas, {'otro-id'}), isEmpty);
    });

    test('dos filtros con lo mismo son iguales', () {
      expect(
        const FiltroAlertas(tipo: TipoAlerta.vencido),
        const FiltroAlertas(tipo: TipoAlerta.vencido),
      );
      expect(
        const FiltroAlertas(tipo: TipoAlerta.vencido),
        isNot(const FiltroAlertas(tipo: TipoAlerta.stockBajo)),
      );
      expect(
        const FiltroAlertas(estado: EstadoVistaAlerta.vistas),
        isNot(const FiltroAlertas()),
      );
    });
  });

  group('filtroAlertasProvider', () {
    test('arranca sin filtros', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(filtroAlertasProvider).estaVacio, isTrue);
    });

    test('cambiar guarda el filtro y limpiar lo vacía', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(filtroAlertasProvider.notifier)
          .cambiar(const FiltroAlertas(tipo: TipoAlerta.vencido));
      expect(
        container.read(filtroAlertasProvider),
        const FiltroAlertas(tipo: TipoAlerta.vencido),
      );

      container.read(filtroAlertasProvider.notifier).limpiar();
      expect(container.read(filtroAlertasProvider).estaVacio, isTrue);
    });
  });

  group('alertasFiltradasProvider', () {
    late StreamController<List<AlertaVista>> vistas;

    setUp(() => vistas = StreamController<List<AlertaVista>>.broadcast());
    tearDown(() => vistas.close());

    ProviderContainer crear({AsyncValue<List<Alerta>>? alertas}) {
      final container = ProviderContainer(
        overrides: [
          alertasProvider.overrideWithValue(alertas ?? AsyncData(_todas)),
          alertasVistasProvider.overrideWith(
            (ref) => vistas.stream.map(
              (lista) => {for (final v in lista) v.alertaId},
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      // Las marcas son un stream: se escucha para que no se pause.
      container.listen(alertasVistasProvider, (previous, next) {});
      return container;
    }

    void hayVistas(List<String> ids) {
      vistas.add([
        for (final id in ids)
          AlertaVista(alertaId: id, usuarioId: 'u1', vistaEn: DateTime(2026, 11, 20)),
      ]);
    }

    test('sin filtro muestra todas', () {
      final container = crear();

      expect(container.read(alertasFiltradasProvider).value, _todas);
    });

    test('con un filtro de tipo muestra solo ese tipo', () {
      final container = crear();

      container
          .read(filtroAlertasProvider.notifier)
          .cambiar(const FiltroAlertas(tipo: TipoAlerta.vencido));

      expect(container.read(alertasFiltradasProvider).value, [_vencido]);
    });

    test('el filtro de estado usa las marcas de la persona', () async {
      final container = crear();
      container
          .read(filtroAlertasProvider.notifier)
          .cambiar(const FiltroAlertas(estado: EstadoVistaAlerta.sinVer));

      hayVistas([_sinStock.id]);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(alertasFiltradasProvider).value,
        [_stockBajo, _vencido, _agotaria, _otroSinStock],
      );
    });

    test('el filtro no cambia la lista de las sin ver (la de la campana)', () {
      final container = crear();

      container
          .read(filtroAlertasProvider.notifier)
          .cambiar(const FiltroAlertas(tipo: TipoAlerta.vencido));

      expect(container.read(alertasSinVerProvider), _todas);
    });

    test('mientras las alertas cargan, sigue cargando', () {
      final container = crear(alertas: const AsyncLoading<List<Alerta>>());

      expect(container.read(alertasFiltradasProvider).isLoading, isTrue);
    });

    test('si las alertas fallan, el error pasa tal cual', () {
      final container = crear(
        alertas: AsyncError<List<Alerta>>('sin permiso', StackTrace.empty),
      );

      expect(container.read(alertasFiltradasProvider).hasError, isTrue);
    });
  });
}
