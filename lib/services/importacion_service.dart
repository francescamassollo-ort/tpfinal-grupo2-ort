import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ubicacion.dart';
import 'historial_service.dart';
import 'insumo_service.dart';
import 'plan_de_importacion.dart';
import 'stock_logica.dart';
import 'ubicacion_service.dart';
import 'ubicaciones_logica.dart';
import 'usuario_actual_service.dart';

/// Guarda en Firestore lo que dice un [PlanDeImportacion]: los insumos, su
/// entrada de stock en el Historial ("Alta de insumo", igual que al darlos de
/// alta a mano) y las ubicaciones nuevas.
///
/// Se guarda por tandas: Firestore acepta como mucho 500 operaciones por tanda
/// y cada insumo con stock lleva dos (el insumo y su movimiento).
class ImportacionService {
  ImportacionService({FirebaseFirestore? db, UsuarioActualService? usuarioActual})
      : _dbOpcional = db,
        _usuarioActual = usuarioActual ?? UsuarioActualService();

  final FirebaseFirestore? _dbOpcional;
  final UsuarioActualService _usuarioActual;

  FirebaseFirestore get _db => _dbOpcional ?? FirebaseFirestore.instance;

  /// Insumos por tanda: 2 operaciones cada uno, por debajo del tope de 500.
  static const int insumosPorTanda = 200;

  /// Guarda el plan y devuelve cuántos insumos se cargaron. [alAvanzar] se llama
  /// después de cada tanda con lo cargado hasta ahora y el total.
  ///
  /// Si una tanda falla, las anteriores ya quedaron guardadas: lanza la
  /// excepción y el plan se puede volver a armar (lo ya cargado cuenta como
  /// repetido y no se duplica).
  Future<int> importar(
    PlanDeImportacion plan, {
    void Function(int cargados, int total)? alAvanzar,
  }) async {
    final usuario = await _usuarioActual.obtener();
    final ahora = DateTime.now();

    // Las ubicaciones primero: si algo falla después, la lista igual quedó
    // completa.
    for (var i = 0; i < plan.ubicacionesNuevas.length; i += 400) {
      final lote = _db.batch();
      for (final nombre in plan.ubicacionesNuevas.skip(i).take(400)) {
        final id = UbicacionesLogica.idDe(nombre);
        if (id.isEmpty) continue;
        lote.set(
          _db.collection(UbicacionService.coleccion).doc(id),
          Ubicacion(id: id, nombre: nombre).toMap(),
        );
      }
      await lote.commit();
    }

    var cargados = 0;
    for (var i = 0; i < plan.nuevos.length; i += insumosPorTanda) {
      final lote = _db.batch();
      for (final insumo in plan.nuevos.skip(i).take(insumosPorTanda)) {
        final ref = _db.collection(InsumoService.coleccion).doc();
        lote.set(ref, insumo.toMap());

        final movimiento = StockLogica.altaDeInsumo(
          insumoId: ref.id,
          stockInicial: insumo.stock,
          usuario: usuario,
          ahora: ahora,
        );
        if (movimiento != null) {
          lote.set(
            _db.collection(HistorialService.coleccion).doc(),
            movimiento.toMap(),
          );
        }
      }
      await lote.commit();
      cargados += plan.nuevos.skip(i).take(insumosPorTanda).length;
      alAvanzar?.call(cargados, plan.nuevos.length);
    }
    return cargados;
  }
}
