import 'alerta.dart';

/// Qué alertas mostrar según si la persona ya las marcó como vistas.
enum EstadoVistaAlerta {
  /// Todas, vistas o no.
  todas,

  /// Solo las que todavía no marcó como vistas.
  sinVer,

  /// Solo las que ya marcó como vistas.
  vistas,
}

/// Filtros de la pantalla de Alertas. Todos son opcionales: un filtro vacío
/// deja pasar todas las alertas.
///
/// Solo cambia lo que se muestra en la lista. No afecta a la campana, que sigue
/// contando todas las alertas sin ver.
class FiltroAlertas {
  const FiltroAlertas({
    this.tipo,
    this.estado = EstadoVistaAlerta.todas,
  });

  /// Solo las alertas de este tipo. Null deja pasar todos.
  final TipoAlerta? tipo;

  final EstadoVistaAlerta estado;

  bool get estaVacio => tipo == null && estado == EstadoVistaAlerta.todas;

  /// Deja las alertas que cumplen todos los filtros puestos, en el mismo orden
  /// en que venían. [vistas] son los ids de las alertas que la persona ya
  /// marcó como vistas.
  List<Alerta> aplicar(Iterable<Alerta> alertas, Set<String> vistas) {
    return [
      for (final alerta in alertas)
        if ((tipo == null || alerta.tipo == tipo) &&
            _cumpleEstado(vistas.contains(alerta.id)))
          alerta,
    ];
  }

  bool _cumpleEstado(bool vista) => switch (estado) {
        EstadoVistaAlerta.todas => true,
        EstadoVistaAlerta.sinVer => !vista,
        EstadoVistaAlerta.vistas => vista,
      };

  @override
  bool operator ==(Object other) =>
      other is FiltroAlertas && other.tipo == tipo && other.estado == estado;

  @override
  int get hashCode => Object.hash(tipo, estado);
}
