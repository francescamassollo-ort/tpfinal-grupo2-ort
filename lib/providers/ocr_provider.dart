import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../services/lector_mlkit.dart';
import '../services/ocr_service.dart';

/// Saca una foto con la cámara y devuelve dónde quedó guardada, o null si la
/// persona cancela. Puede lanzar una excepción si no hay permiso de cámara.
typedef CapturadorDeFoto = Future<String?> Function();

// El servicio que lee etiquetas. Se pide por acá, y no con OcrService()
// directo, para poder reemplazarlo por uno falso en las pruebas de las
// pantallas (que no tienen cámara ni ML Kit).
final ocrServiceProvider = Provider<OcrService>(
  (ref) => OcrService(lector: LectorMlKit()),
);

// La cámara que saca la foto de la etiqueta. Se achica la imagen: una foto de
// 12 megapíxeles tarda más en leerse y no lee mejor el texto.
final capturadorDeFotoProvider = Provider<CapturadorDeFoto>(
  (ref) => () async {
    final foto = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 2000,
      imageQuality: 85,
    );
    return foto?.path;
  },
);
