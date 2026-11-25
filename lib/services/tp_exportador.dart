import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/formatters.dart';
import '../models/insumo.dart';
import '../models/trabajo_practico.dart';
import 'exportacion_comun.dart';

/// Una línea de la lista del TP: un insumo requerido con lo que hace falta
/// para preparar la práctica.
class FilaTp {
  const FilaTp({
    required this.nombre,
    required this.cantidad,
    required this.unidad,
    required this.stock,
    required this.ubicacion,
    required this.falta,
  });

  final String nombre;

  /// Cantidad que pide el TP.
  final double cantidad;
  final String unidad;

  /// Stock disponible hoy (0 si el insumo ya no existe).
  final int stock;

  /// Vacía si el insumo ya no existe: no se inventa un lugar.
  final String ubicacion;

  /// Cuánto falta para llegar a [cantidad]; 0 si alcanza.
  final double falta;

  bool get faltaStock => falta > 0;
}

/// Arma los archivos de la lista de un trabajo práctico (CSV y PDF) para
/// prepararlo: qué insumos pide, cuánto hay y dónde está cada uno.
///
/// No toca Firestore ni la pantalla: recibe el TP, los insumos y lo que falta
/// y devuelve los bytes. Compartir o guardar es trabajo de la pantalla.
///
/// Los textos de acá son el contenido de los archivos, no de la interfaz, por
/// eso no están en AppStrings.
class TpExportador {
  const TpExportador._();

  static const String _sinUbicacion = 'Sin ubicación';
  static const String _noEncontrado = 'Insumo no encontrado';
  static const List<String> _encabezados = [
    'Ubicación',
    'Insumo',
    'Cantidad pedida',
    'Stock disponible',
    'Falta',
  ];

  static const String _separador = ExportacionComun.separadorCsv;
  static const PdfColor _azul = ExportacionComun.azul;

  /// Las filas del TP, ordenadas por ubicación (sin distinguir mayúsculas) y
  /// después por nombre, para que sirvan de recorrido por el laboratorio. Los
  /// insumos que ya no existen quedan al final.
  ///
  /// [faltantes] es lo que informa TpService: insumoId -> cantidad que falta.
  static List<FilaTp> armarFilas(
    TrabajoPractico tp,
    List<Insumo> insumos,
    Map<String, double> faltantes,
  ) {
    final porId = {for (final i in insumos) i.id: i};
    final filas = [
      for (final r in tp.insumos)
        FilaTp(
          nombre: porId[r.insumoId]?.nombre ?? _noEncontrado,
          cantidad: r.cantidad,
          unidad: r.unidad,
          stock: porId[r.insumoId]?.stock ?? 0,
          ubicacion: porId[r.insumoId]?.ubicacion.trim() ?? '',
          falta: faltantes[r.insumoId] ?? 0,
        ),
    ];
    filas.sort((a, b) {
      // Sin ubicación al final: un string vacío ordenaría primero.
      if (a.ubicacion.isEmpty != b.ubicacion.isEmpty) {
        return a.ubicacion.isEmpty ? 1 : -1;
      }
      final porLugar =
          a.ubicacion.toLowerCase().compareTo(b.ubicacion.toLowerCase());
      if (porLugar != 0) return porLugar;
      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });
    return filas;
  }

  /// "17/11/2026".
  static String formatearFecha(DateTime fecha) =>
      ExportacionComun.formatearFecha(fecha);

  /// Nombre del archivo, por ejemplo "tp-titulaciones-2026-11-20.csv". Usa la
  /// fecha del TP. El nombre del TP pierde tildes y símbolos, que dan problemas
  /// en algunos sistemas de archivos.
  static String nombreArchivo(
    String nombreTp,
    DateTime fecha,
    String extension,
  ) {
    final fechaTexto = ExportacionComun.fechaParaNombre(fecha);
    return 'tp-${_limpiar(nombreTp)}-$fechaTexto.$extension';
  }

