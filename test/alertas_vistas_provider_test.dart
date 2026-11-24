import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/alerta.dart';
import 'package:tpfinal_grupo2/models/alerta_vista.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/movimiento_stock.dart';
import 'package:tpfinal_grupo2/models/trabajo_practico.dart';
import 'package:tpfinal_grupo2/providers/alerta_provider.dart';
import 'package:tpfinal_grupo2/providers/historial_provider.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/trabajopractico_provider.dart';
import 'package:tpfinal_grupo2/providers/usuario_provider.dart';
import 'package:tpfinal_grupo2/services/alertas_vistas_service.dart';

/// Reemplazo del servicio real: no escribe en Firestore, solo anota qué le
/// pidieron. Las marcas que "hay guardadas" las emite el test a mano.
class _ServicioFalso implements AlertasVistasService {
  final controlador = StreamController<List<AlertaVista>>.broadcast();

  final marcadas = <(String, String)>[];
  final desmarcadas = <(String, String)>[];
  final olvidadas = <(String, List<String>)>[];

  void hayVistas(List<String> alertaIds) {
    controlador.add([
      for (final id in alertaIds)
        AlertaVista(alertaId: id, usuarioId: 'u1', vistaEn: DateTime(2026, 11, 20)),
    ]);
  }

  @override
  Stream<List<AlertaVista>> watchVistas(String usuarioId) => controlador.stream;

  @override
  Future<void> marcar(String usuarioId, String alertaId, {DateTime? ahora}) async {
    marcadas.add((usuarioId, alertaId));
  }

  final variasMarcadas = <(String, List<String>)>[];

  @override
  Future<void> marcarVarias(
    String usuarioId,
    Iterable<String> alertaIds, {
    DateTime? ahora,
  }) async {
    variasMarcadas.add((usuarioId, alertaIds.toList()));
  }

  @override
  Future<void> desmarcar(String usuarioId, String alertaId) async {
    desmarcadas.add((usuarioId, alertaId));
  }

  @override
  Future<void> olvidar(String usuarioId, Iterable<String> alertaIds) async {
    olvidadas.add((usuarioId, alertaIds.toList()));
  }
}

Insumo _insumo(String id, {int stock = 10}) => Insumo(
      id: id,
      nombre: 'Insumo $id',
      tipo: InsumoTipo.comprado,
      stock: stock,
      ubicacion: 'Estante 1',
      umbralMinimo: 2,
    );

Alerta _alerta(String id, TipoAlerta tipo) =>
    Alerta(productoId: id, productoNombre: 'Insumo $id', tipo: tipo);

({ProviderContainer container, _ServicioFalso servicio}) _armar({
  List<Insumo>? insumos,
  Stream<List<MovimientoStock>>? movimientos,
  Stream<List<TrabajoPractico>>? tps,
}) {
  final servicio = _ServicioFalso();
  addTearDown(servicio.controlador.close);

  final container = ProviderContainer(
    // Sin reintentos: un error de prueba tiene que quedar como error.
    retry: (retries, error) => null,
    overrides: [
      usuarioActualIdProvider.overrideWithValue('u1'),
      alertasVistasServiceProvider.overrideWithValue(servicio),
      // Sin insumos con alertas por defecto: el que no las necesita no las ve.
      insumosProvider.overrideWith(
        (ref) => Stream.value(insumos ?? const <Insumo>[]),
      ),
      movimientosStockProvider.overrideWith(
        (ref) => movimientos ?? Stream.value(const <MovimientoStock>[]),
      ),
      tpsStreamProvider.overrideWith(
        (ref) => tps ?? Stream.value(const <TrabajoPractico>[]),
      ),
    ],
  );
  addTearDown(container.dispose);
  // Como la pantalla real, el test tiene que escuchar los providers: en
  // Riverpod 3 un stream que nadie escucha queda pausado.
  container.listen(alertasProvider, (previous, next) {});
  container.listen(alertasVistasProvider, (previous, next) {});
  container.listen(alertasSinVerProvider, (previous, next) {});
  return (container: container, servicio: servicio);
}

