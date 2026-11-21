import '../models/alerta.dart';
import '../models/insumo.dart';
import '../models/prediccion_stock.dart';

/// Genera las alertas a partir de los insumos y de la predicción de stock. No
/// habla con Firestore: recibe los datos y devuelve las alertas, por eso se
/// puede probar sola.
class AlertaService {
  AlertaService._();

  /// Alertas de [insumos] y de [predicciones], primero las críticas y después
  /// por nombre.
  ///
  /// Las reglas de los insumos son las del propio [Insumo], para que Alertas,
  /// Inventario y Lista de compras digan lo mismo:
  /// - sin stock: el stock es cero (o menos).
  /// - stock bajo: el stock está en o por debajo del umbral mínimo.
  /// - vencimiento cercano o vencido: la alarma está activada y la fecha cae
  ///   dentro de los próximos días (ver [Insumo.porVencer]).
  ///
  /// Un insumo con stock cero genera "sin stock" y no además "stock bajo".
  ///
  /// Las [predicciones] (opcionales) suman avisos de lo que se espera que
  /// pase, uno por motivo:
  /// - agotamiento próximo: al ritmo de consumo se agota antes de la próxima
  ///   compra. No se avisa si el insumo ya está sin stock, porque "sin stock"
  ///   ya lo dice.
  /// - TP sin cobertura: el stock no alcanza para un trabajo práctico
  ///   planificado. Se avisa aunque el insumo ya esté sin stock, porque dice
  ///   para qué trabajo y cuándo.
  ///
  /// [ahora] se puede pasar para probar; por defecto es la hora actual.
  static List<Alerta> generar(
    Iterable<Insumo> insumos, {
    Iterable<PrediccionStock> predicciones = const [],
    DateTime? ahora,
  }) {
    final momento = ahora ?? DateTime.now();
    final alertas = <Alerta>[];

    for (final prediccion in predicciones) {
      if (prediccion.seAgotaAntesDeLaCompra && prediccion.stock > 0) {
        alertas.add(
          Alerta(
            productoId: prediccion.productoId,
            productoNombre: prediccion.productoNombre,
            tipo: TipoAlerta.agotamientoProximo,
            fecha: prediccion.fechaAgotamiento,
          ),
        );
      }

      final tp = prediccion.primerTpSinCobertura;
      if (tp != null) {
        alertas.add(
          Alerta(
            productoId: prediccion.productoId,
            productoNombre: prediccion.productoNombre,
            tipo: TipoAlerta.tpSinCobertura,
            fecha: tp.fecha,
            trabajoPractico: tp.nombre,
          ),
        );
      }
    }

    for (final insumo in insumos) {
      void agregar(TipoAlerta tipo) {
        alertas.add(
          Alerta(
            productoId: insumo.id,
            productoNombre: insumo.nombre,
            tipo: tipo,
          ),
        );
      }

      if (insumo.stock <= 0) {
        agregar(TipoAlerta.sinStock);
      } else if (insumo.stockBajo) {
        agregar(TipoAlerta.stockBajo);
      }

      if (insumo.porVencer) {
        final vencido = insumo.fechaVencimiento!.isBefore(momento);
        agregar(vencido ? TipoAlerta.vencido : TipoAlerta.vencimientoCercano);
      }
    }

    alertas.sort(_porSeveridadYNombre);
    return alertas;
  }

  static int _porSeveridadYNombre(Alerta a, Alerta b) {
    final porSeveridad = a.severidad.index.compareTo(b.severidad.index);
    if (porSeveridad != 0) return porSeveridad;

    final porNombre =
        a.productoNombre.toLowerCase().compareTo(b.productoNombre.toLowerCase());
    if (porNombre != 0) return porNombre;

    return a.tipo.index.compareTo(b.tipo.index);
  }
}
