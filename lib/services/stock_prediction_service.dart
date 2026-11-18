import '../models/insumo.dart';
import '../models/movimiento_stock.dart';
import '../models/prediccion_stock.dart';

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
  /// - Un insumo sin salidas en la ventana no aparece: no hay ritmo del que
  ///   estimar nada.
  /// - Con stock cero y consumo reciente aparece con cero días.
  /// - Los movimientos de insumos que no están en [insumos] se ignoran, y los
  ///   que tienen fecha posterior a [ahora] (reloj desfasado) también.
  /// - [proximaCompra] es por defecto la próxima de [proximaVentanaDeCompra].
  ///
  /// [ahora] se puede pasar para probar; por defecto es la hora actual.
  static List<PrediccionStock> predecir({
    required Iterable<Insumo> insumos,
    required Iterable<MovimientoStock> movimientos,
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

    final predicciones = <PrediccionStock>[];
    for (final insumo in insumos) {
      final total = consumido[insumo.id] ?? 0;
      if (total <= 0) continue;

      final diasObservados = _diasObservados(
        desde: primerMovimiento[insumo.id] ?? momento,
        ahora: momento,
        ventanaDias: ventanaDias,
      );
      final consumoDiario = total / diasObservados;

      final diasRestantes =
          insumo.stock <= 0 ? 0 : (insumo.stock / consumoDiario).floor();
      final fechaAgotamiento = momento.add(Duration(days: diasRestantes));

      predicciones.add(
        PrediccionStock(
          productoId: insumo.id,
          productoNombre: insumo.nombre,
          stock: insumo.stock,
          consumoDiario: consumoDiario,
          diasRestantes: diasRestantes,
          fechaAgotamiento: fechaAgotamiento,
          seAgotaAntesDeLaCompra: fechaAgotamiento.isBefore(compra),
        ),
      );
    }

    predicciones.sort(_porUrgenciaYNombre);
    return predicciones;
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

  static int _porUrgenciaYNombre(PrediccionStock a, PrediccionStock b) {
    final porDias = a.diasRestantes.compareTo(b.diasRestantes);
    if (porDias != 0) return porDias;
    return a.productoNombre
        .toLowerCase()
        .compareTo(b.productoNombre.toLowerCase());
  }
}
