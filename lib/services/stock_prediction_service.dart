import '../models/insumo.dart';
import '../models/movimiento_stock.dart';
import '../models/prediccion_stock.dart';
import '../models/trabajo_practico.dart';

/// Estima cuándo se agota cada insumo a partir de los movimientos de stock. No
/// habla con Firestore: recibe los insumos y los movimientos y devuelve las
/// predicciones, igual que `AlertaService`, por eso se puede probar sola.
///
/// Es un promedio de consumo, no aprendizaje automático: se recalcula entero
/// cada vez que cambian los movimientos, así que mejora solo a medida que hay
/// más historial, sin entrenar nada.
class StockPredictionService {
  StockPredictionService._();

  /// Cuántos días hacia atrás se mira el consumo. Se puede cambiar al llamar
  /// (el issue habla de 30 o 60 días).
  static const int ventanaPorDefecto = 30;

  /// Mínimo de días sobre los que se reparte el consumo de un insumo.
  ///
  /// Un insumo con poco historial se mide solo sobre los días que lleva con
  /// movimientos, no sobre toda la ventana: si no, un insumo nuevo que gastó
  /// 20 unidades en 10 días parecería gastar 20 en 30, y la estimación diría
  /// que alcanza el triple de lo real. Este piso evita el otro extremo: con un
  /// solo movimiento de ayer, una división por un día daría un ritmo absurdo.
  static const int diasMinimosObservados = 7;

  // Compras institucionales: julio y diciembre. SUPUESTO: el día 1 de cada
  // mes. Falta confirmar la fecha exacta con el laboratorio.
  static const List<int> mesesDeCompra = [7, 12];
  static const int diaDeCompra = 1;

  /// Predicciones de los insumos que tienen consumo reciente, primero los que
  /// antes se agotan y, a igual cantidad de días, por nombre.
  ///
  /// - Cuenta como consumo solo la `salida`. Un ajuste negativo es una
  ///   corrección de conteo, no un gasto, y distorsionaría el ritmo.
  /// - Un insumo sin salidas en la ventana y que ningún trabajo práctico pide
  ///   no aparece: no hay de dónde estimar nada.
  /// - Con stock cero y consumo reciente aparece con cero días.
  /// - Los movimientos de insumos que no están en [insumos] se ignoran, y los
  ///   que tienen fecha posterior a [ahora] (reloj desfasado) también.
  /// - [proximaCompra] es por defecto la próxima de [proximaVentanaDeCompra].
  ///
  /// Los [trabajosPracticos] activos con fecha entre hoy y [proximaCompra] se
  /// suman al plan de cada insumo. Se asume que la cantidad que pide un TP está
  /// en la misma unidad que el stock, igual que
  /// `TpService.verificarDisponibilidad`. El plan y el ritmo son dos avisos
  /// distintos y no se suman (ver [PrediccionStock]).
  ///
  /// Van primero los insumos en riesgo, por la fecha del primer problema (el
  /// agotamiento por ritmo o el primer TP sin cobertura, el que llegue antes),
  /// y después los demás por fecha de agotamiento.
  ///
  /// [ahora] se puede pasar para probar; por defecto es la hora actual.
  static List<PrediccionStock> predecir({
    required Iterable<Insumo> insumos,
    required Iterable<MovimientoStock> movimientos,
    Iterable<TrabajoPractico> trabajosPracticos = const [],
    DateTime? ahora,
    int ventanaDias = ventanaPorDefecto,
    DateTime? proximaCompra,
  }) {
    assert(ventanaDias >= diasMinimosObservados, 'La ventana es muy corta');

    final momento = ahora ?? DateTime.now();
    final compra = proximaCompra ?? proximaVentanaDeCompra(momento);
    final inicioVentana = momento.subtract(Duration(days: ventanaDias));

    // Por insumo: lo consumido en la ventana y la fecha de su primer
    // movimiento (de cualquier tipo, aunque sea anterior a la ventana), que
    // dice desde cuándo hay historial.
    final consumido = <String, int>{};
    final primerMovimiento = <String, DateTime>{};
    for (final m in movimientos) {
      if (m.fecha.isAfter(momento)) continue;

      final primero = primerMovimiento[m.productoId];
      if (primero == null || m.fecha.isBefore(primero)) {
        primerMovimiento[m.productoId] = m.fecha;
      }

      if (m.tipo == TipoMovimiento.salida && !m.fecha.isBefore(inicioVentana)) {
        consumido[m.productoId] = (consumido[m.productoId] ?? 0) + m.cantidad.abs();
      }
    }

    final pedidos = _pedidosDeLosTps(trabajosPracticos, momento, compra);

    final predicciones = <PrediccionStock>[];
    for (final insumo in insumos) {
      final total = consumido[insumo.id] ?? 0;
      final plan = pedidos[insumo.id] ?? const <_Pedido>[];
      if (total <= 0 && plan.isEmpty) continue;

      // El ritmo: solo si hubo salidas en la ventana.
      var consumoDiario = 0.0;
      int? diasRestantes;
      DateTime? fechaAgotamiento;
      var seAgotaAntesDeLaCompra = false;
      if (total > 0) {
        final diasObservados = _diasObservados(
          desde: primerMovimiento[insumo.id] ?? momento,
          ahora: momento,
          ventanaDias: ventanaDias,
        );
        consumoDiario = total / diasObservados;
        diasRestantes =
            insumo.stock <= 0 ? 0 : (insumo.stock / consumoDiario).floor();
        fechaAgotamiento = momento.add(Duration(days: diasRestantes));
        seAgotaAntesDeLaCompra = fechaAgotamiento.isBefore(compra);
      }

      predicciones.add(
        PrediccionStock(
          productoId: insumo.id,
          productoNombre: insumo.nombre,
          stock: insumo.stock,
          consumoDiario: consumoDiario,
          diasRestantes: diasRestantes,
          fechaAgotamiento: fechaAgotamiento,
          seAgotaAntesDeLaCompra: seAgotaAntesDeLaCompra,
          demandaPlanificada: plan.fold(0.0, (suma, p) => suma + p.cantidad),
          trabajosPracticos: _nombresSinRepetir(plan),
          primerTpSinCobertura: _primerSinCobertura(plan, insumo.stock),
        ),
      );
    }

    predicciones.sort(_porUrgenciaYNombre);
    return predicciones;
  }

