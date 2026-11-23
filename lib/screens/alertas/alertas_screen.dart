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
import 'alertas_filtro_dialog.dart';

/// Alertas de stock y vencimientos. Va dentro del AppShell: conserva la barra
/// inferior pero, según el diseño, sin botón flotante, Compartir ni Descargar.
///
/// Cada alerta se puede marcar como vista: queda en la lista pero atenuada, y
/// la campana deja de contarla. Es por persona.
///
/// El ícono de filtros abre un panel para ver solo un tipo de alerta o solo las
/// vistas o sin ver. El filtro cambia la lista, no lo que cuenta la campana.
class AlertasScreen extends ConsumerStatefulWidget {
  const AlertasScreen({super.key});

  @override
  ConsumerState<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends ConsumerState<AlertasScreen> {
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
    final alertas = ref.watch(alertasFiltradasProvider);
    final vistas = ref.watch(alertasVistasIdsProvider);
    final filtro = ref.watch(filtroAlertasProvider);
    // Si no hay ninguna alerta, con o sin filtro, no tiene sentido ofrecer
    // "limpiar filtros": no hay nada que el filtro esté escondiendo.
    final hayAlertas =
        (ref.watch(alertasProvider).value ?? const <Alerta>[]).isNotEmpty;

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
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 26),
                  child: IconButton(
                    onPressed: _abrirFiltros,
                    tooltip: AppStrings.filtros,
                    // El punto avisa que hay un filtro puesto: sin él, una
                    // lista corta podría parecer que faltan alertas.
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
                      ? _ListaVacia(
                          hayFiltro: !filtro.estaVacio && hayAlertas,
                          onLimpiar:
                              ref.read(filtroAlertasProvider.notifier).limpiar,
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

  // Abre el panel de filtros y espera a que se cierre. Si se tocó "Filtrar" o
  // "Limpiar" devuelve el filtro elegido y se guarda; si se cerró tocando
  // afuera devuelve null y no cambia nada.
  Future<void> _abrirFiltros() async {
    final elegido = await AlertasFiltroDialog.mostrar(
      context,
      ref.read(filtroAlertasProvider),
    );
    if (elegido == null || !mounted) return;
    ref.read(filtroAlertasProvider.notifier).cambiar(elegido);
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

/// Lo que se ve cuando no hay filas. Distingue dos casos: no hay alertas, o las
/// hay pero ninguna cumple el filtro (con un enlace para sacarlo).
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
                  ? AppStrings.alertasSinCoincidencias
                  : AppStrings.alertasVacia,
              textAlign: TextAlign.center,
              style: AppTextStyles.listItemSubtitle,
            ),
            if (hayFiltro)
              TextButton(
                onPressed: onLimpiar,
                child: const Text(AppStrings.alertasLimpiarFiltros),
              ),
          ],
        ),
      ),
    );
  }
}
