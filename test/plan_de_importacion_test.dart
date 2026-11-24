import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/importacion.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/services/plan_de_importacion.dart';

InsumoImportado _importado(
  String nombre, {
  String ubicacion = 'Armario 1',
  int cantidad = 2,
  bool controlado = false,
}) =>
    InsumoImportado(
      nombre: nombre,
      cantidad: cantidad,
      ubicacion: ubicacion,
      hoja: 'Hoja',
      fila: 2,
      codigoInterno: 'X1',
      formula: 'C2H6O',
      categoria: 'Alcoholes y solventes',
      otrosNombres: const ['Alcohol etílico'],
      controlado: controlado,
    );

Insumo _existente(String nombre, String ubicacion, {bool activo = true}) => Insumo(
      id: nombre,
      nombre: nombre,
      tipo: InsumoTipo.comprado,
      stock: 1,
      ubicacion: ubicacion,
      umbralMinimo: 1,
      activo: activo,
    );

PlanDeImportacion _plan(
  List<InsumoImportado> importados, {
  List<Insumo> existentes = const [],
  List<String> ubicaciones = const [],
}) =>
    PlanDeImportacion.armar(
      importados: importados,
      existentes: existentes,
      ubicaciones: ubicaciones,
    );

void main() {
  test('un insumo nuevo se carga con todos sus datos y stock mínimo 1', () {
    final plan = _plan([_importado('Etanol', cantidad: 5, controlado: true)]);

    final i = plan.nuevos.single;
    expect(i.nombre, 'Etanol');
    expect(i.stock, 5);
    expect(i.umbralMinimo, PlanDeImportacion.stockMinimoPorDefecto);
    expect(PlanDeImportacion.stockMinimoPorDefecto, 1);
    expect(i.tipo, InsumoTipo.comprado);
    expect(i.codigoInterno, 'X1');
    expect(i.formula, 'C2H6O');
    expect(i.categoria, 'Alcoholes y solventes');
    expect(i.otrosNombres, ['Alcohol etílico']);
    expect(i.controlado, isTrue);
    expect(i.activo, isTrue);
    expect(plan.repetidos, 0);
  });

  test('un insumo sin stock ("NO HAY") entra con 0', () {
    expect(_plan([_importado('Agar', cantidad: 0)]).nuevos.single.stock, 0);
  });

  test('se saltan los que ya están cargados, sin mirar mayúsculas ni espacios', () {
    final plan = _plan(
      [_importado('ETANOL absoluto', ubicacion: 'armario  1'), _importado('Metanol')],
      existentes: [_existente('Etanol Absoluto', 'Armario 1')],
    );

    expect(plan.nuevos.map((i) => i.nombre), ['Metanol']);
    expect(plan.repetidos, 1);
  });

  test('el mismo nombre en otro lugar es otro insumo', () {
    final plan = _plan(
      [_importado('Etanol', ubicacion: 'Armario 2')],
      existentes: [_existente('Etanol', 'Armario 1')],
    );

    expect(plan.nuevos, hasLength(1));
    expect(plan.repetidos, 0);
  });

  test('uno dado de baja no cuenta como ya cargado', () {
    final plan = _plan(
      [_importado('Etanol')],
      existentes: [_existente('Etanol', 'Armario 1', activo: false)],
    );

    expect(plan.nuevos, hasLength(1));
  });

  test('se saltan los repetidos dentro del mismo archivo', () {
    final plan = _plan([_importado('Etanol'), _importado('etanol'), _importado('Metanol')]);

    expect(plan.nuevos.map((i) => i.nombre), ['Etanol', 'Metanol']);
    expect(plan.repetidos, 1);
  });

  test('la ubicación se escribe como ya está en la lista', () {
    final plan = _plan(
      [_importado('Etanol', ubicacion: ' heladera  panol ')],
      ubicaciones: ['Heladera Pañol'],
    );

    expect(plan.nuevos.single.ubicacion, 'Heladera Pañol');
    expect(plan.ubicacionesNuevas, isEmpty);
  });

  test('las ubicaciones que faltan se agregan una sola vez', () {
    final plan = _plan(
      [
        _importado('Etanol', ubicacion: 'Armario 7'),
        _importado('Metanol', ubicacion: 'armario 7'),
        _importado('Acetona', ubicacion: 'Armario 8'),
      ],
      ubicaciones: ['Armario 1'],
    );

    expect(plan.ubicacionesNuevas, ['Armario 7', 'Armario 8']);
    // Los dos del armario 7 quedan con la misma escritura.
    expect(plan.nuevos.map((i) => i.ubicacion), ['Armario 7', 'Armario 7', 'Armario 8']);
  });

  test('un insumo repetido no agrega su ubicación a la lista', () {
    final plan = _plan(
      [_importado('Etanol', ubicacion: 'Armario 9')],
      existentes: [_existente('Etanol', 'Armario 9')],
      ubicaciones: const [],
    );

    expect(plan.nuevos, isEmpty);
    expect(plan.ubicacionesNuevas, isEmpty);
  });

  test('sin nada que importar el plan está vacío', () {
    final plan = _plan(const []);

    expect(plan.nuevos, isEmpty);
    expect(plan.repetidos, 0);
    expect(plan.ubicacionesNuevas, isEmpty);
  });
}
