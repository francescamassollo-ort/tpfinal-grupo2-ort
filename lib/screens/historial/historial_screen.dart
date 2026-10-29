import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../providers/historial_provider.dart';
import '../../widgets/app_decorative_background.dart';
import '../../widgets/app_screen_header.dart';
import '../../widgets/share_download_actions.dart';
import 'movimiento_tile.dart';

/// Historial de movimientos de stock. Según el diseño no lleva barra inferior
/// ni botón flotante, por eso su ruta está fuera del ShellRoute.
class HistorialScreen extends ConsumerWidget {
  const HistorialScreen({super.key});

  // Estas acciones todavía no existen: filtros, compartir y descargar quedan
  // sin función hasta que se definan y se implementen.
  static const VoidCallback? _onFiltros = null;
  static const VoidCallback? _onCompartir = null;
  static const VoidCallback? _onDescargar = null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movimientos = ref.watch(historialProvider);

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
              const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 26),
                  child: IconButton(
                    onPressed: _onFiltros,
                    tooltip: AppStrings.filtros,
                    icon: Icon(
                      Icons.tune,
                      size: 24,
                      color: AppColors.titleColor,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: movimientos.isEmpty
                    ? Center(
                        child: Text(
                          AppStrings.historialVacio,
                          style: AppTextStyles.itemDetail,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(36, 8, 36, 20),
                        itemCount: movimientos.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            MovimientoTile(item: movimientos[index]),
                      ),
              ),
              const ShareDownloadActions(
                onShare: _onCompartir,
                onDownload: _onDescargar,
              ),
            ],
          ),
        ),
      ),
    );
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
