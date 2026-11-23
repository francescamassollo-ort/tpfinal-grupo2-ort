import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tpfinal_grupo2/models/insumo.dart';
import 'package:tpfinal_grupo2/models/resultado_codigo.dart';
import 'package:tpfinal_grupo2/services/barcode_service.dart';

/// Un servidor falso en la propia computadora que hace de UPCitemdb (ruta
/// /upc/lookup) y de PubChem (ruta /pubchem/...): así se prueba el servicio sin
/// llamar a internet ni gastar la cuota diaria.
class _ServidorFalso {
  late final HttpServer _servidor;

  int estadoUpc = 200;
  String cuerpoUpc = '';
  Duration demoraUpc = Duration.zero;

  int estadoPubchem = 404;
  String cuerpoPubchem = '';

  /// Cada pedido recibido, con su ruta y sus parámetros.
  final pedidos = <Uri>[];

  int get puerto => _servidor.port;
  String get urlUpc => 'http://127.0.0.1:$puerto/upc';
  String get urlPubchem => 'http://127.0.0.1:$puerto/pubchem';

  List<Uri> get pedidosAUpc =>
      pedidos.where((u) => u.path.startsWith('/upc')).toList();
  List<Uri> get pedidosAPubchem =>
      pedidos.where((u) => u.path.startsWith('/pubchem')).toList();

  Future<void> iniciar() async {
    _servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _servidor.listen((pedido) async {
      pedidos.add(pedido.uri);
      final esUpc = pedido.uri.path.startsWith('/upc');

      if (esUpc && demoraUpc > Duration.zero) {
        await Future<void>.delayed(demoraUpc);
      }
      pedido.response
        ..statusCode = esUpc ? estadoUpc : estadoPubchem
        ..headers.contentType = ContentType.json
        ..write(esUpc ? cuerpoUpc : cuerpoPubchem);
      await pedido.response.close();
    });
  }

  Future<void> cerrar() => _servidor.close(force: true);
}

String _upcConProducto({String title = 'Ethanol 96% 1L', String brand = 'Merck'}) =>
    jsonEncode({
      'code': 'OK',
      'total': 1,
      'items': [
        {'title': title, 'brand': brand},
      ],
    });

const _upcSinProductos = '{"code":"OK","total":0,"items":[]}';

String _pubchem({String formula = 'C2H6O', Object peso = '46.07'}) => jsonEncode({
      'PropertyTable': {
        'Properties': [
          {'CID': 702, 'MolecularFormula': formula, 'MolecularWeight': peso},
        ],
      },
    });

Insumo _insumo(String id, String nombre, {String? codigo}) => Insumo(
      id: id,
      nombre: nombre,
      tipo: InsumoTipo.comprado,
      stock: 10,
      ubicacion: 'Estante 1',
      umbralMinimo: 2,
      codigoBarras: codigo,
    );

