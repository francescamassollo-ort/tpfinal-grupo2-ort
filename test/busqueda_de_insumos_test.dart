import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/providers/insumo_providers.dart';
import 'package:tpfinal_grupo2/providers/inventario_filter_provider.dart';
import 'package:tpfinal_grupo2/services/busqueda_de_insumos.dart';

Insumo _insumo({
  String nombre = 'Ácido acético',
  String ubicacion = 'Estante A',
  String? formula,
  String? codigoInterno,
  List<String> otrosNombres = const [],
  String? categoria,
  String? marca,
  String? codigoBarras,
}) =>
    Insumo(
      id: 'i1',
      nombre: nombre,
      tipo: InsumoTipo.comprado,
      stock: 5,
      ubicacion: ubicacion,
      umbralMinimo: 1,
      formula: formula,
      codigoInterno: codigoInterno,
      otrosNombres: otrosNombres,
      categoria: categoria,
      marca: marca,
      codigoBarras: codigoBarras,
    );

void main() {
  group('BusquedaDeInsumos.coincide', () {
    test('un texto vacío no filtra nada', () {
      expect(BusquedaDeInsumos.coincide(_insumo(), ''), isTrue);
      expect(BusquedaDeInsumos.coincide(_insumo(), '   '), isTrue);
    });

    test('ignora mayúsculas y tildes', () {
      expect(BusquedaDeInsumos.coincide(_insumo(), 'acido'), isTrue);
      expect(BusquedaDeInsumos.coincide(_insumo(), 'ÁCIDO ACÉTICO'), isTrue);
      expect(
        BusquedaDeInsumos.coincide(_insumo(nombre: 'Acido acetico'), 'ácido'),
        isTrue,
      );
    });

    test('todas las palabras tienen que aparecer, en cualquier orden', () {
      expect(BusquedaDeInsumos.coincide(_insumo(), 'acetico acido'), isTrue);
      expect(BusquedaDeInsumos.coincide(_insumo(), 'acido sulfurico'), isFalse);
    });

    test('las palabras pueden estar en campos distintos', () {
      final insumo = _insumo(marca: 'Merck');
      expect(BusquedaDeInsumos.coincide(insumo, 'acido merck'), isTrue);
    });

    test('busca en otros nombres', () {
      final insumo = _insumo(
        nombre: 'Alcohol bencílico',
        otrosNombres: ['Fenilmetanol'],
      );
      expect(BusquedaDeInsumos.coincide(insumo, 'fenilmetanol'), isTrue);
      expect(BusquedaDeInsumos.coincide(_insumo(), 'fenilmetanol'), isFalse);
    });

    test('busca en fórmula, código interno, categoría, marca, barras y ubicación',
        () {
      final insumo = _insumo(
        formula: 'C2H4O2',
        codigoInterno: 'Al-01',
        categoria: 'Solventes',
        marca: 'Sigma',
        codigoBarras: '7791234567890',
        ubicacion: 'Heladera 2',
      );
      for (final texto in [
        'c2h4o2',
        'al-01',
        'solvente',
        'sigma',
        '7791234567890',
        'heladera',
      ]) {
        expect(BusquedaDeInsumos.coincide(insumo, texto), isTrue, reason: texto);
      }
      expect(BusquedaDeInsumos.coincide(insumo, 'freezer'), isFalse);
    });

    test('los campos vacíos (null) no rompen la búsqueda', () {
      expect(BusquedaDeInsumos.coincide(_insumo(), 'sigma'), isFalse);
    });
  });

  test('el Inventario filtra por el texto buscado y mantiene el orden', () async {
    final container = ProviderContainer(overrides: [
      insumosProvider.overrideWith((ref) => Stream.value([
            _insumo(nombre: 'Ácido clorhídrico'),
            _insumo(nombre: 'Etanol', otrosNombres: ['Alcohol etílico']),
            _insumo(nombre: 'Ácido acético'),
          ])),
    ]);
    addTearDown(container.dispose);
    container.listen(inventarioFiltradoProvider, (_, _) {});
    await container.read(insumosProvider.future);

    container.read(inventarioFilterProvider.notifier).setSearchText('acido');
    final lista = container.read(inventarioFiltradoProvider).value!;
    expect(lista.map((i) => i.nombre), ['Ácido acético', 'Ácido clorhídrico']);

    container.read(inventarioFilterProvider.notifier).setSearchText('etilico');
    expect(
      container.read(inventarioFiltradoProvider).value!.map((i) => i.nombre),
      ['Etanol'],
    );
  });
}
