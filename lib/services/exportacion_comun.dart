import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';

/// Lo que comparten los exportadores de la app (lista de compras e historial):
/// el formato de los CSV, las fechas y el color de los PDF.
///
/// No depende de Flutter ni de Firestore, así que se puede probar sola.
class ExportacionComun {
  const ExportacionComun._();

  /// Excel en español separa las columnas con punto y coma. Con coma, abre
  /// todo el contenido en una sola columna.
  static const String separadorCsv = ';';

  /// Azul de la app (AppColors.primary), repetido acá porque este archivo no
  /// depende de Flutter.
  static const PdfColor azul = PdfColor.fromInt(0xFF004B8D);

  /// "17/11/2026".
  static String formatearFecha(DateTime fecha) {
    return '${_dos(fecha.day)}/${_dos(fecha.month)}/${fecha.year}';
  }

  /// "17/11/2026 14:32".
  static String formatearFechaHora(DateTime fecha) {
    return '${formatearFecha(fecha)} ${_dos(fecha.hour)}:${_dos(fecha.minute)}';
  }

  /// "2026-11-17", para armar el nombre de un archivo.
  static String fechaParaNombre(DateTime fecha) {
    return '${fecha.year}-${_dos(fecha.month)}-${_dos(fecha.day)}';
  }

  /// Un texto listo para ir como una celda del CSV. Un valor puede tener ';',
  /// comillas o saltos de línea: se encierra entre comillas y las comillas
  /// internas se duplican. Si empieza con un carácter que Excel toma como
  /// fórmula (=, +, -, @), se antepone un apóstrofo para que se muestre como
  /// texto y no se ejecute.
  static String campoCsv(String valor) {
    var campo = valor;
    if (campo.isNotEmpty && '=+-@\t\r'.contains(campo[0])) {
      campo = "'$campo";
    }
    if (campo.contains(RegExp(r'[;"\r\n]'))) {
      campo = '"${campo.replaceAll('"', '""')}"';
    }
    return campo;
  }

  /// Bytes de un CSV en UTF-8 con BOM. Sin el BOM, Excel no reconoce la
  /// codificación y muestra mal las tildes y la eñe.
  static Uint8List bytesCsv(String texto) {
    return Uint8List.fromList([
      0xEF, 0xBB, 0xBF, // BOM de UTF-8
      ...utf8.encode(texto),
    ]);
  }

  static String _dos(int n) => n.toString().padLeft(2, '0');
}
