import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'ocr_service.dart';

/// Reconoce texto con ML Kit de Google. Corre en el teléfono: la foto no sale
/// del equipo ni hace falta internet. Usa el alfabeto latino (español e inglés).
class LectorMlKit implements LectorDeTexto {
  @override
  Future<String> leer(String rutaImagen) async {
    final reconocedor = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final resultado = await reconocedor.processImage(
        InputImage.fromFilePath(rutaImagen),
      );
      return resultado.text;
    } finally {
      await reconocedor.close();
    }
  }
}
