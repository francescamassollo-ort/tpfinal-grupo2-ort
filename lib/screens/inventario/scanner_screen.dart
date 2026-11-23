import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../models/datos_escaneados.dart';
import '../../models/insumo.dart';
import '../../models/resultado_codigo.dart';
import '../../providers/barcode_provider.dart';
import '../../providers/insumo_providers.dart';
import '../../providers/stock_provider.dart';
import '../../services/barcode_service.dart';
import '../../services/stock_logica.dart';
import '../../widgets/app_action_button.dart';
import '../../widgets/camara_escaner.dart';
import 'sumar_stock_dialog.dart';

/// Escáner de código de barras. Va fuera del AppShell (cámara a pantalla
/// completa, sin barra inferior), como en el diseño.
///
/// Al leer un código, lo busca (ver [BarcodeService]) y muestra abajo qué
/// encontró:
/// - **Un insumo que ya tenemos:** "Sumar stock" (para no crear un duplicado) o
///   "Editar" (abre su detalle).
/// - **Un producto que conoce una base externa:** nombre, marca, fórmula y peso
///   molecular como sugerencia editable; "Usar estos datos" vuelve al Alta con
///   todo precargado.
/// - **Nada:** "Cargar a mano" vuelve al Alta con solo el código.
///
/// Devuelve un [DatosEscaneados] cuando hay que completar el Alta, o null si se
/// vuelve sin elegir nada.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({
    this.camaraBuilder = CamaraEscaner.construir,
    super.key,
  });

  /// Cómo se arma la cámara. Se reemplaza en las pruebas.
  final ConstructorDeCamara camaraBuilder;

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  String? _codigo;
  ResultadoCodigo? _resultado;
  bool _buscando = false;

  // Cambia al escanear de nuevo, para que la cámara se arme otra vez.
  int _intento = 0;

  final _nombreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Mantiene cargada la lista de insumos mientras se escanea, para poder
    // buscar el código entre ellos. No redibuja nada.
    ref.listenManual(insumosProvider, (previous, next) {});
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          KeyedSubtree(
            key: ValueKey(_intento),
            child: widget.camaraBuilder(context, _alLeerCodigo),
          ),
          const IgnorePointer(child: Center(child: _Marco())),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 14, top: 8),
                child: IconButton(
                  onPressed: _volver,
                  tooltip: AppStrings.volver,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Align(alignment: Alignment.bottomCenter, child: _panel()),
        ],
      ),
    );
  }

  Widget _panel() {
    final resultado = _resultado;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.screenBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: switch ((_buscando, resultado)) {
        (true, _) => _buscandoPanel(),
        (false, null) => Text(
            AppStrings.escanerIndicacion,
            textAlign: TextAlign.center,
            style: AppTextStyles.listItemSubtitle,
          ),
        (false, CodigoEnInventario(:final insumo)) => _enInventarioPanel(insumo),
        (false, final CodigoConocido conocido) => _conocidoPanel(conocido),
        (false, final CodigoSinResultado sinResultado) =>
          _sinResultadoPanel(sinResultado),
      },
    );
  }

  Widget _buscandoPanel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        // Flexible: con una letra grande el texto baja de renglón en vez de
        // desbordar.
        Flexible(
          child: Text(
            AppStrings.escanerBuscando,
            style: AppTextStyles.listItemSubtitle,
          ),
        ),
      ],
    );
  }

  Widget _enInventarioPanel(Insumo insumo) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.escanerCodigoAutocompletado,
          style: AppTextStyles.listItemSubtitle,
        ),
        const SizedBox(height: 4),
        Text(insumo.nombre, style: AppTextStyles.screenTitle),
        Text(
          AppStrings.escanerStockActual(
            insumo.stock,
            insumo.unidad ?? AppStrings.escanerUnidadPorDefecto,
          ),
          style: AppTextStyles.listItemSubtitle,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppActionButton(
                label: AppStrings.escanerEditar,
                variant: AppActionButtonVariant.secondary,
                onPressed: () => context.pushReplacement('/insumo/${insumo.id}'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppActionButton(
                label: AppStrings.escanerSumarStock,
                onPressed: () => _sumarStock(insumo),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _conocidoPanel(CodigoConocido conocido) {
    final detalles = [
      if (conocido.marca != null) conocido.marca!,
      if (conocido.formula != null) AppStrings.escanerFormula(conocido.formula!),
      if (conocido.pesoMolecular != null)
        AppStrings.escanerPesoMolecular(conocido.pesoMolecular!),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.escanerCodigoAutocompletado,
          style: AppTextStyles.listItemSubtitle,
        ),
        const SizedBox(height: 8),
        // El nombre viene de una base externa y puede venir en otro idioma o
        // con ruido: se puede corregir antes de usarlo.
        TextField(
          controller: _nombreController,
          decoration: const InputDecoration(
            labelText: AppStrings.escanerCampoNombre,
          ),
        ),
        if (detalles.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(detalles.join(' · '), style: AppTextStyles.listItemSubtitle),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppActionButton(
                label: AppStrings.escanerEscanearDeNuevo,
                variant: AppActionButtonVariant.secondary,
                onPressed: _escanearDeNuevo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppActionButton(
                label: AppStrings.escanerUsarDatos,
                onPressed: () => _usarDatos(conocido),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sinResultadoPanel(CodigoSinResultado sinResultado) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.escanerCodigoDetectado,
          style: AppTextStyles.listItemSubtitle,
        ),
        const SizedBox(height: 4),
        Text(AppStrings.escanerNoEncontrado, style: AppTextStyles.screenTitle),
        // Si la búsqueda en internet no se pudo hacer, se dice por qué: no es
        // que el código no exista.
        if (sinResultado.aviso != null) ...[
          const SizedBox(height: 4),
          Text(sinResultado.aviso!, style: AppTextStyles.listItemSubtitle),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppActionButton(
                label: AppStrings.escanerEscanearDeNuevo,
                variant: AppActionButtonVariant.secondary,
                onPressed: _escanearDeNuevo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppActionButton(
                label: AppStrings.escanerCargarAMano,
                onPressed: () => context.pop(DatosEscaneados(codigo: _codigo!)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _alLeerCodigo(String codigo) async {
    setState(() {
      _codigo = codigo;
      _resultado = null;
      _buscando = true;
    });

    final insumos = ref.read(insumosProvider).value ?? const <Insumo>[];
    ResultadoCodigo resultado;
    try {
      resultado =
          await ref.read(barcodeServiceProvider).buscar(codigo, insumos: insumos);
    } catch (error) {
      // El servicio no debería fallar, pero la cámara no puede quedar colgada
      // en "buscando": se sigue como si no hubiera resultado.
      debugPrint('No se pudo buscar el código $codigo: $error');
      resultado = const CodigoSinResultado(aviso: BarcodeService.avisoError);
    }
    if (!mounted) return;

    setState(() {
      _buscando = false;
      _resultado = resultado;
      if (resultado is CodigoConocido) _nombreController.text = resultado.nombre;
    });
  }

  // Descarta lo leído y vuelve a armar la cámara para leer otro código.
  void _escanearDeNuevo() {
    setState(() {
      _codigo = null;
      _resultado = null;
      _buscando = false;
      _nombreController.clear();
      _intento++;
    });
  }

  void _usarDatos(CodigoConocido conocido) {
    final nombre = _nombreController.text.trim();
    context.pop(
      DatosEscaneados(
        codigo: _codigo!,
        nombre: nombre.isEmpty ? null : nombre,
        marca: conocido.marca,
        formula: conocido.formula,
        pesoMolecular: conocido.pesoMolecular,
      ),
    );
  }

  Future<void> _sumarStock(Insumo insumo) async {
    final messenger = ScaffoldMessenger.of(context);
    final cantidad = await SumarStockDialog.mostrar(context, insumo);
    if (cantidad == null || !mounted) return;

    try {
      await ref.read(stockServiceProvider).registrarEntrada(
            insumo.id,
            cantidad,
            AppStrings.escanerMotivoReposicion,
          );
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppStrings.escanerStockSumado(cantidad, insumo.nombre)),
        ),
      );
      if (mounted) _volver();
    } on StockException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.mensaje)));
    } catch (error) {
      debugPrint('No se pudo sumar el stock: $error');
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.escanerErrorSumar)),
      );
    }
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

/// El marco de esquinas donde se apunta al código, según el diseño.
class _Marco extends StatelessWidget {
  const _Marco();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 280,
      height: 160,
      child: CustomPaint(painter: _MarcoPainter()),
    );
  }
}

class _MarcoPainter extends CustomPainter {
  const _MarcoPainter();

  static const double _largo = 28;

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.square;

    void esquina(Offset punta, Offset horizontal, Offset vertical) {
      canvas
        ..drawLine(punta, punta + horizontal, pincel)
        ..drawLine(punta, punta + vertical, pincel);
    }

    esquina(Offset.zero, const Offset(_largo, 0), const Offset(0, _largo));
    esquina(Offset(size.width, 0), const Offset(-_largo, 0), const Offset(0, _largo));
    esquina(Offset(0, size.height), const Offset(_largo, 0), const Offset(0, -_largo));
    esquina(
      Offset(size.width, size.height),
      const Offset(-_largo, 0),
      const Offset(0, -_largo),
    );
  }

  @override
  bool shouldRepaint(_MarcoPainter oldDelegate) => false;
}
