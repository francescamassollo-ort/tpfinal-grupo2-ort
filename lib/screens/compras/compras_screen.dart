import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../models/insumo.dart';
import '../../models/lista_compra.dart';
import '../../providers/insumo_providers.dart';
import '../../providers/lista_compra_provider.dart';
import '../../widgets/app_decorative_background.dart';
import '../../widgets/app_screen_header.dart';
import '../../widgets/share_download_actions.dart';
import 'compra_tile.dart';
import 'compras_agregar_dialog.dart';
import 'compras_exportacion.dart';
import 'compras_fab.dart';
import 'item_compra.dart';

/// Lista de compras. Según el diseño no lleva la barra inferior del shell y
/// tiene su propio botón flotante, por eso su ruta está fuera del ShellRoute.
class ComprasScreen extends ConsumerStatefulWidget {
  const ComprasScreen({super.key});

  @override
  ConsumerState<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends ConsumerState<ComprasScreen> {
  // Modo "eliminar": se tocó el tacho y se eligen los ítems a sacar.
  bool _seleccionando = false;
  final Set<String> _elegidos = {};

  void _salirDeSeleccion() => setState(() {
        _seleccionando = false;
        _elegidos.clear();
      });

  void _alternar(String id) => setState(() {
        if (!_elegidos.remove(id)) _elegidos.add(id);
      });

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemsCompraProvider);
    final acciones = ref.read(comprasAccionesProvider);
    final todos = items.value ?? const <ItemCompra>[];

    return PopScope(
      // En modo eliminar, "atrás" solo cancela la selección.
      canPop: !_seleccionando,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _salirDeSeleccion();
      },
      child: Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: AppDecorativeBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppScreenHeader(
                title: AppStrings.comprasTitulo,
                onBack: () => _volver(context),
              ),
              _AccionesSuperiores(
                onSugerencias: () => _agregarSugerencias(context, ref),
                seleccionando: _seleccionando,
                cantidadElegidos: _elegidos.length,
                hayItems: todos.isNotEmpty,
                onPapelera: () => setState(() => _seleccionando = true),
                onCancelar: _salirDeSeleccion,
                onTodos: () => setState(() {
                  _elegidos
                    ..clear()
                    ..addAll(todos.map((i) => i.id));
                }),
                onEliminar: () => _eliminar(context, ref),
              ),
              Expanded(
                child: items.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text(
                      AppStrings.comprasError,
                      style: AppTextStyles.listItemSubtitle,
                    ),
                  ),
                  data: (lista) => lista.isEmpty
                      ? Center(
                          child: Text(
                            AppStrings.comprasVacia,
                            style: AppTextStyles.listItemSubtitle,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(36, 8, 36, 20),
                          itemCount: lista.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = lista[index];
                            return CompraTile(
                              item: item,
                              onDecrement: () => acciones.decrementar(item.id),
                              onIncrement: () => acciones.incrementar(item.id),
                              onCambiarEstado: (estado) =>
                                  _cambiarEstado(context, ref, item, estado),
                              seleccionando: _seleccionando,
                              seleccionado: _elegidos.contains(item.id),
                              onSeleccion: () => _alternar(item.id),
                            );
                          },
                        ),
                ),
              ),
              // 28 del borde derecho y 47 hasta los botones (12 ya los pone
              // ShareDownloadActions), según Figma.
              Padding(
                padding: const EdgeInsets.only(right: 28, bottom: 35),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ComprasFab(onPressed: () => _agregar(context, ref)),
                ),
              ),
              // Mientras la lista carga o falla no hay nada que exportar.
              ShareDownloadActions(
                onShare: items.hasValue
                    ? () => exportarListaCompras(context, ref, descargar: false)
                    : null,
                onDownload: items.hasValue
                    ? () => exportarListaCompras(context, ref, descargar: true)
                    : null,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  // Pide confirmar y saca de la lista los ítems elegidos.
  Future<void> _eliminar(BuildContext context, WidgetRef ref) async {
    final ids = _elegidos.toList();
    if (ids.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.comprasEliminarTitulo),
        content: Text(AppStrings.comprasEliminarMensaje(ids.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.comprasEliminarConfirmar),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    try {
      await ref.read(comprasAccionesProvider).eliminar(ids);
      _salirDeSeleccion();
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.comprasEliminados(ids.length))),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.comprasErrorEliminar)),
      );
    }
  }

  // Agrega a la lista los insumos con stock bajo y avisa cuántos se sumaron.
  Future<void> _agregarSugerencias(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final agregados =
          await ref.read(comprasAccionesProvider).agregarSugerencias();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            agregados == 0
                ? AppStrings.comprasSinSugerencias
                : AppStrings.comprasSugerenciasAgregadas(agregados),
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.comprasErrorSugerencias)),
      );
    }
  }

  // Abre el panel para sumar un insumo a mano. Se ofrecen solo los que todavía
  // no están en la lista, así no se puede pedir dos veces lo mismo.
  Future<void> _agregar(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    // Si todavía están cargando, se espera; si no se pueden leer, se avisa.
    final List<Insumo> disponibles;
    try {
      final insumos = await ref.read(insumosProvider.future);
      final pendientes = await ref.read(listaCompraStreamProvider.future);
      final enLista = {for (final item in pendientes) item.productoId};
      disponibles = [
        for (final insumo in insumos)
          if (!enLista.contains(insumo.id)) insumo,
      ];
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.comprasErrorAgregar)),
      );
      return;
    }
    if (!context.mounted) return;

    if (disponibles.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.comprasTodosEnLista)),
      );
      return;
    }

    final elegido = await showDialog<NuevoItemCompra>(
      context: context,
      builder: (context) => ComprasAgregarDialog(insumos: disponibles),
    );
    // Null: se cerró sin elegir. También se sale si la pantalla ya no está,
    // porque no se puede seguir usando ref.
    if (elegido == null || !context.mounted) return;

    try {
      await ref
          .read(comprasAccionesProvider)
          .agregar(elegido.productoId, elegido.cantidad);
      final nombre =
          disponibles.firstWhere((i) => i.id == elegido.productoId).nombre;
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.comprasAgregado(nombre))),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.comprasErrorAgregar)),
      );
    }
  }

  // Pasa el ítem a comprado o descartado. La lista muestra solo los pendientes,
  // así que el ítem desaparece: el aviso trae Deshacer para que no sea una
  // sorpresa ni un error sin vuelta atrás.
  Future<void> _cambiarEstado(
    BuildContext context,
    WidgetRef ref,
    ItemCompra item,
    EstadoCompra estado,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final acciones = ref.read(comprasAccionesProvider);
    // Si se cambian varios seguidos, el aviso nuevo reemplaza al anterior.
    messenger.hideCurrentSnackBar();
    try {
      await acciones.cambiarEstado(item.id, estado);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            estado == EstadoCompra.comprado
                ? AppStrings.comprasMarcadoComprado(item.nombre)
                : AppStrings.comprasDescartado(item.nombre),
          ),
          action: SnackBarAction(
            label: AppStrings.comprasDeshacer,
            onPressed: () =>
                acciones.cambiarEstado(item.id, EstadoCompra.pendiente),
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.comprasErrorEstado)),
      );
    }
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