  // Lo que piden los trabajos prácticos activos, por insumo, ordenado por fecha
  // (y por nombre si coinciden). Solo cuentan los de hoy en adelante y antes de
  // la compra: los pasados ya consumieron lo suyo, y los posteriores se pueden
  // cubrir con esa compra.
  static Map<String, List<_Pedido>> _pedidosDeLosTps(
    Iterable<TrabajoPractico> trabajos,
    DateTime ahora,
    DateTime compra,
  ) {
    final inicioDeHoy = DateTime(ahora.year, ahora.month, ahora.day);
    final vigentes = trabajos
        .where(
          (tp) =>
              tp.activo &&
              !tp.fecha.isBefore(inicioDeHoy) &&
              tp.fecha.isBefore(compra),
        )
        .toList()
      ..sort((a, b) {
        final porFecha = a.fecha.compareTo(b.fecha);
        return porFecha != 0 ? porFecha : a.nombre.compareTo(b.nombre);
      });

    final porInsumo = <String, List<_Pedido>>{};
    for (final tp in vigentes) {
      for (final requerido in tp.insumos) {
        porInsumo
            .putIfAbsent(requerido.insumoId, () => [])
            .add(_Pedido(tp.nombre, tp.fecha, requerido.cantidad));
      }
    }
    return porInsumo;
  }

  // Recorre los pedidos en orden de fecha sumando lo que se va gastando: el
  // primero que deja el acumulado por encima del stock es el que no alcanza.
  static TpSinCobertura? _primerSinCobertura(List<_Pedido> plan, int stock) {
    var acumulado = 0.0;
    for (final pedido in plan) {
      acumulado += pedido.cantidad;
      if (acumulado > stock) {
        return TpSinCobertura(nombre: pedido.tp, fecha: pedido.fecha);
      }
    }
    return null;
  }

  static List<String> _nombresSinRepetir(List<_Pedido> plan) {
    final nombres = <String>[];
    for (final pedido in plan) {
      if (!nombres.contains(pedido.tp)) nombres.add(pedido.tp);
    }
    return nombres;
  }

  /// Próxima fecha de compra institucional posterior al día de [ahora].
  /// Si hoy es el día de compra, la próxima es la siguiente: la de hoy ya está
  /// en curso y no se puede reponer "antes de" ella.
  static DateTime proximaVentanaDeCompra(DateTime ahora) {
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final fechas = [
      for (final anio in [hoy.year, hoy.year + 1])
        for (final mes in mesesDeCompra) DateTime(anio, mes, diaDeCompra),
    ];
    return fechas.firstWhere((fecha) => fecha.isAfter(hoy));
  }

  // Días sobre los que se reparte el consumo: los que lleva el insumo con
  // historial, entre el mínimo y la ventana completa.
  static double _diasObservados({
    required DateTime desde,
    required DateTime ahora,
    required int ventanaDias,
  }) {
    final dias = ahora.difference(desde).inMinutes / (60 * 24);
    return dias
        .clamp(diasMinimosObservados.toDouble(), ventanaDias.toDouble())
        .toDouble();
  }

  // Primero los que están en riesgo, después por la fecha del primer problema
  // (los que no tienen fecha, al final) y a igual fecha por nombre.
  static int _porUrgenciaYNombre(PrediccionStock a, PrediccionStock b) {
    final porRiesgo = (b.enRiesgo ? 1 : 0) - (a.enRiesgo ? 1 : 0);
    if (porRiesgo != 0) return porRiesgo;

    final fechaA = _fechaDelProblema(a);
    final fechaB = _fechaDelProblema(b);
    if (fechaA != null && fechaB != null) {
      final porFecha = fechaA.compareTo(fechaB);
      if (porFecha != 0) return porFecha;
    } else if (fechaA != null) {
      return -1;
    } else if (fechaB != null) {
      return 1;
    }

    return a.productoNombre
        .toLowerCase()
        .compareTo(b.productoNombre.toLowerCase());
  }

  // Cuándo ocurre lo primero que hay que atender: el agotamiento por ritmo
  // (si llega antes de la compra, o si no hay ningún problema) o el primer TP
  // sin cobertura. Si solo falla el plan, la fecha de agotamiento por ritmo no
  // cuenta: está después de la compra y no es un problema.
  static DateTime? _fechaDelProblema(PrediccionStock p) {
    final fechas = <DateTime>[
      if (p.fechaAgotamiento != null && (p.seAgotaAntesDeLaCompra || !p.enRiesgo))
        p.fechaAgotamiento!,
      if (p.primerTpSinCobertura != null) p.primerTpSinCobertura!.fecha,
    ];
    if (fechas.isEmpty) return null;
    return fechas.reduce((a, b) => a.isBefore(b) ? a : b);
  }
}

// Lo que pide un trabajo práctico de un insumo, con su fecha.
class _Pedido {
  const _Pedido(this.tp, this.fecha, this.cantidad);

  final String tp;
  final DateTime fecha;
  final double cantidad;
}
