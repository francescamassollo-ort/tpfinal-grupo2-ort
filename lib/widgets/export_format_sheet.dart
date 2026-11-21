import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_strings.dart';
import '../core/app_text_styles.dart';

/// Formatos en los que se puede compartir o descargar un listado.
enum FormatoExportacion { pdf, csv }

/// Abre un panel desde abajo para elegir el formato. Devuelve el formato
/// elegido, o null si se cerró sin elegir (tocando afuera o deslizando).
///
/// [titulo] distingue las dos acciones: "Compartir como" o "Descargar como".
/// Lo usan Compras ahora e Historial cuando exporte.
Future<FormatoExportacion?> elegirFormatoExportacion(
  BuildContext context, {
  required String titulo,
}) {
  return showModalBottomSheet<FormatoExportacion>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.screenBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _SelectorFormato(titulo: titulo),
  );
}

class _SelectorFormato extends StatelessWidget {
  const _SelectorFormato({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 4, 32, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: AppTextStyles.screenTitle),
          const SizedBox(height: 16),
          const _OpcionFormato(
            formato: FormatoExportacion.pdf,
            icono: Icons.picture_as_pdf_outlined,
            nombre: AppStrings.formatoPdf,
            detalle: AppStrings.formatoPdfDetalle,
          ),
          const SizedBox(height: 12),
          const _OpcionFormato(
            formato: FormatoExportacion.csv,
            icono: Icons.table_chart_outlined,
            nombre: AppStrings.formatoCsv,
            detalle: AppStrings.formatoCsvDetalle,
          ),
        ],
      ),
    );
  }
}

/// Una opción del selector: ícono, nombre del formato y para qué sirve.
class _OpcionFormato extends StatelessWidget {
  const _OpcionFormato({
    required this.formato,
    required this.icono,
    required this.nombre,
    required this.detalle,
  });

  final FormatoExportacion formato;
  final IconData icono;
  final String nombre;
  final String detalle;

  static const double _circulo = 44;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.outlineColor, width: 2),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(formato),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: _circulo,
                height: _circulo,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.subtleSurface,
                ),
                child: Icon(icono, size: 24, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre, style: AppTextStyles.listItemTitle),
                    Text(detalle, style: AppTextStyles.listItemSubtitle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
