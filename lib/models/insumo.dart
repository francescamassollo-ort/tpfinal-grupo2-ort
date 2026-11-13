import 'package:cloud_firestore/cloud_firestore.dart';

enum InsumoTipo { comprado, solucion }

class Insumo {
  Insumo({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.stock,
    required this.ubicacion,
    required this.umbralMinimo,
    this.categoria,
    this.marca,
    this.cantidadPorEnvase,
    this.unidad,
    this.formula,
    this.pesoMolecular,
    this.origen,
    this.proveedor,
    this.fechaVencimiento,
    this.alarmaVencimiento = false,
    this.codigoBarras,
    this.concentracion,
    this.fechaElaboracion,
    this.materia,
    this.preparadoPor,
  });

  // Obligatorios.
  final String id;
  final String nombre;
  final InsumoTipo tipo;
  final int stock;
  final String ubicacion;
  final num umbralMinimo;

  // Opcionales (quedan null si no se cargan).
  final String? categoria;
  final String? marca;
  final num? cantidadPorEnvase;
  final String? unidad;
  final String? formula;
  final double? pesoMolecular;
  final String? origen;
  final String? proveedor;
  final DateTime? fechaVencimiento;
  final bool alarmaVencimiento;
  final String? codigoBarras;

  // Solo para soluciones preparadas.
  final String? concentracion;
  final DateTime? fechaElaboracion;
  final String? materia;
  final String? preparadoPor;

  // Regla de negocio (CLAUDE.md sección 9.8): si el stock está en o por
  // debajo del umbral, el insumo tiene que aparecer en Alertas/Compras.
  bool get stockBajo => stock <= umbralMinimo;

  // "Por vencer": tiene la alarma activada y vence dentro de 30 días o menos
  // (o ya venció). Los 30 días son provisorios, falta confirmarlo con el equipo.
  bool get porVencer {
    if (!alarmaVencimiento || fechaVencimiento == null) return false;
    final limite = DateTime.now().add(const Duration(days: 30));
    return fechaVencimiento!.isBefore(limite);
  }

  // Convierte un documento de Firestore (Map) en un Insumo de Dart.
  factory Insumo.fromMap(String id, Map<String, dynamic> data) {
    return Insumo(
      id: id,
      nombre: data['nombre'] as String,
      tipo: InsumoTipo.values.byName(data['tipo'] as String),
      stock: data['stock'] as int,
      ubicacion: data['ubicacion'] as String,
      umbralMinimo: data['umbralMinimo'] as num,
      categoria: data['categoria'] as String?,
      marca: data['marca'] as String?,
      cantidadPorEnvase: data['cantidadPorEnvase'] as num?,
      unidad: data['unidad'] as String?,
      formula: data['formula'] as String?,
      pesoMolecular: (data['pesoMolecular'] as num?)?.toDouble(),
      origen: data['origen'] as String?,
      proveedor: data['proveedor'] as String?,
      fechaVencimiento: (data['fechaVencimiento'] as Timestamp?)?.toDate(),
      alarmaVencimiento: data['alarmaVencimiento'] as bool? ?? false,
      codigoBarras: data['codigoBarras'] as String?,
      concentracion: data['concentracion'] as String?,
      fechaElaboracion: (data['fechaElaboracion'] as Timestamp?)?.toDate(),
      materia: data['materia'] as String?,
      preparadoPor: data['preparadoPor'] as String?,
    );
  }

  // Convierte este Insumo en un Map listo para guardar en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'tipo': tipo.name,
      'stock': stock,
      'ubicacion': ubicacion,
      'umbralMinimo': umbralMinimo,
      'categoria': categoria,
      'marca': marca,
      'cantidadPorEnvase': cantidadPorEnvase,
      'unidad': unidad,
      'formula': formula,
      'pesoMolecular': pesoMolecular,
      'origen': origen,
      'proveedor': proveedor,
      'fechaVencimiento':
          fechaVencimiento == null ? null : Timestamp.fromDate(fechaVencimiento!),
      'alarmaVencimiento': alarmaVencimiento,
      'codigoBarras': codigoBarras,
      'concentracion': concentracion,
      'fechaElaboracion':
          fechaElaboracion == null ? null : Timestamp.fromDate(fechaElaboracion!),
      'materia': materia,
      'preparadoPor': preparadoPor,
    };
  }
}
