import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../models/usuario.dart';
import '../../providers/role_provider.dart';
import '../../providers/tp_busqueda_provider.dart';
import '../../providers/trabajopractico_provider.dart';
import '../../widgets/tp_card.dart';

// ConsumerStatefulWidget: hace falta estado de VISTA (buscador visible,
// modo selección y qué TPs están marcados). El estado de negocio (la lista,
// el filtro) vive en los providers.
class TpListaScreen extends ConsumerStatefulWidget {
  const TpListaScreen({super.key});

  @override
  ConsumerState<TpListaScreen> createState() => _TpListaScreenState();
}

class _TpListaScreenState extends ConsumerState<TpListaScreen> {
  bool _mostrarBusqueda = false;
  bool _modoSeleccion = false;
  final Set<String> _seleccionados = {};
  final _busquedaController = TextEditingController();

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void _alternarBusqueda() {
    setState(() => _mostrarBusqueda = !_mostrarBusqueda);
    if (!_mostrarBusqueda) {
      // Al cerrar el buscador se descarta el filtro.
      _busquedaController.clear();
      ref.read(tpBusquedaProvider.notifier).setTexto('');
    }
  }

  // Papelera: entra y sale del modo selección. Al salir se desmarca todo.
  void _alternarModoSeleccion() {
    setState(() {
      _modoSeleccion = !_modoSeleccion;
      _seleccionados.clear();
    });
  }

  void _alternarSeleccionado(String id) {
    setState(() {
      if (!_seleccionados.remove(id)) _seleccionados.add(id);
    });
  }

  // Pide confirmación y desactiva (borrado lógico) los TPs marcados.
  Future<void> _confirmarEliminacion() async {
    final ids = _seleccionados.toList();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.tpEliminarTitulo),
        content: Text(AppStrings.tpEliminarMensaje(ids.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.tpCancelar),
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
      for (final id in ids) {
        await notifier.desactivar(id);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.tpErrorEliminar)),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _seleccionados.clear();
      _modoSeleccion = false;
    });
  }

  // Se entra desde el drawer con go(), así que puede no haber nada para
  // "volver": en ese caso se va a Inventario.
  void _volver() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/inventario');
    }
  }

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(tpProvider);
    // La lista ya filtrada por nombre: la pantalla solo la dibuja.
    final filtradosAsync = ref.watch(tpsFiltradosProvider);
    final role = ref.watch(roleProvider);
    // Solo admin y docente editan y eliminan TPs.
    final puedeEditar =
        role == UserRole.administrador || role == UserRole.docente;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  iconSize: 32,
                  color: AppColors.backIconColor,
                  tooltip: AppStrings.volver,
                  onPressed: _volver,
                ),
                Expanded(
                  child: Text(
                    AppStrings.tpTitulo,
                    style: AppTextStyles.screenTitle,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (_modoSeleccion) ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        AppStrings.tpSeleccionados(_seleccionados.length),
                        style: AppTextStyles.itemDetail,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed:
                        _seleccionados.isEmpty ? null : _confirmarEliminacion,
                    child: const Text(AppStrings.tpEliminar),
                  ),
                ] else
                  const Spacer(),
                IconButton(
                  icon: const Icon(Icons.search),
                  color: AppColors.titleColor,
                  tooltip: AppStrings.buscar,
                  onPressed: _alternarBusqueda,
                ),
                if (puedeEditar)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    // Rojo mientras el modo selección está activo.
                    color: _modoSeleccion
                        ? AppColors.stockDanger
                        : AppColors.titleColor,
                    tooltip: AppStrings.papelera,
                    onPressed: _alternarModoSeleccion,
                  ),
              ],
            ),
            if (_mostrarBusqueda)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _busquedaController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: AppStrings.tpBuscarHint,
                    prefixIcon: Icon(Icons.search),
                  ),
                  // read (no watch): solo se llama al método del Notifier.
                  onChanged: (texto) {
                    ref.read(tpBusquedaProvider.notifier).setTexto(texto);
                    // Al cambiar la búsqueda se descarta la selección para
                    // no eliminar TPs que quedaron ocultos por el filtro.
                    if (_seleccionados.isNotEmpty) {
                      setState(_seleccionados.clear);
                    }
                  },
                ),
              ),
            Expanded(
              child: filtradosAsync.when(
                data: (tps) {
                  if (todosAsync.value?.isEmpty ?? true) {
                    return const Center(child: Text(AppStrings.tpVacia));
                  }
                  if (tps.isEmpty) {
                    return const Center(
                      child: Text(AppStrings.tpSinResultados),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(tpProvider);
                      await ref.read(tpProvider.future);
                    },
                    child: ListView.builder(
                      // Espacio abajo para que el botón flotante no tape
                      // la última tarjeta.
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: tps.length,
                      itemBuilder: (context, index) {
                        final tp = tps[index];
                        return TpCard(
                          tp: tp,
                          modoSeleccion: _modoSeleccion,
                          seleccionado: _seleccionados.contains(tp.id),
                          // En modo selección tocar marca/desmarca; si no,
                          // push (no go) apila el detalle, así "volver"
                          // regresa a la lista. Solo viaja el id.
                          onTap: _modoSeleccion
                              ? () => _alternarSeleccionado(tp.id)
                              : () => context.push('/tp/detalle/${tp.id}'),
                          onEditar: puedeEditar
                              ? () => context.push('/tp/editar/${tp.id}')
                              : null,
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    const Center(child: Text(AppStrings.tpError)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/*
class TpListaScreen extends StatelessWidget {
  const TpListaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Lista para trabajos prácticos'));
  }
}
*/