import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/alerta.dart';
import '../services/alerta_service.dart';
import '../services/alertas_vistas_service.dart';
import 'insumo_providers.dart';
import 'prediccion_provider.dart';
import 'trabajopractico_provider.dart';
import 'usuario_provider.dart';

// Alertas activas, calculadas a partir de los insumos y de la predicción de
// stock. Como los insumos llegan en tiempo real desde Firestore, las alertas se
// actualizan solas: aparecen cuando el stock baja y desaparecen cuando se
// repone. Lo mismo con los avisos de la predicción: se recalculan cuando hay un
// movimiento nuevo o cambia un trabajo práctico.
//
// La predicción es un extra: las alertas de los insumos no esperan por ella ni
// dependen de ella. Mientras la predicción carga, o si falla (por ejemplo, si
// no se pueden leer los movimientos), se muestran igual las de siempre.
final alertasProvider = Provider<AsyncValue<List<Alerta>>>((ref) {
  final predicciones = ref.watch(prediccionStockProvider).value ?? const [];

  return ref.watch(insumosProvider).whenData(
        (insumos) =>
            AlertaService.generar(insumos, predicciones: predicciones),
      );
});

final alertasVistasServiceProvider =
    Provider((ref) => AlertasVistasService(FirebaseFirestore.instance));

// Ids de las alertas que la persona actual ya marcó como vistas, en tiempo
// real. Es por persona: lo que marca una no cambia lo que ven las demás.
final alertasVistasProvider = StreamProvider<Set<String>>((ref) {
  final usuarioId = ref.watch(usuarioActualIdProvider);
  return ref
      .watch(alertasVistasServiceProvider)
      .watchVistas(usuarioId)
      .map((vistas) => {for (final vista in vistas) vista.alertaId});
});

// Las mismas, pero sin esperar: mientras cargan o si fallan no hay ninguna
// marcada, así que todas las alertas se ven como nuevas. Es lo más seguro:
// nunca se esconde una alerta por no poder leer las marcas.
final alertasVistasIdsProvider = Provider<Set<String>>(
  (ref) => ref.watch(alertasVistasProvider).value ?? const <String>{},
);

// Las alertas que la persona todavía no vio. Es lo que cuenta la campana.
final alertasSinVerProvider = Provider<List<Alerta>>((ref) {
  final alertas = ref.watch(alertasProvider).value ?? const <Alerta>[];
  final vistas = ref.watch(alertasVistasIdsProvider);
  return [
    for (final alerta in alertas)
      if (!vistas.contains(alerta.id)) alerta,
  ];
});

/// Acciones de la pantalla de Alertas sobre las marcas de "vista". Escriben en
/// Firestore y la pantalla se actualiza sola a través de
/// [alertasVistasProvider].
class AlertasAcciones {
  AlertasAcciones(this._ref);

  final Ref _ref;

  Future<void> marcarVista(Alerta alerta) {
    return _ref
        .read(alertasVistasServiceProvider)
        .marcar(_ref.read(usuarioActualIdProvider), alerta.id);
  }

  Future<void> marcarNoVista(Alerta alerta) {
    return _ref
        .read(alertasVistasServiceProvider)
        .desmarcar(_ref.read(usuarioActualIdProvider), alerta.id);
  }

  /// Borra las marcas de alertas que ya no existen (por ejemplo, se repuso el
  /// stock), para que si la alerta vuelve a aparecer lo haga como nueva.
  ///
  /// Solo actúa cuando TODO lo que arma las alertas terminó de cargar y sin
  /// errores. Si no, una alerta que todavía no llegó (o que no se pudo calcular
  /// porque falló la lectura de los movimientos o de los trabajos prácticos)
  /// parecería "inexistente" y se perdería una marca válida.
  Future<void> limpiarObsoletas() async {
    final insumos = _ref.read(insumosProvider);
    final prediccion = _ref.read(prediccionStockProvider);
    final vistas = _ref.read(alertasVistasProvider);
    // La predicción sigue sin los TP si no se pueden leer, pero entonces le
    // faltan alertas: no se puede saber cuáles ya no existen.
    final tps = _ref.read(tpsStreamProvider);

    bool listo(AsyncValue<Object?> valor) =>
        valor.hasValue && !valor.isLoading && !valor.hasError;
    if (!listo(insumos) || !listo(prediccion) || !listo(vistas)) return;
    if (tps.hasError) return;

    final activas = {
      for (final alerta in _ref.read(alertasProvider).value ?? const <Alerta>[])
        alerta.id,
    };
    final obsoletas = [
      for (final id in vistas.requireValue)
        if (!activas.contains(id)) id,
    ];
    if (obsoletas.isEmpty) return;

    await _ref
        .read(alertasVistasServiceProvider)
        .olvidar(_ref.read(usuarioActualIdProvider), obsoletas);
  }
}

final alertasAccionesProvider = Provider((ref) => AlertasAcciones(ref));
