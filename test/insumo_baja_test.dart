import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';

Map<String, dynamic> _datos({Object? activo = 'sin-dato'}) => {
      'nombre': 'Etanol',
      'tipo': 'comprado',
      'stock': 5,
      'ubicacion': 'Estante A',
      'umbralMinimo': 2,
      if (activo != 'sin-dato') 'activo': activo,
    };

void main() {
  group('baja lógica del insumo', () {
    test('un insumo anterior al campo cuenta como activo', () {
      expect(Insumo.fromMap('i1', _datos()).activo, isTrue);
    });

    test('lee activo en false como dado de baja', () {
      expect(Insumo.fromMap('i1', _datos(activo: false)).activo, isFalse);
    });

    test('los datos de las planillas se guardan y se leen', () {
      final datos = _datos()
        ..['codigoInterno'] = 'I3'
        ..['otrosNombres'] = ['Alcohol etílico', 'Etanol']
        ..['controlado'] = true;

      final insumo = Insumo.fromMap('i1', datos);

      expect(insumo.codigoInterno, 'I3');
      expect(insumo.otrosNombres, ['Alcohol etílico', 'Etanol']);
      expect(insumo.controlado, isTrue);
      expect(insumo.toMap()['otrosNombres'], ['Alcohol etílico', 'Etanol']);
    });

    test('un insumo anterior a esos datos no tiene código ni otros nombres ni control', () {
      final insumo = Insumo.fromMap('i1', _datos());

      expect(insumo.codigoInterno, isNull);
      expect(insumo.otrosNombres, isEmpty);
      expect(insumo.controlado, isFalse);
    });

    test('un insumo nuevo está activo', () {
      final insumo = Insumo(
        id: '',
        nombre: 'Etanol',
        tipo: InsumoTipo.comprado,
        stock: 1,
        ubicacion: 'A',
        umbralMinimo: 1,
      );

      expect(insumo.activo, isTrue);
      expect(insumo.toMap()['activo'], isTrue);
    });
  });
}
