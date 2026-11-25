import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_strings.dart';
import '../../providers/archivo_provider.dart';
import '../../providers/lista_compra_provider.dart';
import '../../services/archivo_service.dart';
import '../../services/lista_compra_exportador.dart';
import '../../widgets/export_format_sheet.dart';
import 'item_compra.dart';

/// Lo que pasa al tocar Compartir o Descargar en la lista de compras:
/// se elige el formato, se arma el archivo y se comparte o se guarda.
///
/// [descargar] en false comparte, en true guarda.
Future<void> exportarListaCompras(
  BuildContext context,
  WidgetRef ref, {
  required bool descargar,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final items = ref.read(itemsCompraProvider).value;
  if (items == null) return;

  // Con la lista vacía no se arma un archivo sin nada: se avisa.
  if (items.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.comprasExportarVacia)),
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
    final archivo = await _armarArchivo(items, formato);
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
  List<ItemCompra> items,
  FormatoExportacion formato,
) async {
  // La fecha se toma una vez: es la misma en el contenido y en el nombre.
  final fecha = DateTime.now();
  return switch (formato) {
    FormatoExportacion.pdf => ArchivoGenerado(
      bytes: await ListaCompraExportador.pdf(items, fecha),
      nombre: ListaCompraExportador.nombreArchivo(fecha, 'pdf'),
      mimeType: 'application/pdf',
    ),
    FormatoExportacion.csv => ArchivoGenerado(
      bytes: ListaCompraExportador.csvBytes(items, fecha),
      nombre: ListaCompraExportador.nombreArchivo(fecha, 'csv'),
      mimeType: 'text/csv',
    ),
  };
}
