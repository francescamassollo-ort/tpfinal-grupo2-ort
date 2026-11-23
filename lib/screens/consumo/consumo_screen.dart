import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../models/insumo.dart';
import '../../providers/insumo_providers.dart';
import '../../providers/stock_provider.dart';
import '../../services/stock_logica.dart';
import '../../widgets/app_action_button.dart';
import '../../widgets/app_decorative_background.dart';
import '../../widgets/app_screen_header.dart';
import '../../widgets/insumo_etiquetas.dart';
import 'consumo_agregar_dialog.dart';
import 'consumo_tile.dart';

/// Registro de consumo: se arma una lista de insumos con cuánto retirar de cada
/// uno y se confirma toda junta. Va fuera del AppShell (sin barra inferior ni
/// botón flotante), como en el diseño.
///
/// Si se pasa [insumoId], la lista arranca con ese insumo, por ejemplo cuando
/// se llega desde el detalle de un insumo o desde el aviso de duplicados de
/// Alta. Un id que no corresponde a ningún insumo se ignora.
///
/// Confirmar es todo o nada: si falta stock de uno solo, no se registra ninguno.
class ConsumoScreen extends ConsumerStatefulWidget {
  const ConsumoScreen({this.insumoId, super.key});

  final String? insumoId;

  @override
  ConsumerState<ConsumoScreen> createState() => _ConsumoScreenState();
}

// Una línea de la lista: qué insumo y cuánto retirar.
class _Linea {
  _Linea(this.insumoId, this.cantidad);

  final String insumoId;
  int cantidad;
}

class _ConsumoScreenState extends ConsumerState<ConsumoScreen> {
  static const _motivos = [
    AppStrings.consumoMotivoTp,
    AppStrings.consumoMotivoClase,
    AppStrings.consumoMotivoInvestigacion,
    AppStrings.consumoMotivoOtro,
  ];

  late final List<_Linea> _lineas = [
    if (widget.insumoId != null) _Linea(widget.insumoId!, 1),
  ];

  String _motivo = AppStrings.consumoMotivoTp;
  final _detalleController = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _detalleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insumos = ref.watch(insumosProvider);

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: AppDecorativeBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppScreenHeader(
                title: AppStrings.consumoTitulo,
                onBack: _volver,
              ),
              Expanded(
                child: insumos.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text(
                      AppStrings.consumoErrorCargar,
                      style: AppTextStyles.listItemSubtitle,
                    ),
                  ),
                  data: _contenido,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(36, 8, 36, 24),
                child: AppActionButton(
                  label: AppStrings.consumoConfirmar,
                  // Sin insumos que retirar, o mientras se guarda, no hace
                  // nada: así un doble toque no registra dos veces.
                  onPressed: _lineas.isEmpty || _guardando
                      ? null
                      : () => _confirmar(insumos.value ?? const []),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contenido(List<Insumo> insumos) {
    final porId = {for (final insumo in insumos) insumo.id: insumo};
    // Un insumo que ya no existe no se puede retirar: se saca de la lista.
    _lineas.removeWhere((linea) => !porId.containsKey(linea.insumoId));
    final etiquetas = etiquetasDeInsumos(insumos);

    return ListView(
      padding: const EdgeInsets.fromLTRB(36, 8, 36, 20),
      children: [
        Text(
          AppStrings.consumoSubtitulo,
          style: AppTextStyles.listItemSubtitle,
        ),
        const SizedBox(height: 12),
        for (final linea in _lineas) ...[
          _filaQuitable(
            linea,
            porId[linea.insumoId]!,
            etiquetas[linea.insumoId]!,
          ),
          const SizedBox(height: 12),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _agregar(insumos),
            child: Text(
              AppStrings.consumoAgregarOtro,
              style: AppTextStyles.link,
            ),
          ),
        ),
        if (_lineas.isNotEmpty) ..._motivoYDetalle(),
      ],
    );
  }

