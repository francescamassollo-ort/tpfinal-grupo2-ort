import 'dart:convert';

import '../models/hallazgo.dart';
import '../models/insumo.dart';
import 'duplicate_detection_service.dart';
import 'modelo_de_lenguaje.dart';
import 'similitud_texto.dart';

/// Busca insumos que son el mismo producto con distinto nombre ("etanol" y
/// "alcohol etílico"), algo que comparar letras no puede ver.
///
/// Le manda a un modelo de lenguaje solo los NOMBRES de los insumos, nunca el
/// stock, las ubicaciones ni datos de personas. El modelo sugiere grupos y
/// después cada sugerencia se valida con las mismas reglas que la comparación
/// de texto: el modelo propone y las reglas deciden.
class SynonymDetectionService {
  SynonymDetectionService(this._modelo);

  final ModeloDeLenguaje _modelo;

  /// Máximo de insumos por consulta. Con el límite de tokens por minuto del
  /// plan gratuito, unos 250 nombres entran cómodos.
  static const int maxInsumosPorConsulta = 250;

  /// El modelo no da un porcentaje de seguridad, así que a sus sugerencias se
  /// les asigna una confianza fija, menor que la de un duplicado exacto.
  static const double confianzaDelModelo = 0.8;

  static const String instrucciones =
      'Sos un asistente de un laboratorio de biotecnologia. Recibis una lista '
      'de insumos, una linea por insumo con la forma "id: nombre". Devolve '
      'SOLO un JSON con la forma {"grupos": [["e1","e2"], ["e3","e4"]]}, donde '
      'cada grupo reune los ids de insumos que son EL MISMO producto escrito '
      'de distinta forma: sinonimos, nombre comun contra nombre quimico, orden '
      'de las palabras o abreviaturas. Dos productos con distinta '
      'concentracion o con un numero distinto NO son el mismo. No incluyas '
      'grupos de un solo id. Si no hay ninguno, devolve {"grupos": []}.';

  /// Pares de insumos que el modelo cree que son el mismo producto y que
  /// cumplen las reglas. Si el modelo falla, lanza una
  /// [ModeloDeLenguajeException].
  Future<List<Hallazgo>> buscar(Iterable<Insumo> insumos) async {
    final hallazgos = <Hallazgo>[];

    for (final tanda in _tandas(insumos.toList())) {
      if (tanda.length < 2) continue;

      final respuesta = await _modelo.responder(
        instrucciones: instrucciones,
        consulta: _armarConsulta(tanda),
      );
      hallazgos.addAll(_validar(_leerGrupos(respuesta), tanda));
    }

    return hallazgos;
  }

  /// Saca de [sugeridos] los pares que [yaDetectados] ya tiene, para no
  /// mostrar dos veces el mismo duplicado.
  static List<Hallazgo> sinRepetir(
    Iterable<Hallazgo> sugeridos,
    Iterable<Hallazgo> yaDetectados,
  ) {
    final conocidos = {for (final h in yaDetectados) _clave(h.insumoIds)};
    return [
      for (final h in sugeridos)
        if (!conocidos.contains(_clave(h.insumoIds))) h,
    ];
  }

  static String _clave(List<String> ids) => (List.of(ids)..sort()).join('|');

  // Los insumos de distinto tipo no se comparan nunca, así que se separan por
  // tipo y, si hace falta, se parten en tandas del tamaño máximo.
  static List<List<Insumo>> _tandas(List<Insumo> insumos) {
    final tandas = <List<Insumo>>[];
    for (final tipo in InsumoTipo.values) {
      final deEsteTipo = insumos.where((i) => i.tipo == tipo).toList();
      for (var i = 0; i < deEsteTipo.length; i += maxInsumosPorConsulta) {
        final fin = i + maxInsumosPorConsulta;
        tandas.add(
          deEsteTipo.sublist(i, fin > deEsteTipo.length ? deEsteTipo.length : fin),
        );
      }
    }
    return tandas;
  }

  // Cada insumo va con un id corto ("e1", "e2") en vez del de Firestore: se
  // gastan menos tokens y no se mandan ids de la base.
  static String _armarConsulta(List<Insumo> tanda) {
    return [
      for (var i = 0; i < tanda.length; i++) 'e${i + 1}: ${tanda[i].nombre}',
    ].join('\n');
  }

  static List<List<String>> _leerGrupos(String respuesta) {
    try {
      final inicio = respuesta.indexOf('{');
      final fin = respuesta.lastIndexOf('}');
      final json = jsonDecode(respuesta.substring(inicio, fin + 1)) as Map;
      return [
        for (final grupo in json['grupos'] as List)
          [for (final id in grupo as List) id as String],
      ];
    } catch (_) {
      throw const ModeloDeLenguajeException(
        'La respuesta de la IA no tiene el formato esperado',
      );
    }
  }

  static List<Hallazgo> _validar(List<List<String>> grupos, List<Insumo> tanda) {
    final porId = {
      for (var i = 0; i < tanda.length; i++) 'e${i + 1}': tanda[i],
    };
    final vistos = <String>{};
    final hallazgos = <Hallazgo>[];

    for (final grupo in grupos) {
      // Ids que existen, sin repetir.
      final insumos = {
        for (final id in grupo)
          if (porId[id] != null) id: porId[id]!,
      }.values.toList();

      for (var i = 0; i < insumos.length; i++) {
        for (var j = i + 1; j < insumos.length; j++) {
          final a = insumos[i];
          final b = insumos[j];

          if (!DuplicateDetectionService.sePuedenComparar(a, b)) continue;
          if (!SimilitudTexto.mismosNumeros(a.nombre, b.nombre)) continue;
          if (!vistos.add(_clave([a.id, b.id]))) continue;

          hallazgos.add(
            Hallazgo(
              tipo: TipoHallazgo.sinonimoProbable,
              insumoIds: [a.id, b.id],
              confianza: confianzaDelModelo,
            ),
          );
        }
      }
    }

    return hallazgos;
  }
}
