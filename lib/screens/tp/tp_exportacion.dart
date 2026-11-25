import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_strings.dart';
import '../../models/trabajo_practico.dart';
import '../../providers/archivo_provider.dart';
import '../../providers/insumo_providers.dart';
import '../../providers/trabajopractico_provider.dart';
import '../../services/archivo_service.dart';
import '../../services/tp_exportador.dart';
import '../../widgets/export_format_sheet.dart';

/// Lo que pasa al tocar Compartir o Descargar en el detalle de un TP: se
/// elige el formato, se arma la lista para prepararlo y se comparte o se
/// guarda.
///
/// [descargar] en false comparte, en true guarda.
Future<void> exportarTp(
  BuildContext context,
  WidgetRef ref,
  TrabajoPractico tp, {
  required bool descargar,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final insumos = ref.read(insumosProvider).value;
  // Mientras el stock carga no se sabe qué falta: no se arma nada a medias.
  if (insumos == null) return;

  // Sin insumos no se arma un archivo vacío: se avisa.
  if (tp.insumos.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.tpExportarVacio)),
    );
    return;
  }

  final faltantes = ref.read(disponibilidadTpProvider(tp)).value?.faltantes ??
      const <String, double>{};
  final filas = TpExportador.armarFilas(tp, insumos, faltantes);

  final formato = await elegirFormatoExportacion(
    context,
    titulo: descargar ? AppStrings.descargarComo : AppStrings.compartirComo,
  );
  // Null: se cerró el panel sin elegir. También se sale si la pantalla ya no
  // está, porque no se puede seguir usando ref ni context.
  if (formato == null || !context.mounted) return;

  final servicio = ref.read(archivoServiceProvider);
  try {
    final archivo = await _armarArchivo(tp, filas, formato);
    if (descargar) {
      // Falso significa que cerró el "Guardar como" sin elegir: no se avisa
      // nada, no hubo error.
      final guardado = await servicio.guardar(archivo);
      if (guardado) {
        messenger.showSnackBar(
          const SnackBar(content: Text(AppStrings.archivoGuardado)),
        );
      }
    } else {
      // El menú de compartir ya es la confirmación: no se agrega otro aviso.
      await servicio.compartir(archivo);
    }
  } catch (error, stack) {
    // Queda en la consola para saber por qué falló el archivo.
    debugPrint('No se pudo entregar el archivo: $error\n$stack');
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          descargar
              ? AppStrings.archivoErrorGuardar
              : AppStrings.archivoErrorCompartir,
        ),
      ),
    );
  }
}

Future<ArchivoGenerado> _armarArchivo(
  TrabajoPractico tp,
  List<FilaTp> filas,
  FormatoExportacion formato,
) async {
  return switch (formato) {
    FormatoExportacion.pdf => ArchivoGenerado(
      bytes: await TpExportador.pdf(tp, filas),
      nombre: TpExportador.nombreArchivo(tp.nombre, tp.fecha, 'pdf'),
      mimeType: 'application/pdf',
    ),
    FormatoExportacion.csv => ArchivoGenerado(
      bytes: TpExportador.csvBytes(tp, filas),
      nombre: TpExportador.nombreArchivo(tp.nombre, tp.fecha, 'csv'),
      mimeType: 'text/csv',
    ),
  };
}
