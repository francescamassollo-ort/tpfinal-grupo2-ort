import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_saver/file_saver.dart';
import 'package:share_plus/share_plus.dart';

/// Un archivo ya armado, listo para compartir o guardar.
class ArchivoGenerado {
  const ArchivoGenerado({
    required this.bytes,
    required this.nombre,
    required this.mimeType,
  });

  final Uint8List bytes;

  /// Nombre completo, con la extensión: "lista-de-compras-2026-11-17.pdf".
  final String nombre;

  /// Tipo del archivo, por ejemplo "application/pdf" o "text/csv".
  final String mimeType;
}

/// Entrega un archivo al usuario: lo comparte con otra app o lo guarda en el
/// teléfono. Es lo único que toca los plugins nativos, así la pantalla se
/// puede probar con un reemplazo que no abre nada.
class ArchivoService {
  const ArchivoService();

  /// Abre el menú de compartir del sistema (WhatsApp, mail, Drive...) con el
  /// archivo adjunto.
  ///
  /// No devuelve si se compartió o no: en Android el sistema no siempre lo
  /// informa, y alcanza con que el menú se haya abierto.
  ///
  /// En la web de escritorio el navegador no puede compartir archivos: ahí se
  /// descarga, que es lo más parecido.
  Future<void> compartir(ArchivoGenerado archivo) async {
    if (kIsWeb) {
      await guardar(archivo);
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            archivo.bytes,
            mimeType: archivo.mimeType,
            name: archivo.nombre,
          ),
        ],
        // XFile.fromData ignora el nombre en Android; sin esto el archivo
        // llegaría con un nombre genérico.
        fileNameOverrides: [archivo.nombre],
      ),
    );
  }

  /// Abre el "Guardar como" del sistema para que la persona elija la carpeta
  /// (Descargas, Drive...). Devuelve true si se guardó y false si cerró el
  /// diálogo sin elegir. Si falla, lanza una excepción.
  ///
  /// Se usa "Guardar como" y no el guardado directo de file_saver porque ese
  /// escribe en una carpeta privada de la app, que la persona no ve desde
  /// Archivos ni Descargas.
  Future<bool> guardar(ArchivoGenerado archivo) async {
    // En la web no hay "Guardar como" del sistema: el navegador descarga el
    // archivo directo a su carpeta de Descargas.
    if (kIsWeb) {
      await FileSaver.instance.saveFile(
        name: archivo.nombre,
        bytes: archivo.bytes,
        includeExtension: false,
        mimeType: MimeType.custom,
        customMimeType: archivo.mimeType,
      );
      return true;
    }
    final destino = await FileSaver.instance.saveAs(
      name: archivo.nombre,
      bytes: archivo.bytes,
      // El nombre ya trae la extensión, por eso no se agrega otra.
      includeExtension: false,
      mimeType: MimeType.custom,
      customMimeType: archivo.mimeType,
    );
    return destino != null;
  }
}