  // Cada fila se puede sacar de la lista deslizándola hacia la izquierda.
  Widget _filaQuitable(_Linea linea, Insumo insumo, String nombre) {
    return Dismissible(
      key: ValueKey(linea.insumoId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => setState(() => _lineas.remove(linea)),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.stockDanger,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: ConsumoTile(
        nombre: nombre,
        disponible: insumo.stock,
        unidad: insumo.unidad ?? AppStrings.consumoUnidadPorDefecto,
        cantidad: linea.cantidad,
        onCambiar: (cantidad) => setState(() => linea.cantidad = cantidad),
      ),
    );
  }

  // El diseño no dibuja el motivo, pero el consumo lo necesita: queda debajo
  // de la lista, antes del botón.
  List<Widget> _motivoYDetalle() {
    return [
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        initialValue: _motivo,
        decoration: const InputDecoration(labelText: AppStrings.consumoMotivo),
        items: [
          for (final motivo in _motivos)
            DropdownMenuItem(value: motivo, child: Text(motivo)),
        ],
        onChanged: (valor) {
          if (valor != null) setState(() => _motivo = valor);
        },
      ),
      if (_motivo == AppStrings.consumoMotivoOtro) ...[
        const SizedBox(height: 12),
        TextField(
          controller: _detalleController,
          decoration: const InputDecoration(
            labelText: AppStrings.consumoDetalleMotivo,
          ),
        ),
      ],
    ];
  }

  // Abre el buscador con los insumos que todavía se pueden agregar: los que
  // tienen stock y no están ya en la lista.
  Future<void> _agregar(List<Insumo> insumos) async {
    final enLista = {for (final linea in _lineas) linea.insumoId};
    final disponibles = [
      for (final insumo in insumos)
        if (insumo.stock > 0 && !enLista.contains(insumo.id)) insumo,
    ];

    if (disponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.consumoSinMasInsumos)),
      );
      return;
    }

    final elegido = await ConsumoAgregarDialog.mostrar(context, disponibles);
    if (elegido == null || !mounted) return;
    setState(() => _lineas.add(_Linea(elegido.id, 1)));
  }

  Future<void> _confirmar(List<Insumo> insumos) async {
    final messenger = ScaffoldMessenger.of(context);
    final motivo = _motivo == AppStrings.consumoMotivoOtro
        ? _detalleController.text.trim()
        : _motivo;
    if (motivo.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.consumoDetalleObligatorio)),
      );
      return;
    }

    final lineas = [
      for (final linea in _lineas)
        (insumoId: linea.insumoId, cantidad: linea.cantidad),
    ];

    setState(() => _guardando = true);
    try {
      await ref.read(stockServiceProvider).registrarSalidas(lineas, motivo);
      if (!mounted) return;
      // Salió todo: la lista queda vacía para poder cargar otro consumo.
      setState(() {
        _lineas.clear();
        _motivo = AppStrings.consumoMotivoTp;
        _detalleController.clear();
      });
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.consumoRegistrado)),
      );
    } on StockException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(_mensajeDe(error, insumos))),
      );
    } catch (error) {
      debugPrint('No se pudo registrar el consumo: $error');
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.consumoError)),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // Dice de qué insumo se trata cuando el problema es de una línea.
  String _mensajeDe(StockException error, List<Insumo> insumos) {
    final nombre = insumos
        .where((insumo) => insumo.id == error.insumoId)
        .map((insumo) => insumo.nombre)
        .firstOrNull;
    if (nombre == null) return error.mensaje;

    return switch (error.mensaje) {
      StockLogica.mensajeStockInsuficiente =>
        AppStrings.consumoSinStock(nombre),
      StockLogica.mensajeInsumoNoEncontrado =>
        AppStrings.consumoInsumoNoExiste(nombre),
      _ => '$nombre: ${error.mensaje}',
    };
  }

  // Si se llegó desde otra pantalla vuelve atrás; si no, vuelve a Inventario.
  void _volver() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/inventario');
    }
  }
}