void main() {
  late _ServidorFalso servidor;

  setUp(() async {
    servidor = _ServidorFalso();
    await servidor.iniciar();
  });

  tearDown(() => servidor.cerrar());

  BarcodeService servicio({Duration tiempoMaximo = const Duration(seconds: 5)}) {
    return BarcodeService(
      upcUrlBase: servidor.urlUpc,
      pubchemUrlBase: servidor.urlPubchem,
      tiempoMaximo: tiempoMaximo,
    );
  }

  group('en nuestros insumos', () {
    test('si el código ya está cargado, no sale a internet', () async {
      final insumos = [_insumo('p1', 'Etanol', codigo: '7790001234567')];

      final resultado = await servicio().buscar('7790001234567', insumos: insumos);

      expect(resultado, isA<CodigoEnInventario>());
      expect((resultado as CodigoEnInventario).insumo.id, 'p1');
      expect(servidor.pedidos, isEmpty);
    });

    test('un código UPC-A y su versión EAN-13 (con un 0 delante) son el mismo', () {
      final insumos = [_insumo('p1', 'Etanol', codigo: '012345678905')];

      expect(BarcodeService.buscarEnInventario('0012345678905', insumos)?.id, 'p1');
      expect(BarcodeService.buscarEnInventario('012345678905', insumos)?.id, 'p1');
    });

    test('ignora los espacios', () {
      final insumos = [_insumo('p1', 'Etanol', codigo: '7790 0012 34')];

      expect(BarcodeService.buscarEnInventario(' 7790001234 ', insumos)?.id, 'p1');
    });

    test('un código distinto no coincide', () {
      final insumos = [_insumo('p1', 'Etanol', codigo: '111')];

      expect(BarcodeService.buscarEnInventario('222', insumos), isNull);
    });

    test('los insumos sin código no coinciden con nada', () {
      final insumos = [_insumo('p1', 'Etanol')];

      expect(BarcodeService.buscarEnInventario('111', insumos), isNull);
    });

    test('un código vacío o de solo ceros no encuentra a nadie', () {
      final insumos = [_insumo('p1', 'Etanol', codigo: '0')];

      expect(BarcodeService.buscarEnInventario('', insumos), isNull);
      expect(BarcodeService.buscarEnInventario('000', insumos), isNull);
    });
  });

  group('en internet', () {
    test('trae el nombre y la marca de UPCitemdb y la química de PubChem', () async {
      servidor
        ..cuerpoUpc = _upcConProducto()
        ..estadoPubchem = 200
        ..cuerpoPubchem = _pubchem();

      final resultado = await servicio().buscar('7790001234567');

      expect(resultado, isA<CodigoConocido>());
      final conocido = resultado as CodigoConocido;
      expect(conocido.nombre, 'Ethanol 96% 1L');
      expect(conocido.marca, 'Merck');
      expect(conocido.formula, 'C2H6O');
      expect(conocido.pesoMolecular, 46.07);
    });

    test('manda el código a UPCitemdb y el nombre a PubChem, bien armados', () async {
      servidor
        ..cuerpoUpc = _upcConProducto(title: 'Alcohol etílico 96%')
        ..estadoPubchem = 200
        ..cuerpoPubchem = _pubchem();

      await servicio().buscar('  7790001234567 ');

      expect(servidor.pedidosAUpc.single.path, '/upc/lookup');
      expect(servidor.pedidosAUpc.single.queryParameters, {'upc': '7790001234567'});
      // El nombre va escapado: los espacios y las tildes no rompen la URL.
      final pedidoPubchem = servidor.pedidosAPubchem.single;
      expect(pedidoPubchem.path, startsWith('/pubchem/compound/name/'));
      expect(pedidoPubchem.path, endsWith('/property/MolecularFormula,MolecularWeight/JSON'));
      expect(
        Uri.decodeComponent(pedidoPubchem.path),
        contains('Alcohol etílico 96%'),
      );
    });

    test('si PubChem no reconoce el nombre, queda solo con el nombre y la marca', () async {
      servidor
        ..cuerpoUpc = _upcConProducto()
        ..estadoPubchem = 404
        ..cuerpoPubchem = '{"Fault":{"Code":"PUGREST.NotFound"}}';

      final conocido = await servicio().buscar('123') as CodigoConocido;

      expect(conocido.nombre, 'Ethanol 96% 1L');
      expect(conocido.formula, isNull);
      expect(conocido.pesoMolecular, isNull);
    });

    test('si PubChem falla, no se pierde lo que ya se sabe', () async {
      servidor
        ..cuerpoUpc = _upcConProducto()
        ..estadoPubchem = 500
        ..cuerpoPubchem = 'error';

      final resultado = await servicio().buscar('123');

      expect(resultado, isA<CodigoConocido>());
      expect((resultado as CodigoConocido).nombre, 'Ethanol 96% 1L');
    });

    test('una marca vacía queda sin marca', () async {
      servidor.cuerpoUpc = _upcConProducto(brand: '  ');

      final conocido = await servicio().buscar('123') as CodigoConocido;

      expect(conocido.marca, isNull);
    });

    test('si UPCitemdb no conoce el código es "sin resultado", sin aviso', () async {
      servidor.cuerpoUpc = _upcSinProductos;

      final resultado = await servicio().buscar('123');

      expect(resultado, isA<CodigoSinResultado>());
      expect((resultado as CodigoSinResultado).aviso, isNull);
      expect(servidor.pedidosAPubchem, isEmpty);
    });

    test('un código inválido (400) también es "sin resultado"', () async {
      servidor
        ..estadoUpc = 400
        ..cuerpoUpc = '{"code":"INVALID_UPC"}';

      final resultado = await servicio().buscar('abc');

      expect((resultado as CodigoSinResultado).aviso, isNull);
    });

    test('un código vacío no consulta nada', () async {
      final resultado = await servicio().buscar('   ');

      expect(resultado, isA<CodigoSinResultado>());
      expect(servidor.pedidos, isEmpty);
    });
  });

  group('cuando internet falla', () {
    Future<String?> avisoDe(BarcodeService s) async {
      final resultado = await s.buscar('123');
      expect(resultado, isA<CodigoSinResultado>());
      return (resultado as CodigoSinResultado).aviso;
    }

    test('el límite de consultas (429) se avisa', () async {
      servidor.estadoUpc = 429;
      servidor.cuerpoUpc = '{"code":"EXCEED_LIMIT"}';

      expect(await avisoDe(servicio()), BarcodeService.avisoLimite);
    });

    test('un error del servidor se avisa', () async {
      servidor.estadoUpc = 500;
      servidor.cuerpoUpc = 'error';

      expect(await avisoDe(servicio()), BarcodeService.avisoError);
    });

    test('una respuesta que no se entiende se avisa', () async {
      servidor.cuerpoUpc = 'esto no es json';

      expect(await avisoDe(servicio()), BarcodeService.avisoError);
    });

    test('sin conexión se avisa', () async {
      final puerto = servidor.puerto;
      await servidor.cerrar();

      final servicioSinRed = BarcodeService(
        upcUrlBase: 'http://127.0.0.1:$puerto/upc',
        pubchemUrlBase: 'http://127.0.0.1:$puerto/pubchem',
        tiempoMaximo: const Duration(seconds: 2),
      );

      expect(await avisoDe(servicioSinRed), BarcodeService.avisoSinConexion);
    });

    test('si el servidor tarda más del tiempo máximo, se avisa', () async {
      servidor
        ..demoraUpc = const Duration(seconds: 2)
        ..cuerpoUpc = _upcConProducto();

      final aviso = await avisoDe(
        servicio(tiempoMaximo: const Duration(milliseconds: 300)),
      );

      expect(aviso, BarcodeService.avisoSinConexion);
    });

    test('un fallo de internet no impide que se encuentre un insumo propio', () async {
      servidor.estadoUpc = 500;
      final insumos = [_insumo('p1', 'Etanol', codigo: '123')];

      final resultado = await servicio().buscar('123', insumos: insumos);

      expect(resultado, isA<CodigoEnInventario>());
    });
  });

  group('lectura de las respuestas', () {
    test('UPCitemdb: sin título no hay producto', () {
      expect(
        BarcodeService.parsearUpcitemdb(
          '{"items":[{"title":"  ","brand":"Merck"}]}',
        ),
        isNull,
      );
    });

    test('PubChem: el peso puede venir como número', () {
      final datos = BarcodeService.parsearPubchem(_pubchem(peso: 46.07));

      expect(datos?.pesoMolecular, 46.07);
    });

    test('PubChem: sin fórmula ni peso no hay datos', () {
      expect(
        BarcodeService.parsearPubchem(
          '{"PropertyTable":{"Properties":[{"CID":1}]}}',
        ),
        isNull,
      );
    });

    test('PubChem: con solo la fórmula alcanza', () {
      final datos = BarcodeService.parsearPubchem(
        '{"PropertyTable":{"Properties":[{"MolecularFormula":"H2O"}]}}',
      );

      expect(datos?.formula, 'H2O');
      expect(datos?.pesoMolecular, isNull);
    });
  });
}
