import '../models/hallazgo.dart';
import '../models/insumo.dart';
import 'similitud_texto.dart';

/// Detecta insumos duplicados e inconsistencias en los datos. No habla con
/// Firestore: recibe los insumos y devuelve los hallazgos, por eso se puede
/// probar sola.
class DuplicateDetectionService {
  DuplicateDetectionService._();

  /// Desde este parecido entre nombres (de 0 a 1) se marca un posible
  /// duplicado. Es fácil de cambiar si da muchos falsos avisos o se pierde
  /// alguno.
  static const double umbralSimilitud = 0.85;

  /// Todos los hallazgos de [insumos]: primero los duplicados, del más seguro
  /// al menos seguro, y después las inconsistencias.
  static List<Hallazgo> detectar(Iterable<Insumo> insumos) {
    final lista = insumos.toList();
    return [
      ...detectarDuplicados(lista),
      ...detectarInconsistencias(lista),
    ];
  }

  /// Pares de insumos que parecen ser el mismo producto. Cada par aparece una
  /// sola vez. Compara todos contra todos: alcanza para el tamaño de un
  /// laboratorio.
  static List<Hallazgo> detectarDuplicados(List<Insumo> insumos) {
    final hallazgos = <Hallazgo>[];

    for (var i = 0; i < insumos.length; i++) {
      for (var j = i + 1; j < insumos.length; j++) {
        final a = insumos[i];
        final b = insumos[j];

        if (_mismoCodigoDeBarras(a, b)) {
          hallazgos.add(
            Hallazgo(
              tipo: TipoHallazgo.duplicadoExacto,
              insumoIds: [a.id, b.id],
            ),
          );
          continue;
        }

        if (!sePuedenComparar(a, b)) continue;

        final parecido = SimilitudTexto.entreNombres(a.nombre, b.nombre);
        if (parecido == 1) {
          hallazgos.add(
            Hallazgo(
              tipo: TipoHallazgo.duplicadoExacto,
              insumoIds: [a.id, b.id],
            ),
          );
        } else if (parecido >= umbralSimilitud) {
          hallazgos.add(
            Hallazgo(
              tipo: TipoHallazgo.duplicadoProbable,
              insumoIds: [a.id, b.id],
              confianza: parecido,
            ),
          );
        }
      }
    }

    hallazgos.sort((a, b) => b.confianza.compareTo(a.confianza));
    return hallazgos;
  }

  /// Insumos que ya existen y se parecen a un nombre que se está por cargar,
  /// del más parecido al menos parecido. Sirve para avisar en Alta "ya existe
  /// algo parecido". [excluirId] deja afuera al propio insumo al editarlo.
  static List<Insumo> buscarSimilares(
    String nombre,
    Iterable<Insumo> insumos, {
    String? marca,
    InsumoTipo? tipo,
    String? codigoBarras,
    String? excluirId,
  }) {
    final encontrados = <MapEntry<Insumo, double>>[];

    for (final insumo in insumos) {
      if (insumo.id == excluirId) continue;

      final mismoCodigo = !_vacio(codigoBarras) &&
          _normalizadoOVacio(insumo.codigoBarras) ==
              _normalizadoOVacio(codigoBarras);
      if (mismoCodigo) {
        encontrados.add(MapEntry(insumo, 1));
        continue;
      }

      final mismoTipo = tipo == null || insumo.tipo == tipo;
      final marcaCompatible = _vacio(marca) ||
          _vacio(insumo.marca) ||
          SimilitudTexto.normalizar(marca!) ==
              SimilitudTexto.normalizar(insumo.marca!);
      if (!mismoTipo || !marcaCompatible) continue;

      final parecido = SimilitudTexto.entreNombres(nombre, insumo.nombre);
      if (parecido >= umbralSimilitud) {
        encontrados.add(MapEntry(insumo, parecido));
      }
    }

    encontrados.sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in encontrados) e.key];
  }

  /// Datos que no pueden ser ciertos o están incompletos, uno por cada
  /// problema de cada insumo.
  static List<Hallazgo> detectarInconsistencias(Iterable<Insumo> insumos) {
    final hallazgos = <Hallazgo>[];

    for (final insumo in insumos) {
      void agregar(TipoHallazgo tipo) {
        hallazgos.add(Hallazgo(tipo: tipo, insumoIds: [insumo.id]));
      }

      if (insumo.stock < 0) agregar(TipoHallazgo.stockNegativo);
      if (insumo.umbralMinimo < 0) agregar(TipoHallazgo.umbralNegativo);

      if (insumo.alarmaVencimiento && insumo.fechaVencimiento == null) {
        agregar(TipoHallazgo.alarmaSinFecha);
      }

      final vencimiento = insumo.fechaVencimiento;
      final elaboracion = insumo.fechaElaboracion;
      if (vencimiento != null &&
          elaboracion != null &&
          vencimiento.isBefore(elaboracion)) {
        agregar(TipoHallazgo.vencimientoAnteriorAElaboracion);
      }

      if (_vacio(insumo.ubicacion)) agregar(TipoHallazgo.sinUbicacion);

      if (insumo.tipo == InsumoTipo.solucion && _vacio(insumo.concentracion)) {
        agregar(TipoHallazgo.solucionSinConcentracion);
      }
    }

    return hallazgos;
  }

  static bool _mismoCodigoDeBarras(Insumo a, Insumo b) {
    if (_vacio(a.codigoBarras) || _vacio(b.codigoBarras)) return false;
    return _normalizadoOVacio(a.codigoBarras) ==
        _normalizadoOVacio(b.codigoBarras);
  }

  /// Dos insumos se comparan por nombre solo si son del mismo tipo y, cuando
  /// los dos tienen marca, es la misma: el mismo reactivo de dos marcas se
  /// maneja como productos distintos.
  static bool sePuedenComparar(Insumo a, Insumo b) {
    if (a.tipo != b.tipo) return false;
    if (_vacio(a.marca) || _vacio(b.marca)) return true;
    return SimilitudTexto.normalizar(a.marca!) ==
        SimilitudTexto.normalizar(b.marca!);
  }

  static bool _vacio(String? texto) => texto == null || texto.trim().isEmpty;

  static String _normalizadoOVacio(String? texto) =>
      texto == null ? '' : SimilitudTexto.normalizar(texto);
}
