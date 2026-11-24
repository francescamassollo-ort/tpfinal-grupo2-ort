import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/importacion.dart';

/// Abre un archivo de Excel (.xlsx) y devuelve sus hojas como filas de celdas
/// simples (texto, número, fecha o null). Lo que hace con ellas lo decide
/// `ImportadorDeInsumos`.
class LectorExcel {
  LectorExcel._();

  /// Lanza una excepción si el archivo no es un Excel válido.
  static List<HojaPlana> leer(Uint8List bytes) {
    final libro = Excel.decodeBytes(bytes);
    return [
      for (final entrada in libro.tables.entries)
        HojaPlana(entrada.key, [
          for (final fila in entrada.value.rows)
            [for (final celda in fila) _valor(celda?.value)],
        ]),
    ];
  }

  static Object? _valor(CellValue? valor) {
    return switch (valor) {
      null => null,
      IntCellValue(:final value) => value,
      DoubleCellValue(:final value) => value,
      BoolCellValue(:final value) => value ? 'Sí' : 'No',
      DateCellValue(:final year, :final month, :final day) =>
        DateTime(year, month, day),
      DateTimeCellValue(:final year, :final month, :final day) =>
        DateTime(year, month, day),
      // Texto, fórmulas y horas: se toman como texto.
      _ => valor.toString(),
    };
  }
}
