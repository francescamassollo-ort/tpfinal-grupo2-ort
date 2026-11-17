import 'package:cloud_firestore/cloud_firestore.dart';

/// Estado de seguimiento de un producto en la lista de compras.
enum EstadoCompra { pendiente, comprado, descartado }

/// Un producto en la lista de compras, con su estado de seguimiento.
///
/// No guarda el nombre ni el stock del producto: se leen del [Insumo] con
/// [productoId], así el stock que se muestra es siempre el actual.
class ListaCompra {
  const ListaCompra({
    required this.id,
    required this.productoId,
    required this.cantidadSugerida,
    required this.cantidadSolicitada,
    required this.generadaEn,
    this.estado = EstadoCompra.pendiente,
  });

  /// Cantidad mínima que se puede pedir de un producto.
  static const int cantidadMinima = 1;

  final String id;

  /// Id del insumo en la colección "insumos".
  final String productoId;

  /// Cantidad que propuso el sistema. No cambia cuando el usuario edita.
  final int cantidadSugerida;

  /// Cantidad que se va a comprar. Arranca igual a la sugerida y el usuario
  /// la puede cambiar. Puede ser mayor que el stock.
  final int cantidadSolicitada;

  final DateTime generadaEn;
  final EstadoCompra estado;

  factory ListaCompra.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    final sugerida = data['cantidadSugerida'] as int;
    return ListaCompra(
      id: snapshot.id,
      productoId: data['productoId'] as String,
      cantidadSugerida: sugerida,
      // Si el documento no trae la cantidad pedida, vale la sugerida.
      cantidadSolicitada: (data['cantidadSolicitada'] as int?) ?? sugerida,
      generadaEn: (data['generadaEn'] as Timestamp).toDate(),
      estado: EstadoCompra.values.asNameMap()[data['estado'] as String?] ??
          EstadoCompra.pendiente,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'productoId': productoId,
        'cantidadSugerida': cantidadSugerida,
        'cantidadSolicitada': cantidadSolicitada,
        'generadaEn': Timestamp.fromDate(generadaEn),
        'estado': estado.name,
      };

  ListaCompra copyWith({
    int? cantidadSolicitada,
    EstadoCompra? estado,
  }) =>
      ListaCompra(
        id: id,
        productoId: productoId,
        cantidadSugerida: cantidadSugerida,
        cantidadSolicitada: cantidadSolicitada ?? this.cantidadSolicitada,
        generadaEn: generadaEn,
        estado: estado ?? this.estado,
      );

  @override
  bool operator ==(Object other) =>
      other is ListaCompra &&
      other.id == id &&
      other.productoId == productoId &&
      other.cantidadSugerida == cantidadSugerida &&
      other.cantidadSolicitada == cantidadSolicitada &&
      other.generadaEn == generadaEn &&
      other.estado == estado;

  @override
  int get hashCode => Object.hash(
        id,
        productoId,
        cantidadSugerida,
        cantidadSolicitada,
        generadaEn,
        estado,
      );
}
