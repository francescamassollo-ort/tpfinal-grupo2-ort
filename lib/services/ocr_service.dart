import '../models/etiqueta_leida.dart';
import 'barcode_service.dart';
import 'interprete_de_etiqueta.dart';

/// Reconoce el texto que hay en una imagen. Es una interfaz para poder cambiar
/// el reconocedor (hoy ML Kit de Google, en el teléfono y sin internet) o usar
/// uno falso en las pruebas, que no tienen cámara ni teléfono.
abstract class LectorDeTexto {
  /// El texto de la imagen guardada en [rutaImagen], con un renglón por línea.
  Future<String> leer(String rutaImagen);
}

/// No se pudo leer la etiqueta (la imagen no se pudo abrir o el reconocedor
/// falló). El mensaje se puede mostrar tal cual.
class OcrException implements Exception {
  const OcrException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

typedef BuscarQuimica = Future<({String? formula, double? pesoMolecular})?> Function(
  String nombreOCas,
);

/// Lee la etiqueta de un insumo a partir de una foto: reconoce el texto
/// ([LectorDeTexto]), lo interpreta ([InterpreteDeEtiqueta]) y, si la etiqueta
/// trae un número CAS pero no la fórmula o el peso molecular, se los pide a
/// PubChem (que sí busca por CAS).
///
/// Todo lo que devuelve es una sugerencia para completar el Alta, no un dato
/// confirmado.
class OcrService {
  OcrService({required LectorDeTexto lector, BuscarQuimica? buscarQuimica})
      : _lector = lector,
        _buscarQuimica = buscarQuimica ?? BarcodeService().datosQuimicos;

  final LectorDeTexto _lector;
  final BuscarQuimica _buscarQuimica;

  static const String mensajeNoSePudoLeer = 'No se pudo leer la etiqueta';

  Future<EtiquetaLeida> leerEtiqueta(String rutaImagen) async {
    final String texto;
    try {
      texto = await _lector.leer(rutaImagen);
    } catch (_) {
      throw const OcrException(mensajeNoSePudoLeer);
    }

    final etiqueta = InterpreteDeEtiqueta.interpretar(texto);
    final cas = etiqueta.cas;

    // Con el CAS se completa lo que falte de la parte química. Lo que la
    // etiqueta ya dice no se pisa.
    final faltaAlgo = etiqueta.formula == null || etiqueta.pesoMolecular == null;
    if (cas == null || !faltaAlgo) return etiqueta;

    final quimica = await _consultarQuimica(cas);
    if (quimica == null) return etiqueta;

    return etiqueta.copiarCon(
      formula: etiqueta.formula == null ? quimica.formula : null,
      pesoMolecular: etiqueta.pesoMolecular == null ? quimica.pesoMolecular : null,
    );
  }

  // PubChem es una ayuda: si falla, se sigue con lo que dice la etiqueta.
  Future<({String? formula, double? pesoMolecular})?> _consultarQuimica(
    String cas,
  ) async {
    try {
      return await _buscarQuimica(cas);
    } catch (_) {
      return null;
    }
  }
}
