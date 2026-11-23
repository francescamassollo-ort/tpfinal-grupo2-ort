import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../core/formatters.dart';
import '../../models/trabajo_practico.dart';
import '../../models/usuario.dart';
import '../../providers/insumo_providers.dart';
import '../../providers/role_provider.dart';
import '../../providers/trabajopractico_provider.dart';
import '../../widgets/indicador_disponibilidad_tp.dart';
import '../../widgets/tp_insumo_fila.dart';

// ConsumerWidget: lee el TP, el rol y el stock desde providers.
// La regla "alcanza / no alcanza" no se calcula acá: viene de TpService
// a través de disponibilidadTpProvider; la pantalla solo la dibuja.
class TpDetalleScreen extends ConsumerWidget {
  const TpDetalleScreen({required this.tpId, super.key});

  final String tpId;

  // Se entra con push() desde la lista, pero por si se abre directo
  // (sin pantalla anterior) se vuelve a la lista de TPs.
  void _volver(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/tp');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tpAsync = ref.watch(tpPorIdProvider(tpId));

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Flecha y título van siempre, así se puede volver aunque el TP
            // todavía esté cargando o haya dado error.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    iconSize: 32,
                    color: AppColors.backIconColor,
                    tooltip: AppStrings.volver,
                    onPressed: () => _volver(context),
                  ),
                  Expanded(
                    child: Text(
                      tpAsync.value?.nombre ?? '',
                      style: AppTextStyles.screenTitle,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tpAsync.when(
                data: (tp) => tp == null
                    ? const Center(child: Text(AppStrings.tpNoEncontrado))
                    : _DetalleTp(tp: tp),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    const Center(child: Text(AppStrings.tpErrorDetalle)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetalleTp extends ConsumerWidget {
  const _DetalleTp({required this.tp});

  final TrabajoPractico tp;

  // Pide confirmación y desactiva (borrado lógico) este TP.
  Future<void> _confirmarEliminacion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.tpEliminarUnoTitulo),
        content: Text(AppStrings.tpEliminarMensaje(1)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.tpEliminar),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    final notifier = ref.read(tpProvider.notifier);
    try {
      await notifier.desactivar(tp.id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.tpErrorEliminar)),
      );
      return;
    }
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/tp');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleProvider);
    // Solo admin y docente editan y eliminan TPs.
    final puedeEditar =
        role == UserRole.administrador || role == UserRole.docente;
    final insumosAsync = ref.watch(insumosProvider);
    final disponibilidad = ref.watch(disponibilidadTpProvider(tp));

    return Column(
      children: [
        if (puedeEditar)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    color: AppColors.titleColor,
                    tooltip: AppStrings.tpEditar,
                    onPressed: () => context.push('/tp/editar/${tp.id}'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    color: AppColors.titleColor,
                    tooltip: AppStrings.papelera,
                    onPressed: () => _confirmarEliminacion(context, ref),
                  ),
                ],
              ),
            ),
          ),
        // Todo lo que scrollea. Los botones de abajo quedan afuera de este
        // Expanded, por eso no se mueven aunque la lista sea larga.
        Expanded(
          child: insumosAsync.when(
            data: (insumos) {
              final porId = {for (final i in insumos) i.id: i};
              final faltantes =
                  disponibilidad.value?.faltantes ?? const <String, double>{};

              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatearFecha(tp.fecha),
                          style: AppTextStyles.listItemSubtitle,
                        ),
                        if (tp.descripcion.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              tp.descripcion,
                              style: AppTextStyles.itemDetail,
                            ),
                          ),
                        const SizedBox(height: 8),
                        IndicadorDisponibilidadTp(
                          disponibilidad: disponibilidad,
                        ),
                      ],
                    ),
                  ),
                  const TpInsumoEncabezado(),
                  if (tp.insumos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(AppStrings.tpSinInsumos),
                    )
                  else
                    for (final requerido in tp.insumos)
                      TpInsumoFila(
                        requerido: requerido,
                        insumo: porId[requerido.insumoId],
                        falta: faltantes.containsKey(requerido.insumoId),
                      ),
                  if (tp.docente.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Text(
                        AppStrings.tpDocenteACargo(tp.docente),
                        style: AppTextStyles.listItemSubtitle
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                const Center(child: Text(AppStrings.tpErrorDisponibilidad)),
          ),
        ),
        const _BotonesFijos(),
      ],
    );
  }
}

// Compartir y Descargar: fijos abajo, todavía sin funcionalidad.
class _BotonesFijos extends StatelessWidget {
  const _BotonesFijos();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              // TODO: compartir la lista de insumos (R12).
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: AppColors.cardBackground,
                side: const BorderSide(color: AppColors.outlineColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                AppStrings.compartir,
                style: AppTextStyles.button(AppColors.titleColor),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              // TODO: descargar la lista de insumos (R12).
              onPressed: () {},
              child: Text(
                AppStrings.descargar,
                style: AppTextStyles.button(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}