// Deja pasar los eventos de los streams hacia los providers.
Future<void> _esperar() async {
  for (var i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('qué alertas se ven como nuevas', () {
    test('las marcas se convierten en un conjunto de ids', () async {
      final t = _armar();
      t.servicio.hayVistas(['p1-sinStock', 'p2-vencido']);
      await _esperar();

      expect(t.container.read(alertasVistasProvider).requireValue, {
        'p1-sinStock',
        'p2-vencido',
      });
    });

    test('sin ver quedan las que la persona no marcó', () async {
      final t = _armar(insumos: [_insumo('p1', stock: 0), _insumo('p2', stock: 0)]);
      t.servicio.hayVistas(['p1-sinStock']);
      await _esperar();

      final sinVer = t.container.read(alertasSinVerProvider);

      expect([for (final a in sinVer) a.id], ['p2-sinStock']);
    });

    test('mientras las marcas cargan, todas se ven como nuevas', () async {
      final t = _armar(insumos: [_insumo('p1', stock: 0)]);
      await _esperar();

      expect(t.container.read(alertasVistasProvider).isLoading, isTrue);
      expect(t.container.read(alertasSinVerProvider), hasLength(1));
    });

    test('si no se pueden leer las marcas, no se esconde ninguna alerta', () async {
      final t = _armar(insumos: [_insumo('p1', stock: 0)]);
      t.servicio.controlador.addError(Exception('sin permiso'));
      await _esperar();

      expect(t.container.read(alertasSinVerProvider), hasLength(1));
    });

    test('una marca de otra alerta no esconde la que no se marcó', () async {
      final t = _armar(insumos: [_insumo('p1', stock: 0)]);
      t.servicio.hayVistas(['p1-stockBajo']);
      await _esperar();

      expect(t.container.read(alertasSinVerProvider), hasLength(1));
    });
  });

  group('marcar y desmarcar', () {
    test('marcar como vista guarda la alerta para la persona actual', () async {
      final t = _armar();

      await t.container
          .read(alertasAccionesProvider)
          .marcarVista(_alerta('p1', TipoAlerta.stockBajo));

      expect(t.servicio.marcadas, [('u1', 'p1-stockBajo')]);
    });

    test('marcar como no vista saca la marca', () async {
      final t = _armar();

      await t.container
          .read(alertasAccionesProvider)
          .marcarNoVista(_alerta('p1', TipoAlerta.stockBajo));

      expect(t.servicio.desmarcadas, [('u1', 'p1-stockBajo')]);
    });
  });

  group('marcar todas como vistas', () {
    test('marca de una vez las alertas que todavía no se vieron', () async {
      final t = _armar(insumos: [
        _insumo('p1', stock: 0),
        _insumo('p2', stock: 0),
      ]);
      await _esperar();
      t.servicio.hayVistas(['p1-sinStock']);
      await _esperar();

      final cantidad =
          await t.container.read(alertasAccionesProvider).marcarTodasVistas();

      expect(cantidad, 1);
      expect(t.servicio.variasMarcadas.single.$1, 'u1');
      expect(t.servicio.variasMarcadas.single.$2, ['p2-sinStock']);
    });

    test('sin alertas nuevas no escribe nada', () async {
      final t = _armar();
      await _esperar();

      final cantidad =
          await t.container.read(alertasAccionesProvider).marcarTodasVistas();

      expect(cantidad, 0);
      expect(t.servicio.variasMarcadas, isEmpty);
    });
  });

  group('limpiar las marcas de alertas que ya no existen', () {
    test('borra las que ya no tienen alerta y deja las que siguen', () async {
      final t = _armar(insumos: [_insumo('p1', stock: 0)]);
      // p1 sigue sin stock; p9 se repuso hace rato y ya no hay alerta.
      t.servicio.hayVistas(['p1-sinStock', 'p9-stockBajo']);
      await _esperar();

      await t.container.read(alertasAccionesProvider).limpiarObsoletas();

      // Un registro con una lista adentro no se compara por contenido: se mira
      // cada parte.
      expect(t.servicio.olvidadas, hasLength(1));
      expect(t.servicio.olvidadas.single.$1, 'u1');
      expect(t.servicio.olvidadas.single.$2, ['p9-stockBajo']);
    });

    test('si todas las marcas siguen vigentes, no escribe nada', () async {
      final t = _armar(insumos: [_insumo('p1', stock: 0)]);
      t.servicio.hayVistas(['p1-sinStock']);
      await _esperar();

      await t.container.read(alertasAccionesProvider).limpiarObsoletas();

      expect(t.servicio.olvidadas, isEmpty);
    });

    test('sin marcas no escribe nada', () async {
      final t = _armar(insumos: [_insumo('p1', stock: 0)]);
      t.servicio.hayVistas(const []);
      await _esperar();

      await t.container.read(alertasAccionesProvider).limpiarObsoletas();

      expect(t.servicio.olvidadas, isEmpty);
    });

    test('mientras las marcas cargan, no borra nada', () async {
      final t = _armar(insumos: [_insumo('p1', stock: 0)]);
      await _esperar();

      await t.container.read(alertasAccionesProvider).limpiarObsoletas();

      expect(t.servicio.olvidadas, isEmpty);
    });

    test('mientras la predicción carga, no borra nada', () async {
      // Los movimientos nunca llegan: la predicción sigue cargando y las
      // alertas que ella arma todavía no existen. No son "obsoletas".
      final sinTerminar = StreamController<List<MovimientoStock>>();
      addTearDown(sinTerminar.close);
      final t = _armar(
        insumos: [_insumo('p1', stock: 0)],
        movimientos: sinTerminar.stream,
      );
      t.servicio.hayVistas(['p1-agotamientoProximo']);
      await _esperar();

      await t.container.read(alertasAccionesProvider).limpiarObsoletas();

      expect(t.servicio.olvidadas, isEmpty);
    });

    test('si falla la lectura de los movimientos, no borra nada', () async {
      final t = _armar(
        insumos: [_insumo('p1', stock: 0)],
        movimientos: Stream.error(Exception('sin permiso')),
      );
      t.servicio.hayVistas(['p1-agotamientoProximo']);
      await _esperar();

      await t.container.read(alertasAccionesProvider).limpiarObsoletas();

      expect(t.servicio.olvidadas, isEmpty);
    });

    test('si falla la lectura de los TP, no borra nada', () async {
      // La predicción sigue sin los TP, pero entonces le faltan avisos: no se
      // puede saber si "no alcanza para un TP" dejó de ser cierto.
      final t = _armar(
        insumos: [_insumo('p1', stock: 0)],
        tps: Stream.error(Exception('sin permiso')),
      );
      t.servicio.hayVistas(['p1-tpSinCobertura']);
      await _esperar();

      await t.container.read(alertasAccionesProvider).limpiarObsoletas();

      expect(t.servicio.olvidadas, isEmpty);
    });

    test('si fallan los insumos, no borra nada', () async {
      final servicio = _ServicioFalso();
      addTearDown(servicio.controlador.close);
      final container = ProviderContainer(
        retry: (retries, error) => null,
        overrides: [
          usuarioActualIdProvider.overrideWithValue('u1'),
          alertasVistasServiceProvider.overrideWithValue(servicio),
          insumosProvider.overrideWith((ref) => Stream.error(Exception('sin permiso'))),
          movimientosStockProvider.overrideWith((ref) => Stream.value(const <MovimientoStock>[])),
          tpsStreamProvider.overrideWith((ref) => Stream.value(const <TrabajoPractico>[])),
        ],
      );
      addTearDown(container.dispose);
      container.listen(alertasProvider, (previous, next) {});
      container.listen(alertasVistasProvider, (previous, next) {});
      servicio.hayVistas(['p1-sinStock']);
      await _esperar();

      await container.read(alertasAccionesProvider).limpiarObsoletas();

      expect(servicio.olvidadas, isEmpty);
    });
  });
}
