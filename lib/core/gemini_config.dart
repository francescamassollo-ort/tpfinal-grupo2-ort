/// Configuración para hablar con Gemini (modelos de lenguaje de Google).
///
/// La clave NO está en el código: se pasa al compilar desde un archivo local
/// que git ignora, el mismo `env.json` que usa Groq:
///
///   flutter run --dart-define-from-file=env.json
///
/// Copiar `env.example.json` a `env.json` y completar `GEMINI_API_KEY` con una
/// clave de Google AI Studio. Nunca se sube. Ojo: la clave queda dentro de la
/// app compilada, así que sirve para la demo y no para una versión publicada
/// (ahí hace falta un servidor intermedio).
///
/// Si no hay clave, [disponible] es falso y la app prueba con otro proveedor o,
/// si no hay ninguno, usa solo la comparación de texto.
class GeminiConfig {
  GeminiConfig._();

  static const String apiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Modelo que se usa. Se puede cambiar sin tocar código, por ejemplo con
  /// GEMINI_MODEL=gemini-3.1-flash-lite si el límite diario no alcanza. Los
  /// nombres disponibles para una clave se ven en Google AI Studio.
  static const String modelo = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.5-flash-lite',
  );

  static const String urlBase =
      'https://generativelanguage.googleapis.com/v1beta';

  /// Cuánto se espera la respuesta antes de darla por perdida.
  static const Duration tiempoMaximo = Duration(seconds: 30);

  // Texto de relleno de env.example.json: si sigue ahí, no hay clave real.
  static const String _relleno = 'pegar-aca-la-clave-de-gemini';

  /// Hay una clave cargada y se puede consultar a Gemini.
  static bool get disponible => apiKey.isNotEmpty && apiKey != _relleno;
}
