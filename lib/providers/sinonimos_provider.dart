import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/gemini_config.dart';
import '../core/groq_config.dart';
import '../models/hallazgo.dart';
import '../services/duplicate_detection_service.dart';
import '../services/gemini_client.dart';
import '../services/groq_client.dart';
import '../services/modelo_con_respaldo.dart';
import '../services/modelo_de_lenguaje.dart';
import '../services/synonym_detection_service.dart';
import 'hallazgos_provider.dart';
import 'insumo_providers.dart';

/// Elige con qué modelo de lenguaje hablar según las claves que haya:
///
/// - Con la de Gemini: usa Gemini. Si además hay una de Groq, queda de
///   respaldo y se usa solo cuando Gemini falla (por ejemplo, límite diario).
/// - Solo con la de Groq: usa Groq.
/// - Sin ninguna: null, y la app sigue con la comparación de texto.
ModeloDeLenguaje? elegirModeloDeLenguaje({
  required bool hayClaveDeGemini,
  required bool hayClaveDeGroq,
}) {
  if (hayClaveDeGemini) {
    return hayClaveDeGroq
        ? ModeloConRespaldo(principal: GeminiClient(), respaldo: GroqClient())
        : GeminiClient();
  }
  return hayClaveDeGroq ? GroqClient() : null;
}

// El modelo de lenguaje a usar. Es null si no hay ninguna clave cargada. En las
// pruebas se reemplaza por uno falso.
final modeloDeLenguajeProvider = Provider<ModeloDeLenguaje?>(
  (ref) => elegirModeloDeLenguaje(
    hayClaveDeGemini: GeminiConfig.disponible,
    hayClaveDeGroq: GroqConfig.disponible,
  ),
);

/// Sinónimos que sugiere el modelo de lenguaje. NO se calculan solos: cada
/// consulta gasta cuota del modelo, así que solo se hacen al llamar a [analizar].
///
/// El estado es un AsyncValue: arranca con la lista vacía (nada analizado),
/// pasa a "cargando" mientras espera y termina con el resultado o con el error.
class SinonimosNotifier extends Notifier<AsyncValue<List<Hallazgo>>> {
  @override
  AsyncValue<List<Hallazgo>> build() => const AsyncData([]);

  /// Le pide al modelo los sinónimos de los insumos actuales.
  Future<void> analizar() async {
    final modelo = ref.read(modeloDeLenguajeProvider);
    if (modelo == null) {
      _fallar('No hay una clave del modelo de lenguaje cargada');
      return;
    }

    // Se usan los insumos que ya están cargados. Leer el stream desde acá
    // podría quedarse esperando si ninguna pantalla lo está escuchando.
    final insumos = ref.read(insumosProvider).value;
    if (insumos == null) {
      _fallar('Los insumos todavía no se cargaron');
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final sugeridos = await SynonymDetectionService(modelo).buscar(insumos);

      // Se sacan los pares que la comparación de texto ya había encontrado.
      return SynonymDetectionService.sinRepetir(
        sugeridos,
        DuplicateDetectionService.detectar(insumos),
      );
    });
  }

  void _fallar(String mensaje) {
    state = AsyncError(
      ModeloDeLenguajeException(mensaje),
      StackTrace.current,
    );
  }
}

final sinonimosProvider =
    NotifierProvider<SinonimosNotifier, AsyncValue<List<Hallazgo>>>(
  SinonimosNotifier.new,
);

// Todo lo que se encontró: lo de la comparación de texto y, si se pidió, lo que
// sugirió el modelo de lenguaje a continuación.
final hallazgosCompletosProvider = Provider<AsyncValue<List<Hallazgo>>>((ref) {
  final deTexto = ref.watch(hallazgosProvider);
  final deIa = ref.watch(sinonimosProvider).value ?? const <Hallazgo>[];

  return deTexto.whenData((hallazgos) => [...hallazgos, ...deIa]);
});
