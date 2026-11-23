import 'package:cloud_firestore/cloud_firestore.dart';

/// Qué tipo de movimiento de stock es.
///
/// - [entrada]: ingresa stock (compra, alta de un insumo).
/// - [salida]: sale stock (consumo en un trabajo práctico).
/// - [ajuste]: corrección manual, por ejemplo después de contar el inventario.
enum TipoMovimiento { entrada, salida, ajuste }

/// Un movimiento de stock: quién cambió el stock de qué insumo, cuánto y cuándo.
///
/// Es un registro histórico: una vez guardado no se edita ni se borra.
///
/// **Cómo se guarda la cantidad** (esto lo tiene que respetar quien escriba
/// movimientos):
/// - [TipoMovimiento.entrada] y [TipoMovimiento.salida]: la cantidad es
///   siempre positiva y el sentido lo da el tipo. Una salida de 10 se guarda
///   como `cantidad: 10`, no como -10.
/// - [TipoMovimiento.ajuste]: la cantidad lleva signo. Positiva pone stock y
///   negativa saca.
class MovimientoStock {
  const MovimientoStock({
    required this.id,
    required this.productoId,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.tipo,
    required this.cantidad,
    required this.fecha,
    this.motivo,
  });

  final String id;

  /// Id del insumo en la colección "insumos".
  final String productoId;

  final String usuarioId;

  /// Nombre de quien hizo el movimiento, guardado junto al movimiento. Así el
  /// historial se puede mostrar sin consultar usuarios, y si la persona
  /// cambia de nombre o se va, el registro sigue diciendo quién fue.
  final String usuarioNombre;

  final TipoMovimiento tipo;
  final int cantidad;
  final DateTime fecha;

  /// Por qué se hizo, por ejemplo "Trabajo práctico 3". Puede faltar.
  final String? motivo;

  /// Cuánto cambió el stock, con signo: positivo si sumó y negativo si restó.
  ///
  /// Es lo que muestra Historial ("+19", "-10"). En entradas y salidas se usa
  /// el valor absoluto, así un dato mal guardado no invierte el sentido.
  int get variacion => switch (tipo) {
        TipoMovimiento.entrada => cantidad.abs(),
        TipoMovimiento.salida => -cantidad.abs(),
        TipoMovimiento.ajuste => cantidad,
      };

  /// Convierte un documento de Firestore (Map) en un MovimientoStock.
  /// Lanza una excepción si el documento está incompleto o tiene un tipo
  /// desconocido: quien lo lea decide qué hacer con un documento roto.
  factory MovimientoStock.fromMap(String id, Map<String, dynamic> data) {
    return MovimientoStock(
      id: id,
      productoId: data['productoId'] as String,
      usuarioId: data['usuarioId'] as String,
      usuarioNombre: data['usuarioNombre'] as String,
      tipo: TipoMovimiento.values.byName(data['tipo'] as String),
      cantidad: data['cantidad'] as int,
      fecha: (data['fecha'] as Timestamp).toDate(),
      motivo: data['motivo'] as String?,
    );
  }

  /// Convierte este movimiento en un Map listo para guardar en Firestore.
  /// El id no se incluye: es el id del documento.
  Map<String, dynamic> toMap() {
    return {
      'productoId': productoId,
      'usuarioId': usuarioId,
      'usuarioNombre': usuarioNombre,
      'tipo': tipo.name,
      'cantidad': cantidad,
      'fecha': Timestamp.fromDate(fecha),
      'motivo': motivo,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is MovimientoStock &&
      other.id == id &&
      other.productoId == productoId &&
      other.usuarioId == usuarioId &&
      other.usuarioNombre == usuarioNombre &&
      other.tipo == tipo &&
      other.cantidad == cantidad &&
      other.fecha == fecha &&
      other.motivo == motivo;

  @override
  int get hashCode => Object.hash(
        id,
        productoId,
        usuarioId,
        usuarioNombre,
        tipo,
        cantidad,
        fecha,
        motivo,
      );
}
