import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/movimiento_stock.dart';
import 'exportacion_comun.dart';

/// Arma los archivos del Historial de movimientos (CSV y PDF) a partir de los
/// movimientos y de los nombres de los insumos.
///
/// No toca Firestore ni la pantalla: recibe los datos y devuelve los bytes del
/// archivo. Por eso se puede probar sin emulador. Compartir o guardar ese
/// archivo es trabajo de la pantalla.
///
/// Los textos de acá son el contenido de los archivos, no de la interfaz, por
/// eso no están en AppStrings.
class HistorialExportador {
  const HistorialExportador._();

  static const String titulo = 'Historial de movimientos';
  static const String _vacio = 'No hay movimientos para mostrar';
  static const String _conFiltros = 'Con filtros aplicados';
  static const String insumoEliminado = 'Insumo eliminado';

  static const List<String> _encabezados = [
    'Fecha',
    'Insumo',
    'Tipo',
    'Cantidad',
    'Persona',
    'Motivo',
  ];

  /// Nombre del archivo, por ejemplo "historial-de-movimientos-2026-11-17.csv".
  static String nombreArchivo(DateTime fecha, String extension) {
    return 'historial-de-movimientos-${ExportacionComun.fechaParaNombre(fecha)}'
        '.$extension';
  }

  /// "Entrada", "Salida" o "Ajuste".
  static String tipoTexto(TipoMovimiento tipo) => switch (tipo) {
        TipoMovimiento.entrada => 'Entrada',
        TipoMovimiento.salida => 'Salida',
        TipoMovimiento.ajuste => 'Ajuste',
      };

  // Las filas, ya como texto. La cantidad es la variación del stock: una salida
  // de 10 sale como "-10". En el CSV va sin el "+" de las entradas, para que
  // Excel la lea como número; en el PDF se agrega para que se lea de un vistazo.
  static List<List<String>> _filas(
    List<MovimientoStock> movimientos,
    Map<String, String> nombres, {
    required bool signoMas,
  }) {
    return [
      for (final m in movimientos)
        [
          ExportacionComun.formatearFechaHora(m.fecha),
          // Si el insumo ya no existe el movimiento se exporta igual: el
          // historial no puede perder registros.
          nombres[m.productoId] ?? insumoEliminado,
          tipoTexto(m.tipo),
          signoMas && m.variacion > 0 ? '+${m.variacion}' : '${m.variacion}',
          m.usuarioNombre,
          m.motivo ?? '',
        ],
    ];
  }

  // CSV

  /// Texto del CSV: título, fecha, un aviso si hay filtros, una línea en blanco,
  /// encabezados y un movimiento por línea. Termina cada línea con \r\n, como
  /// espera Excel.
  ///
  /// [nombres] es insumo id -> nombre. [conFiltros] avisa que no son todos los
  /// movimientos, para que nadie tome el archivo por el historial completo.
  static String csv(
    List<MovimientoStock> movimientos,
    Map<String, String> nombres,
    DateTime fecha, {
    bool conFiltros = false,
  }) {
    final lineas = <String>[
      titulo,
      'Generado el ${ExportacionComun.formatearFecha(fecha)}',
      if (conFiltros) _conFiltros,
      '',
      _encabezados.join(ExportacionComun.separadorCsv),
      for (final fila in _filas(movimientos, nombres, signoMas: false))
        // La cantidad es un número que armamos nosotros ("-10"): no pasa por
        // campoCsv, que le pondría un apóstrofo por empezar con "-".
        [
          for (var i = 0; i < fila.length; i++)
            i == 3 ? fila[i] : ExportacionComun.campoCsv(fila[i]),
        ].join(ExportacionComun.separadorCsv),
    ];
    return '${lineas.join('\r\n')}\r\n';
  }

  /// Bytes del CSV en UTF-8 con BOM.
  static Uint8List csvBytes(
    List<MovimientoStock> movimientos,
    Map<String, String> nombres,
    DateTime fecha, {
    bool conFiltros = false,
  }) {
    return ExportacionComun.bytesCsv(
      csv(movimientos, nombres, fecha, conFiltros: conFiltros),
    );
  }

  // PDF

  /// Bytes del PDF: título, fecha, un aviso si hay filtros y una tabla con
  /// fecha, insumo, tipo, cantidad, persona y motivo. Si no entra en una hoja,
  /// sigue en la siguiente.
  ///
  /// Usa la tipografía estándar del PDF (Helvetica), que cubre las tildes y la
  /// eñe. Un símbolo fuera de ese alfabeto, como la letra griega mu, no se
  /// dibuja.
  static Future<Uint8List> pdf(
    List<MovimientoStock> movimientos,
    Map<String, String> nombres,
    DateTime fecha, {
    bool conFiltros = false,
  }) async {
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
              color: ExportacionComun.azul,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generado el ${ExportacionComun.formatearFecha(fecha)}'
            '${conFiltros ? ' · $_conFiltros' : ''}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),
          if (movimientos.isEmpty)
            pw.Text(_vacio, style: const pw.TextStyle(fontSize: 12))
          else
            _tabla(_filas(movimientos, nombres, signoMas: true)),
        ],
      ),
    );

    return documento.save();
  }

  static pw.Widget _tabla(List<List<String>> filas) {
    return pw.TableHelper.fromTextArray(
      headers: _encabezados,
      data: filas,
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: ExportacionComun.azul),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      // Las cifras a la derecha para que se lean alineadas; el resto a la
      // izquierda.
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerLeft,
        5: pw.Alignment.centerLeft,
      },
      columnWidths: {
        0: const pw.FlexColumnWidth(1.7),
        1: const pw.FlexColumnWidth(2.4),
        2: const pw.FlexColumnWidth(1.1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.8),
        5: const pw.FlexColumnWidth(2.2),
      },
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey300),
        bottom: pw.BorderSide(color: PdfColors.grey300),
      ),
    );
  }
}
