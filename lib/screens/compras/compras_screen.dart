import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../providers/compras_provider.dart';
import '../../widgets/app_decorative_background.dart';
import '../../widgets/app_screen_header.dart';
import '../../widgets/share_download_actions.dart';
import 'compra_tile.dart';
import 'compras_fab.dart';

/// Lista de compras. Según el diseño no lleva la barra inferior del shell y
/// tiene su propio botón flotante, por eso su ruta está fuera del ShellRoute.
class ComprasScreen extends ConsumerWidget {
  const ComprasScreen({super.key});

  // Estas acciones todavía no existen: sugerencias, buscar, papelera, agregar,
  // compartir y descargar quedan sin función hasta que se definan.
  static const VoidCallback? _onSugerencias = null;
  static const VoidCallback? _onBuscar = null;
  static const VoidCallback? _onPapelera = null;
  static const VoidCallback? _onAgregar = null;
  static const VoidCallback? _onCompartir = null;
  static const VoidCallback? _onDescargar = null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(comprasProvider);
    final notifier = ref.read(comprasProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: AppDecorativeBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppScreenHeader(
                title: AppStrings.comprasTitulo,
                onBack: () => _volver(context),
              ),
              const _AccionesSuperiores(
                onSugerencias: _onSugerencias,
                onBuscar: _onBuscar,
                onPapelera: _onPapelera,
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          AppStrings.comprasVacia,
                          style: AppTextStyles.listItemSubtitle,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(36, 8, 36, 20),
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return CompraTile(
                            item: item,
                            onDecrement: () => notifier.decrementar(item.id),
                            onIncrement: () => notifier.incrementar(item.id),
                          );
                        },
                      ),
              ),
              // 28 del borde derecho y 47 hasta los botones (12 ya los pone
              // ShareDownloadActions), según Figma.
              const Padding(
                padding: EdgeInsets.only(right: 28, bottom: 35),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ComprasFab(onPressed: _onAgregar),
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

/// Fila bajo el encabezado: enlace de sugerencias a la izquierda, y buscar y
/// papelera a la derecha. El diseño muestra solo íconos, sin campo de búsqueda.
class _AccionesSuperiores extends StatelessWidget {
  const _AccionesSuperiores({
    required this.onSugerencias,
    required this.onBuscar,
    required this.onPapelera,
  });

  final VoidCallback? onSugerencias;
  final VoidCallback? onBuscar;
  final VoidCallback? onPapelera;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, right: 24),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: onSugerencias,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    AppStrings.comprasAgregarSugerencias,
                    style: AppTextStyles.link,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onBuscar,
            tooltip: AppStrings.buscar,
            icon: const Icon(Icons.search, size: 23, color: AppColors.bodyColor),
          ),
          IconButton(
            onPressed: onPapelera,
            tooltip: AppStrings.papelera,
            icon: const Icon(
              Icons.delete_outline,
              size: 21,
              color: AppColors.titleColor,
            ),
          ),
        ],
      ),
    );
  }
}
