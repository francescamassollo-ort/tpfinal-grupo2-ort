/// Configuración para hablar con Groq (modelos de lenguaje).
///
/// La clave NO está en el código: se pasa al compilar desde un archivo local
/// que git ignora:
///
///   flutter run --dart-define-from-file=env.json
///
/// Copiar `env.example.json` a `env.json` y completar la clave. Nunca se sube.
/// Ojo: la clave queda dentro de la app compilada, así que sirve para la demo
/// y no para una versión publicada (ahí hace falta un servidor intermedio).
///
/// Si no hay clave, [disponible] es falso y la app usa solo la comparación de
/// texto, sin romperse.
class GroqConfig {
  GroqConfig._();

  static const String apiKey = String.fromEnvironment('GROQ_API_KEY');

  /// Modelo que se usa. Se puede cambiar sin tocar código, por ejemplo con
  /// GROQ_MODEL=openai/gpt-oss-120b si el chico se equivoca mucho.
  static const String modelo = String.fromEnvironment(
    'GROQ_MODEL',
    defaultValue: 'openai/gpt-oss-20b',
  );

  static const String urlBase = 'https://api.groq.com/openai/v1';

  /// Cuánto se espera la respuesta antes de darla por perdida.
  static const Duration tiempoMaximo = Duration(seconds: 30);

  // Texto de relleno de env.example.json: si sigue ahí, no hay clave real.
  static const String _relleno = 'pegar-aca-la-clave-de-groq';

  /// Hay una clave cargada y se puede consultar a Groq.
  static bool get disponible => apiKey.isNotEmpty && apiKey != _relleno;
}
