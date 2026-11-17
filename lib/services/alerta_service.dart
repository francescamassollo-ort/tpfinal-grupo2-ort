import '../models/alerta.dart';
import '../models/insumo.dart';

/// Genera las alertas a partir de los insumos. No habla con Firestore: recibe
/// los insumos y devuelve las alertas, por eso se puede probar sola.
class AlertaService {
  AlertaService._();

  /// Alertas de [insumos], primero las críticas y después por nombre.
  ///
  /// Las reglas son las del propio [Insumo], para que Alertas, Inventario y
  /// Lista de compras digan lo mismo:
  /// - sin stock: el stock es cero (o menos).
  /// - stock bajo: el stock está en o por debajo del umbral mínimo.
  /// - vencimiento cercano o vencido: la alarma está activada y la fecha cae
  ///   dentro de los próximos días (ver [Insumo.porVencer]).
  ///
  /// Un insumo con stock cero genera "sin stock" y no además "stock bajo".
  /// [ahora] se puede pasar para probar; por defecto es la hora actual.
  static List<Alerta> generar(Iterable<Insumo> insumos, {DateTime? ahora}) {
    final momento = ahora ?? DateTime.now();
    final alertas = <Alerta>[];

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
