import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../providers/ubicacion_providers.dart';
import '../../services/ubicaciones_logica.dart';

/// Lo que aparece debajo del campo Ubicación mientras se escribe, para que los
/// lugares no queden escritos de varias formas ("Armario 1", "armario 1 ",
/// "Armrio 1"):
///
/// - Si ya existe, lo confirma.
/// - Si se parece a alguna de la lista, la ofrece ("¿Quisiste decir...?").
/// - Si no se parece a ninguna, avisa que se va a agregar como ubicación nueva.
///
/// No frena nada: la persona puede escribir una ubicación nueva. Como el Alta
/// y la edición son del administrador, es él quien suma lugares a la lista.
class SugerenciasUbicacion extends ConsumerWidget {
  const SugerenciasUbicacion({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ubicaciones = ref.watch(ubicacionesProvider).value;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final texto = controller.text;
        // Mientras no se sabe qué ubicaciones hay, no se afirma nada.
        if (ubicaciones == null || UbicacionesLogica.idDe(texto).isEmpty) {
          return const SizedBox.shrink();
        }

        final nombres = [for (final u in ubicaciones) u.nombre];

        if (UbicacionesLogica.existe(texto, nombres)) {
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 16, color: AppColors.stockOk),
                const SizedBox(width: 6),
                Text(
                  AppStrings.ubicacionExistente,
                  style: AppTextStyles.listItemSubtitle,
                ),
              ],
            ),
          );
        }

        final parecidas = UbicacionesLogica.parecidas(texto, nombres);
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (parecidas.isNotEmpty) ...[
                Text(
                  AppStrings.ubicacionQuisisteDecir,
                  style: AppTextStyles.listItemSubtitle,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final nombre in parecidas)
                      ActionChip(
                        label: Text(nombre),
                        // Reemplaza lo escrito por la ubicación de la lista.
                        onPressed: () => controller.text = nombre,
                      ),
                  ],
                ),
              ],
              Text(
                AppStrings.ubicacionNueva,
                style: AppTextStyles.listItemSubtitle,
              ),
            ],
          ),
        );
      },
    );
  }
}
