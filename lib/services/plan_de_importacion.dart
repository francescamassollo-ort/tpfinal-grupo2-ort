import '../models/importacion.dart';
import '../models/insumo.dart';
import 'ubicaciones_logica.dart';

/// Qué se va a cargar de una lectura de Excel: los insumos nuevos, cuántos se
/// saltan por estar repetidos y qué ubicaciones hay que agregar a la lista.
///
/// Es puro (no toca Firestore): primero se arma el plan y se le muestra a la
/// persona, y recién cuando confirma se guarda.
class PlanDeImportacion {
  const PlanDeImportacion({
    required this.nuevos,
    required this.repetidos,
    required this.ubicacionesNuevas,
  });

  /// Los insumos listos para guardar, con la ubicación escrita como en la lista.
  final List<Insumo> nuevos;

  /// Los que se saltan: ya estaban cargados o están dos veces en el archivo.
  final int repetidos;

  /// Ubicaciones que todavía no están en la lista.
  final List<String> ubicacionesNuevas;

  /// El stock mínimo de los que no lo traen en la plantilla: con 1, los que
  /// quedan en 0 aparecen enseguida en las alertas.
  static const int stockMinimoPorDefecto = 1;

  /// Arma el plan. Un insumo se considera repetido si ya hay otro activo con el
  /// mismo nombre y la misma ubicación (sin mirar mayúsculas, tildes ni
  /// espacios), o si aparece antes en el mismo archivo.
  static PlanDeImportacion armar({
    required Iterable<InsumoImportado> importados,
    required Iterable<Insumo> existentes,
    required Iterable<String> ubicaciones,
  }) {
    final yaEstan = <String>{
      for (final i in existentes)
        if (i.activo) _clave(i.nombre, i.ubicacion),
    };
    final lugares = [...ubicaciones];
    final nuevasUbicaciones = <String>[];
    final nuevos = <Insumo>[];
    var repetidos = 0;

    for (final importado in importados) {
      // El lugar se escribe como ya está en la lista; si no está, se agrega.
      final lugar = UbicacionesLogica.canonica(importado.ubicacion, lugares);
      final clave = _clave(importado.nombre, lugar);
      if (!yaEstan.add(clave)) {
        repetidos++;
        continue;
      }
      if (!UbicacionesLogica.existe(lugar, lugares)) {
        lugares.add(lugar);
        nuevasUbicaciones.add(lugar);
      }
      nuevos.add(_aInsumo(importado, lugar));
    }

    return PlanDeImportacion(
      nuevos: nuevos,
      repetidos: repetidos,
      ubicacionesNuevas: nuevasUbicaciones,
    );
  }

  static String _clave(String nombre, String ubicacion) =>
      '${UbicacionesLogica.idDe(nombre)}|${UbicacionesLogica.idDe(ubicacion)}';

  static Insumo _aInsumo(InsumoImportado i, String ubicacion) => Insumo(
        id: '',
        nombre: i.nombre,
        tipo: InsumoTipo.comprado,
        stock: i.cantidad,
        ubicacion: ubicacion,
        umbralMinimo: i.stockMinimo ?? stockMinimoPorDefecto,
        unidad: i.unidad,
        marca: i.marca,
        pesoMolecular: i.pesoMolecular,
        categoria: i.categoria,
        formula: i.formula,
        codigoInterno: i.codigoInterno,
        otrosNombres: i.otrosNombres,
        controlado: i.controlado,
      );
}
