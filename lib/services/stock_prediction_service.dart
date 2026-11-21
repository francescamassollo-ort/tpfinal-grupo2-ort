import '../models/insumo.dart';
import '../models/movimiento_stock.dart';
import '../models/prediccion_stock.dart';
import '../models/trabajo_practico.dart';
import '../models/ventana_prediccion.dart';

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
    final porInsumo = _agruparPorInsumo(movimientos);
    final pedidos = _pedidosDeLosTps(trabajosPracticos, momento, compra);

    final predicciones = <PrediccionStock>[];
    for (final insumo in insumos) {
      final ritmo = _ritmo(
        porInsumo[insumo.id] ?? const <MovimientoStock>[],
        momento,
        ventanaDias,
      );
      final plan = pedidos[insumo.id] ?? const <_Pedido>[];
      if (ritmo == null && plan.isEmpty) continue;

      // El ritmo: solo si hubo salidas en la ventana.
      var consumoDiario = 0.0;
      int? diasRestantes;
      DateTime? fechaAgotamiento;
      var seAgotaAntesDeLaCompra = false;
      if (ritmo != null) {
        consumoDiario = ritmo;
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

  /// Ventanas entre las que se elige sola (el issue habla de 30 o 60 días).
  static const List<int> ventanasCandidatas = [30, 60];

  /// Cuántos días hacia adelante se "predice el pasado" para medir el error.
  static const int horizonteDias = 14;

  /// Cuántos momentos del pasado se evalúan, uno por semana hacia atrás.
  static const int cortes = 4;
  static const int pasoDias = 7;

  /// Con menos comparaciones que estas no se anima a elegir y usa la ventana
  /// por defecto: sacar una conclusión de dos o tres casos sería adivinar.
  static const int minimoEvaluaciones = 5;

  /// Si la ventana por defecto ya se equivoca menos que esto (10 % de lo
  /// consumido), no se cambia: no se arregla lo que funciona.
  static const double errorAceptable = 0.10;

  /// Cuánto tiene que mejorar otra ventana (5 % menos de error que la de por
  /// defecto) para que valga el cambio. Evita que la elección salte de una a
  /// otra por diferencias mínimas.
  static const double mejoraMinima = 0.05;

  /// Elige entre las [ventanasCandidatas] la que mejor habría predicho el
  /// consumo reciente. Es el "aprender de sus errores" del sistema: sin
  /// entrenar un modelo, mide a cuál le fue mejor.
  ///
  /// Cómo: se viaja al pasado a [cortes] momentos (hace [horizonteDias] días,
  /// y una semana más atrás cada vez) y en cada uno se pregunta, para cada
  /// insumo, "con esta ventana, ¿cuánto habría predicho que se consumiría en
  /// los siguientes [horizonteDias] días?". Se compara con lo que realmente se
  /// consumió y se suma el error de cada ventana. Gana la que menos suma.
  ///
  /// Reglas para no adivinar:
  /// - Solo se evalúa un insumo si en ese momento ya tenía al menos
  ///   [diasMinimosObservados] días de historial.
  /// - Se saltean los casos sin ninguna señal (nada consumido ni predicho).
  /// - Con menos de [minimoEvaluaciones] comparaciones, o sin consumo real
  ///   contra qué comparar, se usa la ventana por defecto.
  /// - Si la ventana por defecto ya acierta (error de hasta [errorAceptable]),
  ///   se queda. Otra ventana solo la reemplaza si mejora al menos
  ///   [mejoraMinima].
  ///
  /// Hasta que haya semanas de historial real, va a devolver la ventana por
  /// defecto. [ahora] se puede pasar para probar.
  static VentanaPrediccion elegirVentana({
    required Iterable<MovimientoStock> movimientos,
    DateTime? ahora,
    List<int> candidatas = ventanasCandidatas,
  }) {
    assert(candidatas.isNotEmpty, 'Hace falta al menos una ventana');
    assert(
      candidatas.every((v) => v >= diasMinimosObservados),
      'Hay una ventana muy corta',
    );

    final momento = ahora ?? DateTime.now();
    final porInsumo = _agruparPorInsumo(movimientos);

    final errores = {for (final v in candidatas) v: 0.0};
    var consumoReal = 0.0;
    var evaluaciones = 0;

    for (var j = 0; j < cortes; j++) {
      final corte = momento.subtract(Duration(days: horizonteDias + j * pasoDias));
      final finDelHorizonte = corte.add(const Duration(days: horizonteDias));

      for (final movs in porInsumo.values) {
        if (!_teniaHistorial(movs, corte)) continue;

        // Lo que realmente se consumió en los días siguientes al corte.
        var real = 0;
        for (final m in movs) {
          if (m.tipo == TipoMovimiento.salida &&
              m.fecha.isAfter(corte) &&
              !m.fecha.isAfter(finDelHorizonte)) {
            real += m.cantidad.abs();
          }
        }

        final ritmos = {for (final v in candidatas) v: _ritmo(movs, corte, v)};
        if (real == 0 && ritmos.values.every((r) => r == null)) continue;

        evaluaciones++;
        consumoReal += real;
        for (final v in candidatas) {
          final predicho = (ritmos[v] ?? 0) * horizonteDias;
          errores[v] = errores[v]! + (predicho - real).abs();
        }
      }
    }

    if (evaluaciones < minimoEvaluaciones || consumoReal <= 0) {
      return VentanaPrediccion(
        ventanaDias: ventanaPorDefecto,
        elegidaPorHistorial: false,
        evaluaciones: evaluaciones,
      );
    }

    final relativos = {for (final e in errores.entries) e.key: e.value / consumoReal};

    // La de menor error; a igual error, la primera de la lista.
    var elegida = candidatas.reduce(
      (mejor, v) => relativos[v]! < relativos[mejor]! ? v : mejor,
    );

    // No se abandona la ventana por defecto si ya acierta, ni por una mejora
    // mínima.
    if (candidatas.contains(ventanaPorDefecto) && elegida != ventanaPorDefecto) {
      final delDefecto = relativos[ventanaPorDefecto]!;
      final mejora = (delDefecto - relativos[elegida]!) / delDefecto;
      if (delDefecto <= errorAceptable || mejora < mejoraMinima) {
        elegida = ventanaPorDefecto;
      }
    }

    return VentanaPrediccion(
      ventanaDias: elegida,
      elegidaPorHistorial: true,
      errorRelativoPorVentana: relativos,
      evaluaciones: evaluaciones,
    );
  }

  // Si un insumo, en el momento [corte], ya llevaba los días mínimos con
  // movimientos: sin eso no hay ritmo confiable que evaluar.
  static bool _teniaHistorial(List<MovimientoStock> movs, DateTime corte) {
    DateTime? primero;
    for (final m in movs) {
      if (m.fecha.isAfter(corte)) continue;
      if (primero == null || m.fecha.isBefore(primero)) primero = m.fecha;
    }
    return primero != null &&
        !corte.difference(primero).isNegative &&
        corte.difference(primero) >= const Duration(days: diasMinimosObservados);
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

  static Map<String, List<MovimientoStock>> _agruparPorInsumo(
    Iterable<MovimientoStock> movimientos,
  ) {
    final porInsumo = <String, List<MovimientoStock>>{};
    for (final m in movimientos) {
      porInsumo.putIfAbsent(m.productoId, () => []).add(m);
    }
    return porInsumo;
  }

  // Cuántas unidades por día consumía un insumo en el momento [en], mirando los
  // [ventanaDias] días anteriores. Solo usa los movimientos hasta [en]: sirve
  // tanto para predecir hoy como para "viajar al pasado" en el autoajuste.
  // Devuelve null si no hubo salidas en la ventana.
  //
  // La ventana es (en - ventanaDias, en]: no incluye su primer instante, así dos
  // ventanas seguidas no cuentan dos veces un movimiento justo en el borde.
  static double? _ritmo(
    List<MovimientoStock> movimientosDelInsumo,
    DateTime en,
    int ventanaDias,
  ) {
    final inicio = en.subtract(Duration(days: ventanaDias));

    // Lo consumido en la ventana, y la fecha del primer movimiento (de
    // cualquier tipo, aunque sea anterior a la ventana): dice desde cuándo hay
    // historial.
    var consumido = 0;
    DateTime? primero;
    for (final m in movimientosDelInsumo) {
      if (m.fecha.isAfter(en)) continue;
      if (primero == null || m.fecha.isBefore(primero)) primero = m.fecha;
      if (m.tipo == TipoMovimiento.salida && m.fecha.isAfter(inicio)) {
        consumido += m.cantidad.abs();
      }
    }
    if (consumido <= 0) return null;

    return consumido /
        _diasObservados(desde: primero!, ahora: en, ventanaDias: ventanaDias);
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
