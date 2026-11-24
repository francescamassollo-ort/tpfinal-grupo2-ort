import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../models/importacion.dart';
import '../../providers/importacion_provider.dart';
import '../../providers/insumo_providers.dart';
import '../../providers/ubicacion_providers.dart';
import '../../services/importador_de_insumos.dart';
import '../../services/lector_excel.dart';
import '../../services/plan_de_importacion.dart';
import '../../widgets/app_screen_header.dart';

/// Importar el inventario desde un Excel (R19, carga inicial). Solo para el
/// administrador.
///
/// Tres pasos: elegir el archivo, ver qué se va a cargar (cuántos insumos, cuáles
/// se saltan por estar repetidos, qué avisos hay) y confirmar. Nada se guarda
/// hasta confirmar.
class ImportarExcelScreen extends ConsumerStatefulWidget {
  const ImportarExcelScreen({super.key});

  @override
  ConsumerState<ImportarExcelScreen> createState() => _ImportarExcelScreenState();
}

enum _Paso { inicio, leyendo, vistaPrevia, importando, listo }

class _ImportarExcelScreenState extends ConsumerState<ImportarExcelScreen> {
  _Paso _paso = _Paso.inicio;
  ResultadoLectura? _lectura;
  PlanDeImportacion? _plan;
  int _cargados = 0;
  int _cargadosCuenta = 0;

  @override
  void initState() {
    super.initState();
    // El plan compara contra lo que ya está cargado: se mantienen escuchadas las
    // dos listas mientras la pantalla está abierta, para tenerlas listas cuando
    // se elige el archivo. No redibuja nada.
    ref.listenManual(insumosProvider, (previous, next) {});
    ref.listenManual(ubicacionesProvider, (previous, next) {});
  }

