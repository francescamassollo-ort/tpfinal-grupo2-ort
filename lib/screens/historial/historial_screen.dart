import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../models/filtro_historial.dart';
import '../../providers/historial_provider.dart';
import '../../providers/insumo_providers.dart';
import '../../widgets/app_decorative_background.dart';
import '../../widgets/app_screen_header.dart';
import '../../widgets/share_download_actions.dart';
import 'historial_exportacion.dart';
import 'historial_filtro_dialog.dart';
import 'movimiento_tile.dart';

/// Historial de movimientos de stock. Según el diseño no lleva barra inferior
/// ni botón flotante, por eso su ruta está fuera del ShellRoute.
class HistorialScreen extends ConsumerWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movimientos = ref.watch(historialProvider);
    final filtro = ref.watch(filtroHistorialProvider);

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: AppDecorativeBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppScreenHeader(
                title: AppStrings.historialTitulo,
                onBack: () => _volver(context),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 26),
                  child: IconButton(
                    onPressed: () => _abrirFiltros(context, ref),
                    tooltip: AppStrings.filtros,
                    // El punto avisa que hay un filtro puesto: sin él, una
                    // lista corta podría parecer que faltan movimientos.
                    icon: Badge(
                      isLabelVisible: !filtro.estaVacio,
                      smallSize: 9,
                      backgroundColor: AppColors.movementBlue,
                      child: const Icon(
                        Icons.tune,
                        size: 24,
                        color: AppColors.titleColor,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: movimientos.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text(
                      AppStrings.historialError,
                      style: AppTextStyles.itemDetail,
                    ),
                  ),
                  data: (lista) => lista.isEmpty
                      ? _ListaVacia(
                          hayFiltro: !filtro.estaVacio,
                          onLimpiar:
                              ref.read(filtroHistorialProvider.notifier).limpiar,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(36, 8, 36, 20),
                          itemCount: lista.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              MovimientoTile(item: lista[index]),
                        ),
                ),
              ),
              // Mientras el historial carga o falla no hay nada que exportar.
              ShareDownloadActions(
                onShare: movimientos.hasValue
                    ? () => exportarHistorial(context, ref, descargar: false)
                    : null,
                onDownload: movimientos.hasValue
                    ? () => exportarHistorial(context, ref, descargar: true)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Abre el panel de filtros y espera a que se cierre. Si se tocó "Filtrar" o
  // "Limpiar" devuelve el filtro elegido y se guarda; si se cerró tocando
  // afuera devuelve null y no cambia nada.
  Future<void> _abrirFiltros(BuildContext context, WidgetRef ref) async {
    final elegido = await showDialog<FiltroHistorial>(
      context: context,
      builder: (_) => HistorialFiltroDialog(
        filtroActual: ref.read(filtroHistorialProvider),
        insumos: ref.read(insumosProvider).value ?? const [],
      ),
    );
    if (elegido == null) return;
    ref.read(filtroHistorialProvider.notifier).cambiar(elegido);
  }

  // Si se llegó desde otra pantalla vuelve atrás; si no (por ejemplo desde el
  // menú lateral), vuelve a Inventario.
  void _volver(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/inventario');
    }
  }
}

/// Lo que se ve cuando no hay filas. Distingue dos casos distintos: no hay
/// movimientos cargados, o los hay pero ninguno cumple el filtro (con un
/// enlace para sacarlo).
class _ListaVacia extends StatelessWidget {
  const _ListaVacia({required this.hayFiltro, required this.onLimpiar});

  final bool hayFiltro;
  final VoidCallback onLimpiar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hayFiltro
                  ? AppStrings.historialSinCoincidencias
                  : AppStrings.historialVacio,
              textAlign: TextAlign.center,
              style: AppTextStyles.itemDetail,
            ),
            if (hayFiltro)
              TextButton(
                onPressed: onLimpiar,
                child: const Text(AppStrings.historialLimpiarFiltros),
              ),
          ],
        ),
      ),
    );
  }
}
