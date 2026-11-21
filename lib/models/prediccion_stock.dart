/// El primer trabajo práctico para el que no alcanza el stock de un insumo.
class TpSinCobertura {
  const TpSinCobertura({required this.nombre, required this.fecha});

  final String nombre;
  final DateTime fecha;
}

/// Qué se espera de un insumo hasta la próxima compra institucional. Lo arma
/// `StockPredictionService`; no se guarda en Firestore.
///
/// Mira el insumo por dos caminos que NO se suman, porque el consumo pasado ya
/// incluye los trabajos prácticos anteriores y se contaría doble:
/// - **El ritmo:** a qué velocidad se viene consumiendo ([consumoDiario],
///   [diasRestantes], [fechaAgotamiento], [seAgotaAntesDeLaCompra]).
/// - **El plan:** lo que piden los trabajos prácticos ya planificados
///   ([demandaPlanificada], [trabajosPracticos], [primerTpSinCobertura]).
class PrediccionStock {
  const PrediccionStock({
    required this.productoId,
    required this.productoNombre,
    required this.stock,
    this.consumoDiario = 0,
    this.diasRestantes,
    this.fechaAgotamiento,
    this.seAgotaAntesDeLaCompra = false,
    this.demandaPlanificada = 0,
    this.trabajosPracticos = const [],
    this.primerTpSinCobertura,
  });

  final String productoId;
  final String productoNombre;

  /// Stock actual del insumo.
  final int stock;

  /// Unidades que se consumen por día, en promedio, en el período observado.
  /// Cero si el insumo no tuvo salidas recientes (solo está en el plan).
  final double consumoDiario;

  /// Días completos que alcanza el stock al ritmo actual. Cero si ya no queda.
  /// Es null si no hay ritmo del que estimar nada.
  final int? diasRestantes;

  /// Día estimado en que se agota: hoy más [diasRestantes]. Null si no hay
  /// ritmo.
  final DateTime? fechaAgotamiento;

  /// Si, al ritmo actual, se agota antes de la próxima compra institucional
  /// (julio o diciembre). Lo que se agota antes de esa fecha ya no se puede
  /// reponer a tiempo.
  final bool seAgotaAntesDeLaCompra;

  /// Unidades que piden en total los trabajos prácticos activos planificados
  /// entre hoy y la próxima compra. Cero si ninguno lo usa.
  final double demandaPlanificada;

  /// Nombres de esos trabajos prácticos, del más próximo al más lejano.
  final List<String> trabajosPracticos;

  /// El primer trabajo práctico (por fecha) para el que, sumando lo que piden
  /// los anteriores, ya no alcanza el stock. Null si alcanza para todos.
  final TpSinCobertura? primerTpSinCobertura;

  /// Si el stock no alcanza para los trabajos prácticos planificados.
  bool get faltaParaTps => primerTpSinCobertura != null;

  /// Si hay algún motivo para avisar: se agota antes de la compra o no alcanza
  /// para un trabajo práctico.
  bool get enRiesgo => seAgotaAntesDeLaCompra || faltaParaTps;
}