  static String _limpiar(String texto) {
    const conTilde = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const sinTilde = 'aaaaaeeeeiiiiooooouuuunc';
    final buffer = StringBuffer();
    for (final c in texto.toLowerCase().split('')) {
      final i = conTilde.indexOf(c);
      buffer.write(i >= 0 ? sinTilde[i] : c);
    }
    var limpio = buffer
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (limpio.length > 40) {
      limpio = limpio.substring(0, 40).replaceAll(RegExp(r'-+$'), '');
    }
    return limpio.isEmpty ? 'trabajo-practico' : limpio;
  }

  static String _pedido(FilaTp f) {
    final cantidad = formatearCantidad(f.cantidad);
    return f.unidad.isEmpty ? cantidad : '$cantidad ${f.unidad}';
  }

  static String _faltaTexto(FilaTp f) =>
      f.faltaStock ? formatearCantidad(f.falta) : '-';

  static String _ubicacionTexto(FilaTp f) =>
      f.ubicacion.isEmpty ? _sinUbicacion : f.ubicacion;

  static String _docente(TrabajoPractico tp) =>
      tp.docente.isEmpty ? '-' : tp.docente;

  // CSV

  /// Texto del CSV: título, fecha, docente, una línea en blanco, encabezados
  /// y un insumo por línea. Termina cada línea con \r\n, como espera Excel.
  static String csv(TrabajoPractico tp, List<FilaTp> filas) {
    final lineas = <String>[
      ExportacionComun.campoCsv(tp.nombre),
      'Fecha: ${formatearFecha(tp.fecha)}',
      'Docente: ${tp.docente.isEmpty ? '-' : ExportacionComun.campoCsv(tp.docente)}',
      '',
      _encabezados.join(_separador),
      for (final f in filas)
        [
          ExportacionComun.campoCsv(_ubicacionTexto(f)),
          ExportacionComun.campoCsv(f.nombre),
          ExportacionComun.campoCsv(_pedido(f)),
          f.stock.toString(),
          _faltaTexto(f),
        ].join(_separador),
    ];
    return '${lineas.join('\r\n')}\r\n';
  }

  /// Bytes del CSV en UTF-8 con BOM, para que Excel muestre bien las tildes.
  static Uint8List csvBytes(TrabajoPractico tp, List<FilaTp> filas) {
    return ExportacionComun.bytesCsv(csv(tp, filas));
  }

  // PDF

  /// Bytes del PDF: título con el nombre del TP, fecha y docente, y una tabla
  /// por ubicación (en el orden de [filas]) para ir recorriendo el laboratorio.
  static Future<Uint8List> pdf(TrabajoPractico tp, List<FilaTp> filas) async {
    final documento = pw.Document(title: tp.nombre);

    // Agrupa filas contiguas con la misma ubicación (ya vienen ordenadas).
    final grupos = <String, List<FilaTp>>{};
    for (final f in filas) {
      grupos.putIfAbsent(_ubicacionTexto(f), () => []).add(f);
    }

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
            tp.nombre,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: _azul,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Fecha: ${formatearFecha(tp.fecha)}  |  Docente: ${_docente(tp)}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          for (final e in grupos.entries) ...[
            pw.Text(
              e.key,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: _azul,
              ),
            ),
            pw.SizedBox(height: 4),
            _tabla(e.value),
            pw.SizedBox(height: 14),
          ],
        ],
      ),
    );

    return documento.save();
  }

  static pw.Widget _tabla(List<FilaTp> filas) {
    return pw.TableHelper.fromTextArray(
      headers: const ['Insumo', 'Cantidad pedida', 'Stock disponible', 'Falta'],
      data: [
        for (final f in filas)
          [f.nombre, _pedido(f), f.stock.toString(), _faltaTexto(f)],
      ],
      headerStyle: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: _azul),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1.4),
        2: const pw.FlexColumnWidth(1.4),
        3: const pw.FlexColumnWidth(1),
      },
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey300),
        bottom: pw.BorderSide(color: PdfColors.grey300),
      ),
    );
  }
}
