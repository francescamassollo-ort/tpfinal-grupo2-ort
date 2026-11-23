import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/insumo.dart';
import '../models/resultado_codigo.dart';

/// Averigua de qué insumo es un código de barras. Busca en capas y se queda con
/// la primera que sabe:
///
/// 1. **Nuestros insumos** (`Insumo.codigoBarras`): si el código ya está
///    cargado, no hace falta salir a internet.
/// 2. **UPCitemdb**, una base gratuita de productos comerciales (sin clave, unas
///    100 consultas por día): devuelve el nombre y la marca.
/// 3. **PubChem**, con ese nombre: completa la fórmula y el peso molecular. Solo
///    se consulta con un nombre: PubChem no busca por código de barras.
/// 4. Si nadie lo conoce, [CodigoSinResultado]: se carga a mano.
///
/// Nunca lanza por un problema de red: lo informa en [CodigoSinResultado.aviso].
/// Que un reactivo de laboratorio no esté en una base pública es lo esperable.
/// Para sumar otra fuente (por ejemplo EAN-Search, que pide token) se agrega
/// otra capa entre la 2 y la 4.
///
/// Usa dart:io en vez de un paquete de HTTP para no sumar dependencias. Al
/// escanear, el código y el nombre del producto salen a esos servicios.
class BarcodeService {
  BarcodeService({
    String? upcUrlBase,
    String? pubchemUrlBase,
    Duration tiempoMaximo = const Duration(seconds: 10),
  })  : _upcUrlBase = upcUrlBase ?? urlUpcitemdb,
        _pubchemUrlBase = pubchemUrlBase ?? urlPubchem,
        _tiempoMaximo = tiempoMaximo;

  static const String urlUpcitemdb = 'https://api.upcitemdb.com/prod/trial';
  static const String urlPubchem = 'https://pubchem.ncbi.nlm.nih.gov/rest/pug';

  static const String avisoSinConexion =
      'Sin conexión: no se pudo buscar el código en internet';
  static const String avisoLimite =
      'Se alcanzó el límite de consultas de códigos de barras por hoy';
  static const String avisoError =
      'No se pudo buscar el código en internet';

  final String _upcUrlBase;
  final String _pubchemUrlBase;
  final Duration _tiempoMaximo;

  /// Busca [codigo]. [insumos] son los que ya están cargados.
  Future<ResultadoCodigo> buscar(
    String codigo, {
    Iterable<Insumo> insumos = const [],
  }) async {
    final limpio = codigo.trim();
    if (limpio.isEmpty) return const CodigoSinResultado();

    final propio = buscarEnInventario(limpio, insumos);
    if (propio != null) return CodigoEnInventario(propio);

    final _Respuesta respuesta;
    try {
      respuesta = await _get(
        Uri.parse('$_upcUrlBase/lookup').replace(queryParameters: {'upc': limpio}),
      );
    } on _FalloDeRed catch (fallo) {
      return CodigoSinResultado(aviso: fallo.aviso);
    }

    // El código no es válido o el servicio no lo conoce: se carga a mano.
    if (respuesta.estado == 400 || respuesta.estado == 404) {
      return const CodigoSinResultado();
    }
    if (respuesta.estado == 429) {
      return const CodigoSinResultado(aviso: avisoLimite);
    }
    if (respuesta.estado != 200) {
      return const CodigoSinResultado(aviso: avisoError);
    }

    final producto = parsearUpcitemdb(respuesta.cuerpo);
    if (producto == null) {
      // Respuesta que no se entiende: no es lo mismo que "no está".
      final vacia = _esRespuestaSinProductos(respuesta.cuerpo);
      return vacia
          ? const CodigoSinResultado()
          : const CodigoSinResultado(aviso: avisoError);
    }

    final quimica = await datosQuimicos(producto.nombre);
    return CodigoConocido(
      nombre: producto.nombre,
      marca: producto.marca,
      formula: quimica?.formula,
      pesoMolecular: quimica?.pesoMolecular,
    );
  }

