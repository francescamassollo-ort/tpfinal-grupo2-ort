import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../core/breakpoints.dart';
import '../../models/insumo.dart';
import '../../models/trabajo_practico.dart';
import '../../providers/insumo_providers.dart';
import '../../providers/trabajopractico_provider.dart';
import '../../providers/usuario_provider.dart';
import '../../widgets/campo_fecha.dart';
import '../../widgets/insumo_selector_sheet.dart';
import '../../widgets/tp_insumo_editable_card.dart';
import '../../widgets/contenido_centrado.dart';

// El stock es un entero (unidades), por eso los insumos del TP se guardan
// siempre en "u" y el diseño no trae selector de unidad.
const String _unidadPorDefecto = 'u';

// Se entra con push() desde la lista o el detalle; si se abre directo
// (sin pantalla anterior) se vuelve a la lista de TPs.
void _volver(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/tp');
  }
}

// Pantalla de alta y edición. Sin tpId = alta; con tpId = edición.
// Esta clase solo decide QUÉ mostrar: en edición espera a tener el TP
// cargado y recién ahí arma el formulario, así los campos nacen con sus
// valores iniciales y no hace falta rellenarlos después.
class TpEditarScreen extends ConsumerWidget {
  const TpEditarScreen({this.tpId, super.key});

  final String? tpId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = tpId;
    if (id == null) return const _FormularioTp();

    final tpAsync = ref.watch(tpPorIdProvider(id));
    return tpAsync.when(
      data: (tp) => tp == null
          ? const _Marco(child: Center(child: Text(AppStrings.tpNoEncontrado)))
          : _FormularioTp(tp: tp),
      loading: () =>
          const _Marco(child: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          const _Marco(child: Center(child: Text(AppStrings.tpErrorDetalle))),
    );
  }
}

// Estructura común: flecha + título arriba, contenido en el medio y, si
// corresponde, botón flotante y botón fijo abajo (el FAB queda por encima
// del botón fijo porque Scaffold lo acomoda solo).
class _Marco extends StatelessWidget {
  const _Marco({
    required this.child,
    this.floatingActionButton,
    this.botonInferior,
  });

