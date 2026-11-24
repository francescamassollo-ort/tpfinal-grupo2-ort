import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/insumo.dart';
import '../models/lista_compra.dart';

/// Único lugar de la app que habla con la colección "listaCompras".
class ListaCompraService {
  ListaCompraService(FirebaseFirestore db)
      : _ref = db.collection(coleccion).withConverter<ListaCompra>(
              fromFirestore: ListaCompra.fromFirestore,
              toFirestore: (item, _) => item.toFirestore(),
            );

  // Nombre de colección acordado: listaCompras.
  // Tiene que coincidir con las reglas de Firestore (issue #44).
  static const String coleccion = 'listaCompras';

  // Provisorio: se repone hasta este múltiplo del umbral mínimo del insumo.
  // Falta definir con el equipo que se pueda configurar al cargar el insumo.
  static const int factorReposicion = 2;

  final CollectionReference<ListaCompra> _ref;

  /// Productos pendientes de compra, en tiempo real y del más viejo al más
  /// nuevo. El estado se filtra en Dart para no exigir un índice compuesto.
  Stream<List<ListaCompra>> watchPendientes() {
    return _ref.orderBy('generadaEn').snapshots().map(
          (snap) => snap.docs
              .map((d) => d.data())
              .where((item) => item.estado == EstadoCompra.pendiente)
              .toList(),
        );
  }

  /// Agrega un producto a la lista y devuelve el id del documento. Si el
  /// producto ya está pendiente, no crea otro y devuelve el que ya existe.
  Future<String> agregar(String productoId, int cantidadSugerida) async {
    final existentes =
        await _ref.where('productoId', isEqualTo: productoId).get();
    for (final doc in existentes.docs) {
      if (doc.data().estado == EstadoCompra.pendiente) return doc.id;
    }

    final cantidad = math.max(ListaCompra.cantidadMinima, cantidadSugerida);
    final doc = _ref.doc();
    await doc.set(
      ListaCompra(
        id: doc.id,
        productoId: productoId,
        cantidadSugerida: cantidad,
        cantidadSolicitada: cantidad,
        generadaEn: DateTime.now(),
      ),
    );
    return doc.id;
  }

  /// Cambia la cantidad a comprar. Nunca baja de la cantidad mínima.
  Future<void> cambiarCantidad(String id, int cantidad) {
    return _ref.doc(id).update({
      'cantidadSolicitada': math.max(ListaCompra.cantidadMinima, cantidad),
    });
  }

  /// Marca un producto como comprado o descartado (o lo vuelve a pendiente).
  Future<void> actualizarEstado(String id, EstadoCompra estado) {
    return _ref.doc(id).update({'estado': estado.name});
  }

  /// Borra de la lista los productos con estos [ids]. A diferencia de marcar
  /// como descartado, no queda registro del ítem.
  Future<void> eliminar(Iterable<String> ids) async {
    final batch = _ref.firestore.batch();
    for (final id in ids) {
      batch.delete(_ref.doc(id));
    }
    await batch.commit();
  }

  /// Agrega a la lista los insumos con stock bajo que todavía no están
  /// pendientes. Devuelve cuántos agregó.
  Future<int> importarSugerencias(Iterable<Insumo> insumos) async {
    final pendientes =
        await _ref.where('estado', isEqualTo: EstadoCompra.pendiente.name).get();
    final yaEnLista = {for (final d in pendientes.docs) d.data().productoId};

    final nuevos = calcularSugerencias(insumos, yaEnLista);
    final batch = _ref.firestore.batch();
    for (final entry in nuevos.entries) {
      final doc = _ref.doc();
      batch.set(
        doc,
        ListaCompra(
          id: doc.id,
          productoId: entry.key,
          cantidadSugerida: entry.value,
          cantidadSolicitada: entry.value,
          generadaEn: DateTime.now(),
        ),
      );
    }
    await batch.commit();
    return nuevos.length;
  }

  /// Productos que el sistema sugiere comprar: los insumos con stock bajo que
  /// no están en [yaEnLista]. Devuelve productoId -> cantidad sugerida.
  /// No toca Firestore, por eso se puede probar sola.
  static Map<String, int> calcularSugerencias(
    Iterable<Insumo> insumos,
    Set<String> yaEnLista,
  ) {
    return {
      for (final insumo in insumos)
        if (insumo.stockBajo && !yaEnLista.contains(insumo.id))
          insumo.id: cantidadSugeridaPara(insumo),
    };
  }

  /// Cantidad para volver a [factorReposicion] veces el umbral mínimo, y nunca
  /// menos que la cantidad mínima.
  static int cantidadSugeridaPara(Insumo insumo) {
    final faltante = (insumo.umbralMinimo * factorReposicion - insumo.stock);
    return math.max(ListaCompra.cantidadMinima, faltante.ceil());
  }
}
