import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../models/insumo.dart';
import '../../providers/insumo_providers.dart';
import '../../services/similitud_texto.dart';

/// Los insumos cuyo nombre contiene [texto], para sugerirlos mientras se
/// escribe el nombre de uno nuevo. No distingue mayúsculas, tildes ni
/// espacios. Los que empiezan igual van primero; después, en orden alfabético.
///
/// Con menos de [minimoCaracteres] letras no sugiere nada: una sola letra
/// coincide con casi todo y solo molesta.
List<Insumo> sugerenciasPorNombre(
  String texto,
  Iterable<Insumo> insumos, {
  int maximo = 3,
  int minimoCaracteres = 2,
}) {
  final buscado = SimilitudTexto.normalizar(texto);
  if (buscado.length < minimoCaracteres) return const [];

  final coincidencias = <({Insumo insumo, bool empieza, String nombre})>[
    for (final insumo in insumos)
      if (SimilitudTexto.normalizar(insumo.nombre).contains(buscado))
        (
          insumo: insumo,
          empieza: SimilitudTexto.normalizar(insumo.nombre).startsWith(buscado),
          nombre: insumo.nombre.toLowerCase(),
        ),
  ]..sort((a, b) {
      if (a.empieza != b.empieza) return a.empieza ? -1 : 1;
      return a.nombre.compareTo(b.nombre);
    });

  return [for (final c in coincidencias.take(maximo)) c.insumo];
}

/// Las sugerencias que aparecen debajo del campo Nombre del Alta mientras se
/// escribe. Previene duplicados antes de cargarlos: si ya existe un insumo con
/// ese nombre, se ve enseguida y se puede abrir.
///
/// Si no hay ninguno parecido, lo dice: se va a agregar como nuevo. No frena
/// nada: la persona sigue cargando igual.
class SugerenciasNombre extends ConsumerWidget {
  const SugerenciasNombre({
    required this.controller,
    required this.onElegir,
    super.key,
  });

  /// El campo Nombre. Cada vez que cambia, se recalculan las sugerencias.
  final TextEditingController controller;

  /// Se llama al tocar una sugerencia.
  final ValueChanged<Insumo> onElegir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insumos = ref.watch(insumosProvider).value;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final texto = controller.text;
        // Mientras no se sabe qué insumos hay (cargando o sin permiso), no se
        // dice nada: afirmar que no hay ninguno parecido sería engañoso.
        if (insumos == null ||
            SimilitudTexto.normalizar(texto).length < 2) {
          return const SizedBox.shrink();
        }

        final sugeridos = sugerenciasPorNombre(texto, insumos);
        if (sugeridos.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              AppStrings.altaSinCoincidencias,
              style: AppTextStyles.listItemSubtitle,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.altaSugerenciasTitulo,
                style: AppTextStyles.listItemSubtitle,
              ),
              for (final insumo in sugeridos)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    insumo.nombre,
                    style: AppTextStyles.listItemTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${insumo.ubicacion} · '
                    '${AppStrings.escanerStockActual(insumo.stock, insumo.unidad ?? AppStrings.escanerUnidadPorDefecto)}',
                    style: AppTextStyles.listItemSubtitle,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onElegir(insumo),
                ),
            ],
          ),
        );
      },
    );
  }
}
