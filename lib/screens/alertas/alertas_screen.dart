import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../models/alerta.dart';
import '../../providers/alerta_provider.dart';
import '../../widgets/app_decorative_background.dart';
import '../../widgets/app_screen_header.dart';
import 'alerta_tile.dart';

/// Alertas de stock y vencimientos. Va dentro del AppShell: conserva la barra
/// inferior pero, según el diseño, sin botón flotante, Compartir ni Descargar.
///
/// Cada alerta se puede marcar como vista: queda en la lista pero atenuada, y
/// la campana deja de contarla. Es por persona.
class AlertasScreen extends ConsumerStatefulWidget {
  const AlertasScreen({super.key});

  @override
  ConsumerState<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends ConsumerState<AlertasScreen> {
  // El filtro todavía no existe: el diseño solo dibuja el ícono y no define
  // qué opciones tiene.
  static const VoidCallback? _onFiltros = null;

  @override
  void initState() {
    super.initState();
    // Cada vez que cambian las alertas o las marcas (y al abrir la pantalla) se
    // borran las marcas de alertas que ya no existen, para que si una vuelve
    // lo haga como nueva. La acción decide sola si es seguro hacerlo.
    ref.listenManual(
      alertasProvider,
      (previous, next) => _limpiar(),
      fireImmediately: true,
    );
    ref.listenManual(alertasVistasProvider, (previous, next) => _limpiar());
  }

  // Limpiar es un detalle de mantenimiento: si falla, no hay nada que mostrarle
  // a la persona, y se vuelve a intentar en el próximo cambio.
  Future<void> _limpiar() async {
    try {
      await ref.read(alertasAccionesProvider).limpiarObsoletas();
    } catch (error) {
      debugPrint('No se pudieron limpiar las marcas de alertas: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertas = ref.watch(alertasProvider);
    final vistas = ref.watch(alertasVistasIdsProvider);

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
                            final vista = vistas.contains(alerta.id);
                            return AlertaTile(
                              alerta: alerta,
                              vista: vista,
                              // Abre el insumo, igual que al tocarlo en Inventario.
                              onTap: () =>
                                  context.push('/insumo/${alerta.productoId}'),
                              onToggleVista: () => _alternarVista(alerta, vista),
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

  // Marca la alerta como vista o, si ya lo estaba, la vuelve a dejar como
  // nueva. La lista se actualiza sola cuando Firestore confirma el cambio.
  Future<void> _alternarVista(Alerta alerta, bool vista) async {
    final messenger = ScaffoldMessenger.of(context);
    final acciones = ref.read(alertasAccionesProvider);
    try {
      if (vista) {
        await acciones.marcarNoVista(alerta);
      } else {
        await acciones.marcarVista(alerta);
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.alertasErrorMarcar)),
      );
    }
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
