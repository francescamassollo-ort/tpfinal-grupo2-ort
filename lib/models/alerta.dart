/// Qué tan urgente es una alerta. Define el color con que se muestra.
enum SeveridadAlerta {
  /// Hay que actuar ya: sin stock, stock bajo o vencido. Se muestra en rojo,
  /// igual que Inventario marca el stock bajo.
  critica,

  /// Hay que prestar atención: vencimiento cercano. Se muestra en naranja,
  /// igual que Inventario marca "Por vencer".
  advertencia,
}

/// Motivo de una alerta. Cada tipo tiene su severidad.
enum TipoAlerta {
  sinStock(SeveridadAlerta.critica),
  stockBajo(SeveridadAlerta.critica),
  vencido(SeveridadAlerta.critica),
  vencimientoCercano(SeveridadAlerta.advertencia);

  const TipoAlerta(this.severidad);

  final SeveridadAlerta severidad;
}

/// Una alerta de un insumo: por qué hay que prestarle atención.
///
/// Las alertas no se guardan: se calculan a partir del stock y las fechas del
/// insumo, así que aparecen y desaparecen solas cuando esos datos cambian.
/// Un mismo insumo puede tener más de una (por ejemplo stock bajo y
/// vencimiento cercano).
class Alerta {
  const Alerta({
    required this.productoId,
    required this.productoNombre,
    required this.tipo,
  });

  /// Id del insumo en la colección "insumos".
  final String productoId;
  final String productoNombre;
  final TipoAlerta tipo;

  SeveridadAlerta get severidad => tipo.severidad;

  /// Identifica la alerta: un insumo no repite el mismo tipo.
  String get id => '$productoId-${tipo.name}';

  @override
  bool operator ==(Object other) =>
      other is Alerta &&
      other.productoId == productoId &&
      other.productoNombre == productoNombre &&
      other.tipo == tipo;

  @override
  int get hashCode => Object.hash(productoId, productoNombre, tipo);
}
