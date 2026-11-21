import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../models/insumo.dart';

/// Un insumo que ya existe y se parece al que se está por cargar. Si
/// [mismoCodigoDeBarras] es true, la coincidencia es por el código y no solo
/// por el nombre.
typedef InsumoParecido = ({Insumo insumo, bool mismoCodigoDeBarras});

/// Ventana que se abre al tocar "Buscar duplicados" en Alta de insumo.
///
/// Si no hay nada parecido lo dice y se cierra con "Cerrar". Si lo hay, lista
/// cada insumo con su stock y un botón para cargarle un consumo, en vez de
/// crear uno repetido.
///
/// Devuelve el insumo al que se quiere cargar un consumo, o null si la persona
/// sigue con el alta (o cierra tocando afuera).
class DuplicadosDialog extends StatelessWidget {
  const DuplicadosDialog({required this.parecidos, super.key});

  final List<InsumoParecido> parecidos;

  /// Abre la ventana y espera la respuesta.
  static Future<Insumo?> mostrar(
    BuildContext context,
    List<InsumoParecido> parecidos,
  ) {
    return showDialog<Insumo>(
      context: context,
      builder: (context) => DuplicadosDialog(parecidos: parecidos),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.duplicadosBuscar, style: AppTextStyles.itemName),
            const SizedBox(height: 12),
            if (parecidos.isEmpty) ..._sinCoincidencias(context) else
              ..._conCoincidencias(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _sinCoincidencias(BuildContext context) {
    return [
      Text(
        AppStrings.duplicadosNinguno,
        style: AppTextStyles.listItemSubtitle,
      ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(AppStrings.duplicadosCerrar),
      ),
    ];
  }

  List<Widget> _conCoincidencias(BuildContext context) {
    return [
      Text(
        AppStrings.duplicadosEncontrados,
        style: AppTextStyles.listItemSubtitle,
      ),
      const SizedBox(height: 8),
      // Con varios resultados la lista se desplaza en vez de agrandar la
      // ventana más que la pantalla.
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: parecidos.length,
          separatorBuilder: (context, index) => const Divider(height: 16),
          itemBuilder: (context, index) => _Fila(
            parecido: parecidos[index],
            onCargarConsumo: () =>
                Navigator.of(context).pop(parecidos[index].insumo),
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(AppStrings.duplicadosSeguir),
      ),
    ];
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.parecido, required this.onCargarConsumo});

  final InsumoParecido parecido;
  final VoidCallback onCargarConsumo;

  @override
  Widget build(BuildContext context) {
    final insumo = parecido.insumo;
    final marca = insumo.marca;
    final stock = AppStrings.duplicadosStockActual(
      insumo.stock,
      insumo.unidad ?? AppStrings.duplicadosUnidades,
    );
    final motivo = parecido.mismoCodigoDeBarras
        ? AppStrings.duplicadosMismoCodigo
        : AppStrings.duplicadosNombreParecido;

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
        Text(motivo, style: AppTextStyles.listItemSubtitle),
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
