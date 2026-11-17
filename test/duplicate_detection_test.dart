import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/hallazgo.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/services/duplicate_detection_service.dart';

Insumo _insumo(
  String id,
  String nombre, {
  InsumoTipo tipo = InsumoTipo.comprado,
  int stock = 10,
  num umbral = 5,
  String ubicacion = 'Estante A',
  String? marca,
  String? codigoBarras,
  String? concentracion,
  DateTime? vencimiento,
  DateTime? elaboracion,
  bool alarma = false,
}) {
  return Insumo(
    id: id,
    nombre: nombre,
    tipo: tipo,
    stock: stock,
    ubicacion: ubicacion,
    umbralMinimo: umbral,
    marca: marca,
    codigoBarras: codigoBarras,
    concentracion: concentracion,
    fechaVencimiento: vencimiento,
    fechaElaboracion: elaboracion,
    alarmaVencimiento: alarma,
  );
}

List<TipoHallazgo> _tipos(List<Hallazgo> hallazgos) =>
    hallazgos.map((h) => h.tipo).toList();

void main() {
  group('duplicados', () {
    test('el mismo código de barras es un duplicado exacto', () {
      final hallazgos = DuplicateDetectionService.detectarDuplicados([
        _insumo('a', 'Etanol', codigoBarras: '7791234'),
        _insumo('b', 'Alcohol etílico', codigoBarras: '7791234'),
      ]);

      expect(_tipos(hallazgos), [TipoHallazgo.duplicadoExacto]);
      expect(hallazgos.first.insumoIds, ['a', 'b']);
    });

    test('el mismo nombre normalizado es un duplicado exacto', () {
      final hallazgos = DuplicateDetectionService.detectarDuplicados([
        _insumo('a', 'Etanol 96%'),
        _insumo('b', 'etanol 96 %'),
      ]);

      expect(_tipos(hallazgos), [TipoHallazgo.duplicadoExacto]);
    });

    test('un error de tipeo es un duplicado probable con su parecido', () {
      final hallazgos = DuplicateDetectionService.detectarDuplicados([
        _insumo('a', 'Tubos Falcon 50ml'),
        _insumo('b', 'Tubos Falcn 50ml'),
      ]);

      expect(_tipos(hallazgos), [TipoHallazgo.duplicadoProbable]);
      expect(hallazgos.first.confianza, greaterThanOrEqualTo(0.85));
      expect(hallazgos.first.confianza, lessThan(1));
    });

    test('números distintos no son duplicados (1M y 2M)', () {
      final hallazgos = DuplicateDetectionService.detectarDuplicados([
        _insumo('a', 'Ácido acético 1M'),
        _insumo('b', 'Ácido acético 2M'),
      ]);

      expect(hallazgos, isEmpty);
    });

    test('marcas distintas no son duplicados', () {
      final hallazgos = DuplicateDetectionService.detectarDuplicados([
        _insumo('a', 'Etanol 96%', marca: 'Merck'),
        _insumo('b', 'Etanol 96%', marca: 'Biopack'),
      ]);

      expect(hallazgos, isEmpty);
    });

    test('si una de las dos no tiene marca, se comparan igual', () {
      final hallazgos = DuplicateDetectionService.detectarDuplicados([
        _insumo('a', 'Etanol 96%', marca: 'Merck'),
        _insumo('b', 'Etanol 96%'),
      ]);

      expect(_tipos(hallazgos), [TipoHallazgo.duplicadoExacto]);
    });

    test('un comprado y una solución con el mismo nombre no son duplicados', () {
      final hallazgos = DuplicateDetectionService.detectarDuplicados([
        _insumo('a', 'Etanol 70%'),
        _insumo('b', 'Etanol 70%', tipo: InsumoTipo.solucion, concentracion: '70%'),
      ]);

      expect(hallazgos, isEmpty);
    });

    test('nombres distintos no son duplicados', () {
      final hallazgos = DuplicateDetectionService.detectarDuplicados([
        _insumo('a', 'Agar LB'),
        _insumo('b', 'Guantes de nitrilo'),
      ]);

      expect(hallazgos, isEmpty);
    });

    test('tres iguales dan tres pares, cada uno una sola vez', () {
      final hallazgos = DuplicateDetectionService.detectarDuplicados([
        _insumo('a', 'Agar'),
        _insumo('b', 'Agar'),
        _insumo('c', 'Agar'),
      ]);

      expect(hallazgos, hasLength(3));
    });

    test('los más seguros van primero', () {
      final hallazgos = DuplicateDetectionService.detectarDuplicados([
        _insumo('a', 'Tubos Falcon 50ml'),
        _insumo('b', 'Tubos Falcn 50ml'),
        _insumo('c', 'Agar LB'),
        _insumo('d', 'agar lb'),
      ]);

      expect(
        _tipos(hallazgos),
        [TipoHallazgo.duplicadoExacto, TipoHallazgo.duplicadoProbable],
      );
    });
  });

  group('buscarSimilares', () {
    final existentes = [
      _insumo('1', 'Etanol 96%'),
      _insumo('2', 'Agar LB'),
      _insumo('3', 'Etanol 96 %', marca: 'Merck'),
    ];

    test('encuentra los que se parecen al nombre que se está cargando', () {
      final similares =
          DuplicateDetectionService.buscarSimilares('etanol 96', existentes);

      expect(similares.map((i) => i.id), containsAll(['1', '3']));
      expect(similares.any((i) => i.id == '2'), isFalse);
    });

    test('deja afuera al insumo que se está editando', () {
      final similares = DuplicateDetectionService.buscarSimilares(
        'Etanol 96%',
        existentes,
        excluirId: '1',
      );

      expect(similares.any((i) => i.id == '1'), isFalse);
    });

    test('el mismo código de barras siempre cuenta, aunque el nombre difiera', () {
      final similares = DuplicateDetectionService.buscarSimilares(
        'Nombre totalmente distinto',
        [_insumo('9', 'Reactivo X', codigoBarras: '123')],
        codigoBarras: '123',
      );

      expect(similares.map((i) => i.id), ['9']);
    });

    test('sin nada parecido devuelve vacío', () {
      expect(
        DuplicateDetectionService.buscarSimilares('Pipetas', existentes),
        isEmpty,
      );
    });

    test('con marca distinta no cuenta', () {
      final similares = DuplicateDetectionService.buscarSimilares(
        'Etanol 96%',
        [_insumo('3', 'Etanol 96%', marca: 'Merck')],
        marca: 'Biopack',
      );

      expect(similares, isEmpty);
    });
  });

  group('inconsistencias', () {
    final hoy = DateTime.now();

    test('un insumo sano no tiene hallazgos', () {
      expect(
        DuplicateDetectionService.detectarInconsistencias([_insumo('a', 'Agar')]),
        isEmpty,
      );
    });

    test('stock negativo', () {
      final h = DuplicateDetectionService.detectarInconsistencias(
        [_insumo('a', 'Guantes', stock: -3)],
      );

      expect(_tipos(h), [TipoHallazgo.stockNegativo]);
    });

    test('umbral mínimo negativo', () {
      final h = DuplicateDetectionService.detectarInconsistencias(
        [_insumo('a', 'Guantes', umbral: -5)],
      );

      expect(_tipos(h), [TipoHallazgo.umbralNegativo]);
    });

    test('alarma de vencimiento sin fecha', () {
      final h = DuplicateDetectionService.detectarInconsistencias(
        [_insumo('a', 'Enzima', alarma: true)],
      );

      expect(_tipos(h), [TipoHallazgo.alarmaSinFecha]);
    });

    test('la alarma apagada sin fecha está bien', () {
      expect(
        DuplicateDetectionService.detectarInconsistencias(
          [_insumo('a', 'Enzima', alarma: false)],
        ),
        isEmpty,
      );
    });

    test('vencimiento anterior a la elaboración', () {
      final h = DuplicateDetectionService.detectarInconsistencias([
        _insumo(
          'a',
          'Solución',
          tipo: InsumoTipo.solucion,
          concentracion: '1M',
          elaboracion: hoy,
          vencimiento: hoy.subtract(const Duration(days: 5)),
        ),
      ]);

      expect(_tipos(h), [TipoHallazgo.vencimientoAnteriorAElaboracion]);
    });

    test('insumo sin ubicación', () {
      final h = DuplicateDetectionService.detectarInconsistencias(
        [_insumo('a', 'Agar', ubicacion: '  ')],
      );

      expect(_tipos(h), [TipoHallazgo.sinUbicacion]);
    });

    test('solución sin concentración', () {
      final h = DuplicateDetectionService.detectarInconsistencias(
        [_insumo('a', 'Solución', tipo: InsumoTipo.solucion)],
      );

      expect(_tipos(h), [TipoHallazgo.solucionSinConcentracion]);
    });

    test('un comprado sin concentración está bien', () {
      expect(
        DuplicateDetectionService.detectarInconsistencias([_insumo('a', 'Agar')]),
        isEmpty,
      );
    });

    test('un insumo puede tener varias inconsistencias a la vez', () {
      final h = DuplicateDetectionService.detectarInconsistencias(
        [_insumo('a', 'Mal cargado', stock: -1, ubicacion: '')],
      );

      expect(
        _tipos(h),
        containsAll([TipoHallazgo.stockNegativo, TipoHallazgo.sinUbicacion]),
      );
      expect(h, hasLength(2));
    });
  });

  group('detectar', () {
    test('junta duplicados e inconsistencias, con los duplicados primero', () {
      final h = DuplicateDetectionService.detectar([
        _insumo('a', 'Agar LB', stock: -1),
        _insumo('b', 'agar lb'),
      ]);

      expect(h.first.tipo.esDuplicado, isTrue);
      expect(_tipos(h), contains(TipoHallazgo.stockNegativo));
    });

    test('sin insumos no hay hallazgos', () {
      expect(DuplicateDetectionService.detectar(const []), isEmpty);
    });
  });
}
