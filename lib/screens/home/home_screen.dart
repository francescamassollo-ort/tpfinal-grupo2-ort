import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../providers/home_provider.dart';
import '../../widgets/app_action_button.dart';
import '../../widgets/app_decorative_background.dart';
import '../../widgets/contenido_centrado.dart';
import '../historial/movimiento_item.dart';

/// Inicio: un tablero con lo que más importa de un vistazo (insumos con stock
/// bajo, alertas activas y el último movimiento) y atajos a Inventario, Alertas
/// e Historial. Va dentro del AppShell. Lo pueden ver todos los roles: no
/// muestra nada que no vean ya en esas pantallas.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockBajo = ref.watch(homeStockBajoProvider);
    final alertas = ref.watch(homeAlertasProvider);
    final ultimo = ref.watch(homeUltimoMovimientoProvider);

    return ColoredBox(
      color: AppColors.screenBackground,
      child: AppDecorativeBackground(
        child: SafeArea(
          bottom: false,
          child: ContenidoCentrado(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(36, 20, 36, 24),
              children: [
                Text(AppStrings.homeTitulo, style: AppTextStyles.screenTitle),
                const SizedBox(height: 20),
                _TarjetaDato<int>(
                  etiqueta: AppStrings.homeStockBajo,
                  color: AppColors.stockDanger,
                  valor: stockBajo,
                  texto: (cantidad) => '$cantidad',
                  detalle: (cantidad) => AppStrings.homeStockBajoDetalle,
                  onTap: () => context.go('/inventario'),
                ),
                const SizedBox(height: 12),
                _TarjetaDato<ResumenAlertas>(
                  etiqueta: AppStrings.homeAlertas,
                  color: AppColors.stockWarning,
                  valor: alertas,
                  texto: (resumen) => '${resumen.activas}',
                  detalle: (resumen) =>
                      '${resumen.sinVer} ${AppStrings.homeAlertasDetalle}',
                  onTap: () => context.go('/alertas'),
                ),
                const SizedBox(height: 12),
                _TarjetaDato<MovimientoItem?>(
                  etiqueta: AppStrings.homeUltimoMovimiento,
                  color: AppColors.movementBlue,
                  valor: ultimo,
                  // Sin movimientos no hay nada que mostrar en grande: el
                  // mensaje va en el lugar del dato.
                  texto: (m) =>
                      m == null ? AppStrings.homeSinMovimientos : m.elementoNombre,
                  detalle: (m) => m == null
                      ? ''
                      : '${m.deltaTexto} · ${m.usuarioNombre} · ${m.fechaEtiqueta}',
                  grande: false,
                  onTap: () => context.push('/historial'),
                ),
                const SizedBox(height: 28),
                Text(AppStrings.homeAtajos, style: AppTextStyles.listItemTitle),
                const SizedBox(height: 12),
                AppActionButton(
                  label: AppStrings.homeIrInventario,
                  onPressed: () => context.go('/inventario'),
                ),
                const SizedBox(height: 12),
                AppActionButton(
                  label: AppStrings.homeIrAlertas,
                  variant: AppActionButtonVariant.secondary,
                  onPressed: () => context.go('/alertas'),
                ),
                const SizedBox(height: 12),
                AppActionButton(
                  label: AppStrings.homeIrHistorial,
                  variant: AppActionButtonVariant.secondary,
                  // El Historial va fuera del shell: se abre encima y su flecha
                  // vuelve acá.
                  onPressed: () => context.push('/historial'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Una tarjeta del tablero: etiqueta, el dato y una línea de detalle. Mientras
/// el dato carga muestra "...", y si falla lo dice, en vez de mostrar un valor
/// que podría ser falso.
class _TarjetaDato<T> extends StatelessWidget {
  const _TarjetaDato({
    required this.etiqueta,
    required this.color,
    required this.valor,
    required this.texto,
    required this.detalle,
    required this.onTap,
    this.grande = true,
  });

  final String etiqueta;
  final Color color;
  final AsyncValue<T> valor;
  final String Function(T) texto;
  final String Function(T) detalle;
  final VoidCallback onTap;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final style = grande
        ? AppTextStyles.screenTitle.copyWith(fontSize: 32, color: color)
        : AppTextStyles.listItemTitle.copyWith(color: color);

    final (principal, secundario) = valor.when(
      loading: () => ('...', ''),
      error: (error, stack) => (AppStrings.homeErrorDato, ''),
      data: (dato) => (texto(dato), detalle(dato)),
    );

    return Material(
      color: AppColors.subtleSurface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.outlineColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiqueta, style: AppTextStyles.itemDetail),
              const SizedBox(height: 4),
              Text(principal, style: style),
              if (secundario.isNotEmpty)
                Text(secundario, style: AppTextStyles.itemDetail),
            ],
          ),
        ),
      ),
    );
  }
}
