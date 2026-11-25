import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../screens/compras/item_compra.dart';
import 'exportacion_comun.dart';

/// Arma los archivos de la lista de compras (CSV y PDF) a partir de sus ítems.
///
/// No toca Firestore ni la pantalla: recibe los ítems y la fecha y devuelve
/// los bytes del archivo. Por eso se puede probar sin emulador. Compartir o
/// guardar ese archivo es trabajo de la pantalla.
///
/// Los textos de acá son el contenido de los archivos, no de la interfaz, por
/// eso no están en AppStrings.
class ListaCompraExportador {
  const ListaCompraExportador._();

  static const String titulo = 'Lista de compras';
  static const String _vacia = 'La lista de compras está vacía';
  static const List<String> _encabezados = [
    'Insumo',
    'Stock actual',
    'Cantidad a comprar',
  ];

  static const String _separador = ExportacionComun.separadorCsv;
  static const PdfColor _azul = ExportacionComun.azul;

  /// "17/11/2026".
  static String formatearFecha(DateTime fecha) =>
      ExportacionComun.formatearFecha(fecha);

  /// Nombre del archivo, por ejemplo "lista-de-compras-2026-11-17.csv".
  static String nombreArchivo(DateTime fecha, String extension) {
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    return 'lista-de-compras-${fecha.year}-$mes-$dia.$extension';
  }

  // CSV

  /// Texto del CSV: título, fecha, una línea en blanco, encabezados y un
  /// ítem por línea. Termina cada línea con \r\n, como espera Excel.
  static String csv(List<ItemCompra> items, DateTime fecha) {
    final lineas = <String>[
      titulo,
      'Generada el ${formatearFecha(fecha)}',
      '',
      _encabezados.join(_separador),
      for (final item in items)
        [
          ExportacionComun.campoCsv(item.nombre),
          item.stock.toString(),
          item.cantidadSolicitada.toString(),
        ].join(_separador),
    ];
    return '${lineas.join('\r\n')}\r\n';
  }

  /// Bytes del CSV en UTF-8 con BOM. Sin el BOM, Excel no reconoce la
  /// codificación y muestra mal las tildes y la eñe.
  static Uint8List csvBytes(List<ItemCompra> items, DateTime fecha) {
    return ExportacionComun.bytesCsv(csv(items, fecha));
  }

  // PDF

  /// Bytes del PDF: título, fecha y una tabla con insumo, stock actual y
  /// cantidad a comprar. Si no entra en una hoja, sigue en la siguiente.
  ///
  /// Usa la tipografía estándar del PDF (Helvetica), que cubre las tildes y la
  /// eñe. Un símbolo fuera de ese alfabeto, como la letra griega mu, no se
  /// dibuja.
  static Future<Uint8List> pdf(List<ItemCompra> items, DateTime fecha) async {
    final documento = pw.Document(title: titulo);

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        // El tope por defecto es 20 páginas: una lista larga (por ejemplo tras
        // una importación grande) fallaba con TooManyPagesException.
        maxPages: 2000,
        margin: const pw.EdgeInsets.all(40),
        footer: (contexto) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${contexto.pageNumber} de ${contexto.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        build: (contexto) => [
          pw.Text(
            titulo,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: _azul,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generada el ${formatearFecha(fecha)}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),
          if (items.isEmpty)
            pw.Text(_vacia, style: const pw.TextStyle(fontSize: 12))
          else
            _tabla(items),
        ],
      ),
    );

    return documento.save();
  }

  static pw.Widget _tabla(List<ItemCompra> items) {
    return pw.TableHelper.fromTextArray(
      headers: _encabezados,
      data: [
        for (final item in items)
          [item.nombre, item.stock.toString(), item.cantidadSolicitada.toString()],
      ],
      headerStyle: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: _azul),
      cellStyle: const pw.TextStyle(fontSize: 11),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      // La primera columna a la izquierda; las cifras a la derecha para que
      // se lean alineadas.
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
      },
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.4),
      },
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey300),
        bottom: pw.BorderSide(color: PdfColors.grey300),
      ),
    );
  }
}
