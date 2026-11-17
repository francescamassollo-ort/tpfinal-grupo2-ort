import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../providers/alerta_provider.dart';
import '../../widgets/app_decorative_background.dart';
import '../../widgets/app_screen_header.dart';
import 'alerta_tile.dart';

/// Alertas de stock y vencimientos. Va dentro del AppShell: conserva la barra
/// inferior pero, según el diseño, sin botón flotante, Compartir ni Descargar.
class AlertasScreen extends ConsumerWidget {
  const AlertasScreen({super.key});

  // El filtro todavía no existe: el diseño solo dibuja el ícono y no define
  // qué opciones tiene.
  static const VoidCallback? _onFiltros = null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertas = ref.watch(alertasProvider);

    return ColoredBox(
      color: AppColors.screenBackground,
      child: AppDecorativeBackground(
        // La barra inferior es la del shell, por eso el área segura es solo
        // la de arriba.
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppScreenHeader(
                title: AppStrings.alertasTitulo,
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
                child: alertas.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text(
                      AppStrings.alertasError,
                      style: AppTextStyles.listItemSubtitle,
                    ),
                  ),
                  data: (lista) => lista.isEmpty
                      ? Center(
                          child: Text(
                            AppStrings.alertasVacia,
                            style: AppTextStyles.listItemSubtitle,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(36, 8, 36, 20),
                          itemCount: lista.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final alerta = lista[index];
                            return AlertaTile(
                              alerta: alerta,
                              // Abre el insumo, igual que al tocarlo en Inventario.
                              onTap: () =>
                                  context.push('/insumo/${alerta.productoId}'),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Si se llegó desde otra pantalla vuelve atrás; si no (por ejemplo desde la
  // barra inferior), vuelve a Inventario.
  void _volver(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/inventario');
    }
  }
}