  final Widget child;
  final Widget? floatingActionButton;
  final Widget? botonInferior;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar:
          botonInferior == null ? null : SafeArea(
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                maxWidth: Breakpoints.maxContentWidth,
                ),
              child: botonInferior!,
              ),
            ),
          ),
      body: SafeArea(
        child: ContenidoCentrado(
          child: Column(
            children: [
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
                        AppStrings.tpTitulo,
                        style: AppTextStyles.screenTitle,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// ConsumerStatefulWidget: hace falta ciclo de vida (los controllers se crean
// en initState y se liberan en dispose) y estado de VISTA del borrador
// (fecha elegida, insumos agregados, "guardando"). Guardar y leer datos va
// por los providers; la regla de stock, por TpService.
class _FormularioTp extends ConsumerStatefulWidget {
  const _FormularioTp({this.tp});

  /// null = alta.
  final TrabajoPractico? tp;

  @override
  ConsumerState<_FormularioTp> createState() => _FormularioTpState();
}

class _FormularioTpState extends ConsumerState<_FormularioTp> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late DateTime _fecha;
  late List<InsumoRequerido> _insumos;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final tp = widget.tp;
    _nombreController = TextEditingController(text: tp?.nombre ?? '');
    _descripcionController = TextEditingController(text: tp?.descripcion ?? '');
    _fecha = tp?.fecha ?? DateTime.now();
    _insumos = List.of(tp?.insumos ?? const <InsumoRequerido>[]);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  // TP armado con lo que hay en pantalla, solo para consultarle a TpService
  // qué insumos no alcanzan (la misma regla de la lista y el detalle).
  TrabajoPractico get _borrador => TrabajoPractico(
        id: '',
        nombre: '',
        descripcion: '',
        fecha: _fecha,
        docente: '',
        insumos: _insumos,
      );

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (elegida == null || !mounted) return;
    setState(() => _fecha = elegida);
  }

  Future<void> _agregarInsumo() async {
    final elegido = await showModalBottomSheet<Insumo>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => InsumoSelectorSheet(
        excluidos: {for (final i in _insumos) i.insumoId},
      ),
    );
    if (elegido == null || !mounted) return;
    setState(() {
      _insumos = [
        ..._insumos,
        InsumoRequerido(
          insumoId: elegido.id,
          cantidad: 1,
          unidad: _unidadPorDefecto,
        ),
      ];
    });
  }

  void _cambiarCantidad(String insumoId, double delta) {
    setState(() {
      _insumos = [
        for (final i in _insumos)
          if (i.insumoId == insumoId)
            InsumoRequerido(
              insumoId: i.insumoId,
              cantidad: i.cantidad + delta,
              unidad: i.unidad,
            )
          else
            i,
      ];
    });
  }

  void _quitarInsumo(String insumoId) {
    setState(() {
      _insumos = _insumos.where((i) => i.insumoId != insumoId).toList();
    });
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    if (!_formKey.currentState!.validate()) return;
    if (_insumos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.tpSinInsumosError)),
      );
      return;
    }

    setState(() => _guardando = true);
    // Se obtiene antes del await: después puede que el widget ya no exista.
    final notifier = ref.read(tpProvider.notifier);
    final usuarioService = ref.read(usuarioActualServiceProvider);
    final original = widget.tp;
    final nombre = _nombreController.text.trim();
    final descripcion = _descripcionController.text.trim();

    try {
      if (original == null) {
        // El docente es quien crea el TP, con el mismo nombre que figura en el
        // Historial (el de su documento en "usuarios", o el de su cuenta).
        final docente = (await usuarioService.obtener()).nombre;
        await notifier.crear(
          TrabajoPractico(
            id: '', // lo genera Firestore
            nombre: nombre,
            descripcion: descripcion,
            fecha: _fecha,
            insumos: _insumos,
            docente: docente,
          ),
        );
      } else {
        // En edición se conserva el docente que creó el TP.
        await notifier.actualizar(
          original.copyWith(
            nombre: nombre,
            descripcion: descripcion,
            fecha: _fecha,
            insumos: _insumos,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.tpErrorGuardar)),
      );
      return;
    }
    if (!mounted) return;
    _volver(context);
  }

  @override
  Widget build(BuildContext context) {
    final insumosAsync = ref.watch(insumosProvider);

    return _Marco(
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarInsumo,
        tooltip: AppStrings.tpAgregarInsumo,
        child: const Icon(Icons.add),
      ),
      botonInferior: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    AppStrings.tpGenerarLista,
                    style: AppTextStyles.button(Colors.white),
                  ),
          ),
        ),
      ),
      child: Form(
        key: _formKey,
        // Todo scrollea junto; la lista de insumos es un SliverList.builder
        // (se construye bajo demanda) y cada ítem es un widget aparte.
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      style: AppTextStyles.screenTitle,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: AppStrings.tpNombreHint,
                        filled: false,
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.bodyColor),
                        ),
                      ),
                      validator: (valor) =>
                          (valor == null || valor.trim().isEmpty)
                              ? AppStrings.tpNombreRequerido
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descripcionController,
                      minLines: 2,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: AppStrings.tpDescripcionHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CampoFecha(fecha: _fecha, onTap: _elegirFecha),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _Aviso(
                _insumos.isEmpty
                    ? AppStrings.tpInsumosVacios
                    : AppStrings.tpDeslizarParaQuitar,
              ),
            ),
            insumosAsync.when(
              data: _listaInsumos,
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, stack) => const SliverToBoxAdapter(
                child: Center(child: Text(AppStrings.tpErrorDisponibilidad)),
              ),
            ),
            // Espacio para que el botón flotante no tape la última tarjeta.
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }

  Widget _listaInsumos(List<Insumo> insumos) {
    final porId = {for (final i in insumos) i.id: i};
    final faltantes = ref
        .watch(tpServiceProvider)
        .verificarDisponibilidad(
          _borrador,
          {for (final i in insumos) i.id: i.stock},
        )
        .faltantes;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.builder(
        itemCount: _insumos.length,
        itemBuilder: (context, index) {
          final requerido = _insumos[index];
          final insumo = porId[requerido.insumoId];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            // Deslizar hacia la izquierda quita el insumo del TP.
            child: Dismissible(
              key: ValueKey(requerido.insumoId),
              direction: DismissDirection.endToStart,
              background: const _FondoQuitar(),
              onDismissed: (_) => _quitarInsumo(requerido.insumoId),
              child: TpInsumoEditableCard(
                nombre: insumo?.nombre ?? AppStrings.tpInsumoNoEncontrado,
                stock: insumo?.stock ?? 0,
                cantidad: requerido.cantidad,
                falta: faltantes.containsKey(requerido.insumoId),
                onDisminuir: () => _cambiarCantidad(requerido.insumoId, -1),
                onAumentar: () => _cambiarCantidad(requerido.insumoId, 1),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Texto chico de ayuda sobre la lista de insumos.
class _Aviso extends StatelessWidget {
  const _Aviso(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Text(texto, style: AppTextStyles.itemDetail),
    );
  }
}

// Fondo rojo con tacho que aparece detrás de la tarjeta al deslizarla.
class _FondoQuitar extends StatelessWidget {
  const _FondoQuitar();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: AppColors.stockDanger,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }
}