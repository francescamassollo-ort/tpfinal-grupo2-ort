import '../../core/app_strings.dart';
import '../../models/insumo.dart';
import '../../models/movimiento_stock.dart';
import 'movimiento_item.dart';

/// Arma lo que muestra la pantalla de Historial a partir de los movimientos
/// guardados y de los insumos. Son funciones puras: no leen Firestore.
class HistorialItems {
  HistorialItems._();

  /// Un [MovimientoItem] por movimiento, en el mismo orden en que vienen.
  ///
  /// El movimiento guarda el id del insumo y no su nombre, así que se busca en
  /// [insumos]. Si el insumo ya no existe el movimiento se muestra igual, con
  /// un nombre genérico: el historial no puede perder registros.
  static List<MovimientoItem> armar({
    required List<MovimientoStock> movimientos,
    required List<Insumo> insumos,
    required DateTime ahora,
  }) {
    final nombres = {for (final insumo in insumos) insumo.id: insumo.nombre};

    return [
      for (final m in movimientos)
        MovimientoItem(
          id: m.id,
          elementoNombre:
              nombres[m.productoId] ?? AppStrings.historialInsumoEliminado,
          usuarioNombre: m.usuarioNombre,
          fechaEtiqueta: etiquetaFecha(m.fecha, ahora),
          delta: m.variacion,
          // Según el diseño, las entradas van con el fondo resaltado.
          destacado: m.variacion > 0,
        ),
    ];
  }

  /// "Hoy 14:32", "Ayer 16:40", "22/09 09:02" o, si es de otro año,
  /// "22/09/25 09:02". [ahora] se recibe de afuera para poder probarlo.
  static String etiquetaFecha(DateTime fecha, DateTime ahora) {
    final hora = '${_dos(fecha.hour)}:${_dos(fecha.minute)}';
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final ayer = DateTime(ahora.year, ahora.month, ahora.day - 1);

    if (dia == hoy) return '${AppStrings.historialHoy} $hora';
    if (dia == ayer) return '${AppStrings.historialAyer} $hora';

    final diaMes = '${_dos(fecha.day)}/${_dos(fecha.month)}';
    final conAnio = fecha.year == ahora.year
        ? diaMes
        : '$diaMes/${_dos(fecha.year % 100)}';
    return '$conAnio $hora';
  }

  static String _dos(int n) => n.toString().padLeft(2, '0');
}
