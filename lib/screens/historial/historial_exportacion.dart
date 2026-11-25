import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_strings.dart';
import '../../models/movimiento_stock.dart';
import '../../providers/archivo_provider.dart';
import '../../providers/historial_provider.dart';
import '../../providers/insumo_providers.dart';
import '../../services/archivo_service.dart';
import '../../services/historial_exportador.dart';
import '../../widgets/export_format_sheet.dart';
import '../../widgets/insumo_etiquetas.dart';

/// Lo que pasa al tocar Compartir o Descargar en el Historial: se elige el
/// formato, se arma el archivo y se comparte o se guarda.
///
/// Se exporta **lo que se ve**: si hay filtros puestos, solo los movimientos
/// que los cumplen, y el archivo lo aclara.
///
/// [descargar] en false comparte, en true guarda.
Future<void> exportarHistorial(
  BuildContext context,
  WidgetRef ref, {
  required bool descargar,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final movimientos = ref.read(movimientosStockProvider).value;
  final insumos = ref.read(insumosConBajasProvider).value;
  if (movimientos == null || insumos == null) return;

  final filtro = ref.read(filtroHistorialProvider);
  final visibles = filtro.aplicar(movimientos);

  // Con la lista vacía no se arma un archivo sin nada: se avisa.
  if (visibles.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.historialExportarVacio)),
    );
    return;
  }

  final formato = await elegirFormatoExportacion(
    context,
    titulo: descargar ? AppStrings.descargarComo : AppStrings.compartirComo,
  );
  // Null: se cerró el panel sin elegir. También se sale si la pantalla ya no
  // está, porque no se puede seguir usando ref ni context.
  if (formato == null || !context.mounted) return;

  final servicio = ref.read(archivoServiceProvider);
  try {
    final archivo = await _armarArchivo(
      visibles,
      // Con nombres repetidos se suma la ubicación, igual que en los
      // desplegables, para poder distinguir los insumos en el archivo.
      etiquetasDeInsumos(insumos),
      formato,
      conFiltros: !filtro.estaVacio,
    );
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
  List<MovimientoStock> movimientos,
  Map<String, String> nombres,
  FormatoExportacion formato, {
  required bool conFiltros,
}) async {
  // La fecha se toma una vez: es la misma en el contenido y en el nombre.
  final fecha = DateTime.now();
  return switch (formato) {
    FormatoExportacion.pdf => ArchivoGenerado(
      bytes: await HistorialExportador.pdf(
        movimientos,
        nombres,
        fecha,
        conFiltros: conFiltros,
      ),
      nombre: HistorialExportador.nombreArchivo(fecha, 'pdf'),
      mimeType: 'application/pdf',
    ),
    FormatoExportacion.csv => ArchivoGenerado(
      bytes: HistorialExportador.csvBytes(
        movimientos,
        nombres,
        fecha,
        conFiltros: conFiltros,
      ),
      nombre: HistorialExportador.nombreArchivo(fecha, 'csv'),
      mimeType: 'text/csv',
    ),
  };
}
