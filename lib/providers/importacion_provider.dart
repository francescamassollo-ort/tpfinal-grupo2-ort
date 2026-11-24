import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/importacion_service.dart';

/// Deja elegir un archivo de Excel y devuelve su contenido, o null si la
/// persona cancela. Se reemplaza en las pruebas (no tienen selector de
/// archivos).
typedef SelectorDeExcel = Future<Uint8List?> Function();

final selectorDeExcelProvider = Provider<SelectorDeExcel>(
  (ref) => () async {
    final archivo = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
    );
    if (archivo == null) return null;
    return archivo.xFile.readAsBytes();
  },
);

// El servicio que guarda la importación. Se pide por acá para poder
// reemplazarlo en las pruebas (el de verdad habla con Firestore).
final importacionServiceProvider =
    Provider<ImportacionService>((ref) => ImportacionService());
