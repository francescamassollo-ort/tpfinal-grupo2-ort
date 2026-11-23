import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class InsumoRequerido {
  const InsumoRequerido({
    required this.insumoId,
    required this.cantidad,
    required this.unidad,
  });

  final String insumoId;
  final double cantidad;
  final String unidad;

  factory InsumoRequerido.fromMap(Map<String, dynamic> map) => InsumoRequerido(
        insumoId: map['insumoId'] as String,
        cantidad: (map['cantidad'] as num).toDouble(),
        unidad: map['unidad'] as String,
      );

  Map<String, dynamic> toMap() =>
      {'insumoId': insumoId, 'cantidad': cantidad, 'unidad': unidad};

  @override
  bool operator ==(Object other) =>
      other is InsumoRequerido &&
      other.insumoId == insumoId &&
      other.cantidad == cantidad &&
      other.unidad == unidad;
 
  @override
  int get hashCode => Object.hash(insumoId, cantidad, unidad);
}
 
class TrabajoPractico {
  const TrabajoPractico({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.fecha,
    required this.docente,
    required this.insumos,
    this.activo = true,
  });
 
  final String id;
  final String nombre;
  final String descripcion;
  final DateTime fecha;
  final String docente;
  final List<InsumoRequerido> insumos;
  final bool activo;
 
  factory TrabajoPractico.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return TrabajoPractico(
      id: snapshot.id,
      nombre: data['nombre'] as String,
      descripcion: (data['descripcion'] as String?) ?? '',
      fecha: (data['fecha'] as Timestamp).toDate(),
      docente: (data['docente'] as String?) ?? '',
      insumos: ((data['insumos'] as List?) ?? [])
          .map((e) =>
              InsumoRequerido.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      activo: (data['activo'] as bool?) ?? true,
    );
  }
 
  Map<String, dynamic> toFirestore() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'fecha': Timestamp.fromDate(fecha),
        'docente': docente,
        'insumos': insumos.map((e) => e.toMap()).toList(),
        'activo': activo,
      };
 
  TrabajoPractico copyWith({
    String? nombre,
    String? descripcion,
    DateTime? fecha,
    String? docente,
    List<InsumoRequerido>? insumos,
    bool? activo,
  }) =>
      TrabajoPractico(
        id: id,
        nombre: nombre ?? this.nombre,
        descripcion: descripcion ?? this.descripcion,
        fecha: fecha ?? this.fecha,
        docente: docente ?? this.docente,
        insumos: insumos ?? this.insumos,
        activo: activo ?? this.activo,
      );
 
  @override
  bool operator ==(Object other) =>
      other is TrabajoPractico &&
      other.id == id &&
      other.nombre == nombre &&
      other.descripcion == descripcion &&
      other.fecha == fecha &&
      other.docente == docente &&
      other.activo == activo &&
      listEquals(other.insumos, insumos);
 
  @override
  int get hashCode =>
      Object.hash(id, nombre, descripcion, fecha, activo,docente, Object.hashAll(insumos));
}