  void _volver() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/inventario');
    }
  }

  void _avisar(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _elegirArchivo() async {
    // El plan compara contra lo que ya está cargado: hace falta tenerlo.
    final existentes = ref.read(insumosProvider).value;
    final ubicaciones = ref.read(ubicacionesProvider).value;
    if (existentes == null || ubicaciones == null) {
      _avisar(AppStrings.importarCargandoDatos);
      return;
    }

    final bytes = await ref.read(selectorDeExcelProvider)();
    if (bytes == null || !mounted) return;

    setState(() => _paso = _Paso.leyendo);
    // Deja que se dibuje el "Leyendo…" antes del trabajo pesado.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    try {
      final lectura = ImportadorDeInsumos.leer(LectorExcel.leer(bytes));
      final plan = PlanDeImportacion.armar(
        importados: lectura.insumos,
        existentes: existentes,
        ubicaciones: [for (final u in ubicaciones) u.nombre],
      );
      if (!mounted) return;
      setState(() {
        _lectura = lectura;
        _plan = plan;
        _paso = _Paso.vistaPrevia;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _paso = _Paso.inicio);
      _avisar(AppStrings.importarArchivoInvalido);
    }
  }

  Future<void> _importar() async {
    final plan = _plan;
    if (plan == null || plan.nuevos.isEmpty) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.importarConfirmarTitulo),
        content: Text(AppStrings.importarConfirmarMensaje(plan.nuevos.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.importarConfirmar),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() {
      _paso = _Paso.importando;
      _cargados = 0;
    });
    try {
      final cargados = await ref.read(importacionServiceProvider).importar(
            plan,
            alAvanzar: (hechos, total) {
              if (mounted) setState(() => _cargados = hechos);
            },
          );
      if (!mounted) return;
      setState(() {
        _cargadosCuenta = cargados;
        _paso = _Paso.listo;
      });
    } catch (_) {
      if (!mounted) return;
      // Lo que ya se cargó queda cargado; al volver a elegir el archivo, eso
      // cuenta como repetido y no se duplica.
      setState(() => _paso = _Paso.inicio);
      _avisar(AppStrings.importarError);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.screenBackground,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppScreenHeader(title: AppStrings.importarTitulo, onBack: _volver),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: switch (_paso) {
                  _Paso.inicio => _inicio(),
                  _Paso.leyendo => [
                      const SizedBox(height: 48),
                      const Center(child: CircularProgressIndicator()),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.importarLeyendo,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.itemDetail,
                      ),
                    ],
                  _Paso.vistaPrevia => _vistaPrevia(),
                  _Paso.importando => _importando(),
                  _Paso.listo => _listo(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _inicio() => [
        Text(AppStrings.importarExplicacion, style: AppTextStyles.itemDetail),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _elegirArchivo,
          icon: const Icon(Icons.upload_file),
          label: const Text(AppStrings.importarElegir),
        ),
      ];

  List<Widget> _vistaPrevia() {
    final lectura = _lectura!;
    final plan = _plan!;
    final sinStock = plan.nuevos.where((i) => i.stock == 0).length;

    return [
      _Dato(Icons.add_circle_outline, AppStrings.importarNuevos(plan.nuevos.length)),
      if (plan.repetidos > 0)
        _Dato(Icons.copy_all_outlined, AppStrings.importarRepetidos(plan.repetidos)),
      if (plan.ubicacionesNuevas.isNotEmpty)
        _Dato(
          Icons.place_outlined,
          AppStrings.importarUbicacionesNuevas(plan.ubicacionesNuevas.length),
        ),
      if (sinStock > 0)
        _Dato(Icons.remove_shopping_cart_outlined, AppStrings.importarSinStock(sinStock)),
      _Dato(
        Icons.table_chart_outlined,
        AppStrings.importarHojas(lectura.hojasLeidas.length),
      ),
      if (lectura.hojasIgnoradas.isNotEmpty)
        _Dato(
          Icons.warning_amber_outlined,
          AppStrings.importarHojasIgnoradas(lectura.hojasIgnoradas.join(', ')),
        ),
      if (lectura.avisos.isNotEmpty) ...[
        const SizedBox(height: 8),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(AppStrings.importarAvisos(lectura.avisos.length)),
          subtitle: const Text(AppStrings.importarAvisosAyuda),
          children: [
            for (final aviso in lectura.avisos.take(_maxAvisos))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('$aviso', style: AppTextStyles.listItemSubtitle),
              ),
            if (lectura.avisos.length > _maxAvisos)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  AppStrings.importarAvisosMas(lectura.avisos.length - _maxAvisos),
                  style: AppTextStyles.listItemSubtitle,
                ),
              ),
          ],
        ),
      ],
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: plan.nuevos.isEmpty ? null : _importar,
        child: Text(AppStrings.importarBoton(plan.nuevos.length)),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: () => setState(() => _paso = _Paso.inicio),
        child: const Text(AppStrings.importarOtroArchivo),
      ),
    ];
  }

  List<Widget> _importando() {
    final total = _plan?.nuevos.length ?? 0;
    return [
      const SizedBox(height: 48),
      LinearProgressIndicator(value: total == 0 ? null : _cargados / total),
      const SizedBox(height: 16),
      Text(
        AppStrings.importarProgreso(_cargados, total),
        textAlign: TextAlign.center,
        style: AppTextStyles.itemDetail,
      ),
    ];
  }

  List<Widget> _listo() => [
        const SizedBox(height: 24),
        const Icon(Icons.check_circle, size: 64, color: AppColors.stockOk),
        const SizedBox(height: 16),
        Text(
          AppStrings.importarListo(_cargadosCuenta),
          textAlign: TextAlign.center,
          style: AppTextStyles.screenTitle,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => context.go('/inventario'),
          child: const Text(AppStrings.importarIrAlInventario),
        ),
      ];

  static const int _maxAvisos = 40;
}

class _Dato extends StatelessWidget {
  const _Dato(this.icono, this.texto);

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 22, color: AppColors.movementBlue),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: AppTextStyles.itemName)),
        ],
      ),
    );
  }
}
