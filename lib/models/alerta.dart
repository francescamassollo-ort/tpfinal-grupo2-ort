/// Qué tan urgente es una alerta. Define el color con que se muestra.
enum SeveridadAlerta {
  /// Hay que actuar ya: sin stock, stock bajo o vencido. Se muestra en rojo,
  /// igual que Inventario marca el stock bajo.
  critica,

  /// Hay que prestar atención: vencimiento cercano o algo que se espera que
  /// pase (predicción de stock). Se muestra en naranja, igual que Inventario
  /// marca "Por vencer".
  advertencia,
}

/// Motivo de una alerta. Cada tipo tiene su severidad.
enum TipoAlerta {
  sinStock(SeveridadAlerta.critica),
  stockBajo(SeveridadAlerta.critica),
  vencido(SeveridadAlerta.critica),
  vencimientoCercano(SeveridadAlerta.advertencia),

  /// Al ritmo de consumo actual, el insumo se agota antes de la próxima compra
  /// institucional. Es un pronóstico, por eso es advertencia y no crítica: lo
  /// crítico queda para lo que ya pasó (sin stock, vencido).
  agotamientoProximo(SeveridadAlerta.advertencia),

  /// El stock no alcanza para un trabajo práctico ya planificado.
  tpSinCobertura(SeveridadAlerta.advertencia);

  const TipoAlerta(this.severidad);

  final SeveridadAlerta severidad;
}

/// Una alerta de un insumo: por qué hay que prestarle atención.
///
/// Las alertas no se guardan: se calculan a partir del stock y las fechas del
/// insumo (y de la predicción de stock), así que aparecen y desaparecen solas
/// cuando esos datos cambian. Un mismo insumo puede tener más de una (por
/// ejemplo stock bajo y vencimiento cercano).
class Alerta {
  const Alerta({
    required this.productoId,
    required this.productoNombre,
    required this.tipo,
    this.fecha,
    this.trabajoPractico,
  });

  /// Id del insumo en la colección "insumos".
  final String productoId;
  final String productoNombre;
  final TipoAlerta tipo;

  /// Fecha que completa el mensaje de las alertas de predicción: el día en que
  /// se agota ([TipoAlerta.agotamientoProximo]) o el día del trabajo práctico
  /// que se queda sin cobertura ([TipoAlerta.tpSinCobertura]). Null en las
  /// demás.
  final DateTime? fecha;

  /// Nombre del trabajo práctico que se queda sin cobertura
  /// ([TipoAlerta.tpSinCobertura]). Null en las demás.
  final String? trabajoPractico;

  SeveridadAlerta get severidad => tipo.severidad;

  /// Identifica la alerta: un insumo no repite el mismo tipo.
  String get id => '$productoId-${tipo.name}';

  @override
  bool operator ==(Object other) =>
      other is Alerta &&
      other.productoId == productoId &&
      other.productoNombre == productoNombre &&
      other.tipo == tipo &&
      other.fecha == fecha &&
      other.trabajoPractico == trabajoPractico;

  @override
  int get hashCode =>
      Object.hash(productoId, productoNombre, tipo, fecha, trabajoPractico);
}