  /// El insumo cargado que tiene este código, o null. Compara sin espacios ni
  /// ceros a la izquierda: un código UPC-A de 12 cifras y su versión EAN-13 de
  /// 13 (que le suma un 0) son el mismo producto.
  static Insumo? buscarEnInventario(String codigo, Iterable<Insumo> insumos) {
    final buscado = _normalizar(codigo);
    if (buscado.isEmpty) return null;

    for (final insumo in insumos) {
      final propio = insumo.codigoBarras;
      if (propio != null && _normalizar(propio) == buscado) return insumo;
    }
    return null;
  }

  static String _normalizar(String codigo) {
    return codigo.replaceAll(RegExp(r'\s'), '').replaceFirst(RegExp(r'^0+'), '');
  }

  /// El primer producto de la respuesta de UPCitemdb, o null si no hay.
  static ({String nombre, String? marca})? parsearUpcitemdb(String cuerpo) {
    try {
      final json = jsonDecode(cuerpo) as Map<String, dynamic>;
      final items = json['items'] as List;
      if (items.isEmpty) return null;

      final primero = items.first as Map<String, dynamic>;
      final nombre = (primero['title'] as String?)?.trim() ?? '';
      if (nombre.isEmpty) return null;

      final marca = (primero['brand'] as String?)?.trim();
      return (nombre: nombre, marca: marca == null || marca.isEmpty ? null : marca);
    } catch (_) {
      return null;
    }
  }

  /// La fórmula y el peso molecular de la respuesta de PubChem, o null si no
  /// trae ninguno.
  static ({String? formula, double? pesoMolecular})? parsearPubchem(
    String cuerpo,
  ) {
    try {
      final json = jsonDecode(cuerpo) as Map<String, dynamic>;
      final propiedades = (json['PropertyTable']['Properties'] as List).first
          as Map<String, dynamic>;

      final formula = (propiedades['MolecularFormula'] as String?)?.trim();
      // PubChem manda el peso como texto ("46.07") y a veces como número.
      final peso = double.tryParse('${propiedades['MolecularWeight']}');

      final tieneFormula = formula != null && formula.isNotEmpty;
      if (!tieneFormula && peso == null) return null;
      return (formula: tieneFormula ? formula : null, pesoMolecular: peso);
    } catch (_) {
      return null;
    }
  }

  // Una respuesta bien formada pero con la lista de productos vacía.
  bool _esRespuestaSinProductos(String cuerpo) {
    try {
      final json = jsonDecode(cuerpo) as Map<String, dynamic>;
      return (json['items'] as List).isEmpty;
    } catch (_) {
      return false;
    }
  }

  /// La fórmula y el peso molecular que PubChem tiene para [nombreOCas]: un
  /// nombre (en inglés anda mejor) o un número CAS ("64-17-5"). Devuelve null si
  /// PubChem no lo reconoce o si falla: son datos de ayuda, nunca un error.
  Future<({String? formula, double? pesoMolecular})?> datosQuimicos(
    String nombreOCas,
  ) async {
    try {
      final respuesta = await _get(
        Uri.parse(
          '$_pubchemUrlBase/compound/name/${Uri.encodeComponent(nombreOCas)}'
          '/property/MolecularFormula,MolecularWeight/JSON',
        ),
      );
      if (respuesta.estado != 200) return null;
      return parsearPubchem(respuesta.cuerpo);
    } on _FalloDeRed {
      return null;
    }
  }

  Future<_Respuesta> _get(Uri url) async {
    final cliente = HttpClient()..connectionTimeout = _tiempoMaximo;
    try {
      final pedido = await cliente.getUrl(url).timeout(_tiempoMaximo);
      pedido.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final respuesta = await pedido.close().timeout(_tiempoMaximo);
      final cuerpo = await respuesta
          .transform(utf8.decoder)
          .join()
          .timeout(_tiempoMaximo);
      return _Respuesta(respuesta.statusCode, cuerpo);
    } on TimeoutException {
      throw const _FalloDeRed(avisoSinConexion);
    } on SocketException {
      throw const _FalloDeRed(avisoSinConexion);
    } on HttpException {
      throw const _FalloDeRed(avisoError);
    } finally {
      cliente.close(force: true);
    }
  }
}

class _Respuesta {
  const _Respuesta(this.estado, this.cuerpo);

  final int estado;
  final String cuerpo;
}

class _FalloDeRed implements Exception {
  const _FalloDeRed(this.aviso);

  final String aviso;
}