/// Fila bajo el encabezado. Normal: enlace de sugerencias y el tacho, que abre
/// el modo "eliminar". En ese modo: cuántos hay elegidos, "Todos", cancelar y el
/// tacho que borra los elegidos.
class _AccionesSuperiores extends StatelessWidget {
  const _AccionesSuperiores({
    required this.onSugerencias,
    required this.seleccionando,
    required this.cantidadElegidos,
    required this.hayItems,
    required this.onPapelera,
    required this.onCancelar,
    required this.onTodos,
    required this.onEliminar,
  });

  final VoidCallback? onSugerencias;
  final bool seleccionando;
  final int cantidadElegidos;
  final bool hayItems;
  final VoidCallback onPapelera;
  final VoidCallback onCancelar;
  final VoidCallback onTodos;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    if (seleccionando) {
      return Padding(
        padding: const EdgeInsets.only(left: 36, right: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.comprasSeleccionados(cantidadElegidos),
                style: AppTextStyles.link,
              ),
            ),
            TextButton(
              onPressed: hayItems ? onTodos : null,
              child: const Text(AppStrings.comprasSeleccionarTodos),
            ),
            IconButton(
              onPressed: onCancelar,
              tooltip: AppStrings.comprasCancelarSeleccion,
              icon: const Icon(Icons.close, size: 22, color: AppColors.bodyColor),
            ),
            IconButton(
              onPressed: cantidadElegidos > 0 ? onEliminar : null,
              tooltip: AppStrings.comprasEliminarSeleccionados,
              icon: Icon(
                Icons.delete,
                size: 22,
                color: cantidadElegidos > 0
                    ? AppColors.stockDanger
                    : AppColors.backIconColor,
              ),
            ),
          ],
        ),
      );
    }

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
            onPressed: hayItems ? onPapelera : null,
            tooltip: AppStrings.comprasSeleccionar,
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
