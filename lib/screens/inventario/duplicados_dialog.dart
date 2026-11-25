import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../core/breakpoints.dart';
import '../../models/insumo.dart';

/// Un insumo que ya existe y se parece al que se está por cargar. Si
/// [mismoCodigoDeBarras] es true, la coincidencia es por el código y no solo
/// por el nombre.
typedef InsumoParecido = ({Insumo insumo, bool mismoCodigoDeBarras});

/// Ventana que se abre al tocar "Buscar duplicados" en Alta de insumo.
///
/// Muestra primero lo que encontró la comparación de texto ([parecidos]), que
/// es instantánea. Si se pasa [sugerenciasIa], espera ese resultado debajo, con
/// un indicador, y suma los sinónimos que sugiera la IA marcados como tales. Si
/// la IA no está disponible ([sugerenciasIa] es null) o falla, lo dice y deja
/// lo de la comparación de texto.
///
/// Devuelve el insumo al que se quiere cargar un consumo, o null si la persona
/// sigue con el alta (o cierra tocando afuera).
class DuplicadosDialog extends StatelessWidget {
  const DuplicadosDialog({
    required this.parecidos,
    this.sugerenciasIa,
    super.key,
  });

  final List<InsumoParecido> parecidos;

  /// Insumos que la IA cree que son el mismo producto, cuando termine de
  /// buscar. Null si no hay IA disponible.
  final Future<List<Insumo>>? sugerenciasIa;

  /// Abre la ventana y espera la respuesta.
  static Future<Insumo?> mostrar(
    BuildContext context,
    List<InsumoParecido> parecidos, {
    Future<List<Insumo>>? sugerenciasIa,
  }) {
    return showDialog<Insumo>(
      context: context,
      builder: (context) => DuplicadosDialog(
        parecidos: parecidos,
        sugerenciasIa: sugerenciasIa,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Breakpoints.maxDialogWidth),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<List<Insumo>>(
            future: sugerenciasIa,
            builder: (context, snapshot) {
              final buscandoConIa = sugerenciasIa != null &&
                  snapshot.connectionState != ConnectionState.done;
              final iaFallo = snapshot.hasError;
              final deIa = snapshot.data ?? const <Insumo>[];

              final filas = <_FilaDatos>[
                for (final p in parecidos)
                  (
                    insumo: p.insumo,
                    motivo: p.mismoCodigoDeBarras
                        ? AppStrings.duplicadosMismoCodigo
                        : AppStrings.duplicadosNombreParecido,
                  ),
                for (final insumo in deIa)
                  (insumo: insumo, motivo: AppStrings.duplicadosSugeridoIa),
              ];

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.duplicadosBuscar,
                    style: AppTextStyles.itemName,
                  ),
                  const SizedBox(height: 12),
                  if (filas.isNotEmpty) ...[
                    Text(
                      AppStrings.duplicadosEncontrados,
                      style: AppTextStyles.listItemSubtitle,
                    ),
                    const SizedBox(height: 8),
                    // Con varios resultados la lista se desplaza en vez de
                    // agrandar la ventana más que la pantalla.
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filas.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 16),
                        itemBuilder: (context, index) => _Fila(
                          datos: filas[index],
                          onCargarConsumo: () =>
                              Navigator.of(context).pop(filas[index].insumo),
                        ),
                      ),
                    ),
                  ] else if (!buscandoConIa)
                    Text(
                      AppStrings.duplicadosNinguno,
                      style: AppTextStyles.listItemSubtitle,
                    ),
                  if (buscandoConIa) ...[
                    const SizedBox(height: 12),
                    const _BuscandoConIa(),
                  ] else if (sugerenciasIa == null) ...[
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.duplicadosIaNoDisponible,
                      style: AppTextStyles.listItemSubtitle,
                    ),
                  ] else if (iaFallo) ...[
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.duplicadosIaFallo,
                      style: AppTextStyles.listItemSubtitle,
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      filas.isEmpty
                          ? AppStrings.duplicadosCerrar
                          : AppStrings.duplicadosSeguir,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

typedef _FilaDatos = ({Insumo insumo, String motivo});

class _BuscandoConIa extends StatelessWidget {
  const _BuscandoConIa();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            AppStrings.duplicadosBuscandoIa,
            style: AppTextStyles.listItemSubtitle,
          ),
        ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.datos, required this.onCargarConsumo});

  final _FilaDatos datos;
  final VoidCallback onCargarConsumo;

  @override
  Widget build(BuildContext context) {
    final insumo = datos.insumo;
    final marca = insumo.marca;
    final stock = AppStrings.duplicadosStockActual(
      insumo.stock,
      insumo.unidad ?? AppStrings.duplicadosUnidades,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          marca == null || marca.trim().isEmpty
              ? insumo.nombre
              : '${insumo.nombre} · $marca',
          style: AppTextStyles.itemName,
        ),
        Text(stock, style: AppTextStyles.listItemSubtitle),
        Text(datos.motivo, style: AppTextStyles.listItemSubtitle),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onCargarConsumo,
            style: TextButton.styleFrom(foregroundColor: AppColors.titleColor),
            child: const Text(AppStrings.duplicadosCargarConsumo),
          ),
        ),
      ],
    );
  }
}
