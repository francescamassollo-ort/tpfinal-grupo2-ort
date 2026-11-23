import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../models/insumo.dart';
import '../../models/sugerencia_categoria.dart';
import '../../providers/insumo_providers.dart';
import '../../providers/sinonimos_provider.dart';
import '../../services/category_suggestion_service.dart';
import '../../services/modelo_de_lenguaje.dart';
import '../../services/similitud_texto.dart';

/// La categoría que se sugiere debajo del campo Categoría del Alta, mientras se
/// escribe el nombre (y la fórmula). Tocar "Usar" la copia al campo.
///
/// Primero muestra lo que se sabe sin internet: la categoría de un insumo
/// parecido o la que dicen las reglas. Si no hay ninguna y hay un modelo de
/// lenguaje configurado, ofrece "Sugerir con IA": recién ahí se le manda el
/// nombre al modelo, así que no gasta nada mientras se escribe.
///
/// No sugiere nada cuando el campo Categoría ya tiene algo escrito: la persona
/// ya decidió.
class SugerenciaDeCategoria extends ConsumerStatefulWidget {
  const SugerenciaDeCategoria({
    required this.nombreController,
    required this.formulaController,
    required this.categoriaController,
    super.key,
  });

  final TextEditingController nombreController;
  final TextEditingController formulaController;
  final TextEditingController categoriaController;

  @override
  ConsumerState<SugerenciaDeCategoria> createState() =>
      _SugerenciaDeCategoriaState();
}

class _SugerenciaDeCategoriaState extends ConsumerState<SugerenciaDeCategoria> {
  // La respuesta de la IA vale solo para el nombre con el que se pidió.
  SugerenciaCategoria? _deIa;
  String? _nombreDeLaIa;
  bool _consultando = false;
  String? _aviso;

  @override
  Widget build(BuildContext context) {
    final insumos = ref.watch(insumosProvider).value ?? const <Insumo>[];
    final hayIa = ref.watch(modeloDeLenguajeProvider) != null;

    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.nombreController,
        widget.formulaController,
        widget.categoriaController,
      ]),
      builder: (context, _) {
        // Con algo escrito en Categoría no se molesta.
        if (widget.categoriaController.text.trim().isNotEmpty) {
          return const SizedBox.shrink();
        }

        final nombre = widget.nombreController.text;
        final clave = SimilitudTexto.normalizar(nombre);
        if (clave.length < 3) return const SizedBox.shrink();

        final deIa = _nombreDeLaIa == clave ? _deIa : null;
        final sugerencia = deIa ??
            CategorySuggestionService.sugerir(
              nombre,
              formula: widget.formulaController.text,
              insumos: insumos,
            );

        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: sugerencia != null
              ? _fila(sugerencia)
              : _sinSugerencia(hayIa, clave, nombre, insumos),
        );
      },
    );
  }

  Widget _fila(SugerenciaCategoria sugerencia) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${AppStrings.categoriaSugerida(sugerencia.categoria)} '
            '(${_origen(sugerencia.origen)})',
            style: AppTextStyles.listItemSubtitle,
          ),
        ),
        TextButton(
          onPressed: () => widget.categoriaController.text = sugerencia.categoria,
          child: const Text(AppStrings.categoriaUsar),
        ),
      ],
    );
  }

  // Ninguna regla ni insumo parecido sabe: si hay IA, se ofrece preguntarle.
  Widget _sinSugerencia(
    bool hayIa,
    String clave,
    String nombre,
    List<Insumo> insumos,
  ) {
    if (_consultando) {
      return Text(
        AppStrings.categoriaConsultandoIa,
        style: AppTextStyles.listItemSubtitle,
      );
    }
    if (!hayIa) return const SizedBox.shrink();

    // Un aviso de un pedido anterior solo vale para ese mismo nombre.
    final aviso = _nombreDeLaIa == clave ? _aviso : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => _preguntarALaIa(clave, nombre, insumos),
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: const Text(AppStrings.categoriaPedirIa),
        ),
        if (aviso != null) Text(aviso, style: AppTextStyles.listItemSubtitle),
      ],
    );
  }

  Future<void> _preguntarALaIa(
    String clave,
    String nombre,
    List<Insumo> insumos,
  ) async {
    final servicio = CategorySuggestionService(ref.read(modeloDeLenguajeProvider));
    setState(() {
      _consultando = true;
      _aviso = null;
    });

    SugerenciaCategoria? resultado;
    String? aviso;
    try {
      resultado = await servicio.sugerirConIa(
        nombre,
        formula: widget.formulaController.text,
        categoriasExistentes: [
          for (final insumo in insumos)
            if (insumo.categoria != null) insumo.categoria!,
        ],
      );
      if (resultado == null) aviso = AppStrings.categoriaIaSinRespuesta;
    } on ModeloDeLenguajeException catch (error) {
      debugPrint('No se pudo sugerir la categoría con IA: $error');
      aviso = AppStrings.categoriaIaError;
    }
    if (!mounted) return;

    setState(() {
      _consultando = false;
      _deIa = resultado;
      _nombreDeLaIa = clave;
      _aviso = aviso;
    });
  }

  String _origen(OrigenSugerencia origen) => switch (origen) {
        OrigenSugerencia.insumoParecido => AppStrings.categoriaOrigenInsumo,
        OrigenSugerencia.reglas => AppStrings.categoriaOrigenReglas,
        OrigenSugerencia.ia => AppStrings.categoriaOrigenIa,
      };
}
