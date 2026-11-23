import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_strings.dart';
import '../../models/datos_escaneados.dart';
import '../../models/insumo.dart';
import '../../providers/insumo_providers.dart';
import '../../providers/sinonimos_provider.dart';
import '../../services/duplicate_detection_service.dart';
import '../../services/stock_service.dart';
import '../../services/synonym_detection_service.dart';
import 'duplicados_dialog.dart';
import 'sugerencias_nombre.dart';

class InsumoAltaScreen extends ConsumerStatefulWidget {
  const InsumoAltaScreen({super.key});

  @override
  ConsumerState<InsumoAltaScreen> createState() => _InsumoAltaScreenState();
}

class _InsumoAltaScreenState extends ConsumerState<InsumoAltaScreen> {
  final _formKey = GlobalKey<FormState>();

  InsumoTipo _tipo = InsumoTipo.comprado;

  final _nombreController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _stockController = TextEditingController();
  final _unidadController = TextEditingController();
  final _codigoBarrasController = TextEditingController();
  final _umbralMinimoController = TextEditingController();

  final _marcaController = TextEditingController();
  final _proveedorController = TextEditingController();
  final _formulaController = TextEditingController();
  final _pesoMolecularController = TextEditingController();

  final _concentracionController = TextEditingController();
  final _preparadoPorController = TextEditingController();

  DateTime? _fechaElaboracion;
  DateTime? _fechaVencimiento;

  final bool _guardando = false;

  @override
  void initState() {
    super.initState();
    // Mantiene escuchada la lista de insumos mientras la pantalla está
    // abierta, para tenerla cargada cuando se toca "Buscar duplicados". No
    // redibuja nada: solo evita que el stream se pause.
    ref.listenManual(insumosProvider, (previous, next) {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Alta de insumo',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),
              DropdownButtonFormField<InsumoTipo>(
                initialValue: _tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                ),
                items: const [
                  DropdownMenuItem(
                    value: InsumoTipo.comprado,
                    child: Text('Insumo comprado'),
                  ),
                  DropdownMenuItem(
                    value: InsumoTipo.solucion,
                    child: Text('Solución preparada'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _tipo = value;
                  });
                },
              ),

              const SizedBox(height: 12),
              TextFormField(
  controller: _nombreController,
  decoration: const InputDecoration(
    labelText: 'Nombre',
  ),
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese un nombre';
    }
    return null;
  },
),

// Mientras se escribe, avisa si ya existe un insumo con un nombre parecido.
// Tocar uno abre su detalle; el Alta queda abierta atrás.
SugerenciasNombre(
  controller: _nombreController,
  onElegir: (insumo) => context.push('/insumo/${insumo.id}'),
),

const SizedBox(height: 12),

TextFormField(
  controller: _categoriaController,
  decoration: const InputDecoration(
    labelText: 'Categoría',
  ),
),

const SizedBox(height: 12),

TextFormField(
  controller: _ubicacionController,
  decoration: const InputDecoration(
    labelText: 'Ubicación',
  ),
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese una ubicación';
    }
    return null;
  },
),

const SizedBox(height: 12),

TextFormField(
  controller: _stockController,
  decoration: const InputDecoration(
    labelText: 'Cantidad inicial',
  ),
  keyboardType: TextInputType.number,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese una cantidad';
    }
    return null;
  },
),

const SizedBox(height: 12),

TextFormField(
  controller: _umbralMinimoController,
  decoration: const InputDecoration(
    labelText: 'Stock mínimo',
  ),
  keyboardType: TextInputType.number,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese un stock mínimo';
    }
    return null;
  },
),

const SizedBox(height: 12),

TextFormField(
  controller: _unidadController,
  decoration: const InputDecoration(
    labelText: 'Unidad',
    hintText: 'ml, g, kg, unidades...',
  ),
),

const SizedBox(height: 12),

TextFormField(
  controller: _codigoBarrasController,
  decoration: const InputDecoration(
    labelText: 'Código de barras',
  ),
),

const SizedBox(height: 8),

// Abre la cámara y completa el formulario con lo que se lea del código.
OutlinedButton.icon(
  onPressed: _escanear,
  icon: const Icon(Icons.qr_code_scanner),
  label: const Text(AppStrings.altaEscanear),
),

const SizedBox(height: 16),

if (_tipo == InsumoTipo.comprado) ...[
  TextFormField(
    controller: _marcaController,
    decoration: const InputDecoration(
      labelText: 'Marca',
    ),
  ),

  const SizedBox(height: 12),

  TextFormField(
    controller: _proveedorController,
    decoration: const InputDecoration(
      labelText: 'Proveedor',
    ),
  ),

  const SizedBox(height: 12),

  TextFormField(
    controller: _formulaController,
    decoration: const InputDecoration(
      labelText: 'Fórmula',
    ),
  ),

  const SizedBox(height: 12),

  TextFormField(
    controller: _pesoMolecularController,
    decoration: const InputDecoration(
      labelText: 'Peso molecular',
    ),
    keyboardType: TextInputType.number,
  ),
]
else ...[
  TextFormField(
    controller: _concentracionController,
    decoration: const InputDecoration(
      labelText: 'Concentración',
    ),
  ),

  const SizedBox(height: 12),

  TextFormField(
    controller: _preparadoPorController,
    decoration: const InputDecoration(
      labelText: 'Preparado por',
    ),
  ),
],

const SizedBox(height: 12),

ElevatedButton(
  onPressed: () async {
    final fecha = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (fecha != null) {
      setState(() {
        _fechaElaboracion = fecha;
      });
    }
  },
  child: Text(
    _fechaElaboracion == null
        ? 'Seleccionar fecha de elaboración'
        : 'Elaboración: ${_fechaElaboracion!.day}/${_fechaElaboracion!.month}/${_fechaElaboracion!.year}',
  ),
),

const SizedBox(height: 12),

ElevatedButton(
  onPressed: () async {
    final fecha = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (fecha != null) {
      setState(() {
        _fechaVencimiento = fecha;
      });
    }
  },
  child: Text(
    _fechaVencimiento == null
        ? 'Seleccionar fecha de vencimiento'
        : 'Vence: ${_fechaVencimiento!.day}/${_fechaVencimiento!.month}/${_fechaVencimiento!.year}',
  ),
),

const SizedBox(height: 24),

// Antes de guardar: revisa si ya existe algo parecido con lo que se
// escribió (nombre, tipo, marca y código de barras).
OutlinedButton.icon(
  onPressed: _buscarDuplicados,
  icon: const Icon(Icons.search),
  label: const Text(AppStrings.duplicadosBuscar),
),

const SizedBox(height: 12),

ElevatedButton(
  onPressed: _guardando ? null : _guardar,
  child: const Text('Guardar'),
),
            ],
          ),
        ),
      ),
    );
  }

  // Abre el escáner y completa el formulario con lo que devuelva. Solo llena los
  // campos que están vacíos: un escaneo nunca pisa lo que la persona ya
  // escribió. La marca, la fórmula y el peso molecular son de los insumos
  // comprados, así que en una solución no se completan.
  Future<void> _escanear() async {
    final datos = await context.push<DatosEscaneados>('/scanner');
    if (datos == null || !mounted) return;

    void completar(TextEditingController campo, String? valor) {
      if (valor != null && campo.text.trim().isEmpty) campo.text = valor;
    }

    setState(() {
      // El código sí se reemplaza: es justo lo que se acaba de leer.
      _codigoBarrasController.text = datos.codigo;
      completar(_nombreController, datos.nombre);
      if (_tipo == InsumoTipo.comprado) {
        completar(_marcaController, datos.marca);
        completar(_formulaController, datos.formula);
        completar(_pesoMolecularController, datos.pesoMolecular?.toString());
      }
    });

    // Si el escáner no encontró nada y solo trajo el código, no hay datos que
    // avisar.
    if (datos.nombre != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.altaDatosCompletados)),
      );
    }
  }

  // Busca insumos parecidos al que se está cargando y muestra el resultado en
  // una ventana. Si la persona elige cargarle un consumo a uno de ellos, se
  // deja el alta (era un duplicado) y se abre Consumo con ese insumo elegido.
  Future<void> _buscarDuplicados() async {
    final nombre = _nombreController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (nombre.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.duplicadosEscribirNombre)),
      );
      return;
    }

    // Sin la lista de insumos no hay con qué comparar: se avisa en vez de
    // decir "no hay duplicados", que sería engañoso.
    final insumos = ref.read(insumosProvider);
    final existentes = insumos.value;
    if (existentes == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            insumos.hasError
                ? AppStrings.duplicadosError
                : AppStrings.duplicadosCargando,
          ),
        ),
      );
      return;
    }

    final codigo = _codigoBarrasController.text.trim();
    final marca = _tipo == InsumoTipo.comprado
        ? _marcaController.text.trim()
        : null;

    final similares = DuplicateDetectionService.buscarSimilares(
      nombre,
      existentes,
      marca: marca,
      tipo: _tipo,
      codigoBarras: codigo,
    );
    final parecidos = [
      for (final insumo in similares)
        (
          insumo: insumo,
          mismoCodigoDeBarras: codigo.isNotEmpty &&
              (insumo.codigoBarras ?? '').trim().toLowerCase() ==
                  codigo.toLowerCase(),
        ),
    ];

    final elegido = await DuplicadosDialog.mostrar(
      context,
      parecidos,
      sugerenciasIa: _sugerenciasDeIa(
        nombre,
        existentes,
        yaMostrados: similares,
        marca: marca,
      ),
    );
    if (elegido == null || !mounted) return;

    context.pushReplacement('/consumo?insumo=${elegido.id}');
  }

  // Le pregunta a la IA si el nombre que se está cargando es un sinónimo de
  // alguno de los que ya existen ("etanol" y "alcohol etílico"). Devuelve null
  // si no hay IA configurada. Solo se le mandan nombres de insumos. Los que la
  // comparación de texto ya mostró se saltean, para no repetirlos.
  Future<List<Insumo>>? _sugerenciasDeIa(
    String nombre,
    List<Insumo> existentes, {
    required List<Insumo> yaMostrados,
    String? marca,
  }) {
    final modelo = ref.read(modeloDeLenguajeProvider);
    if (modelo == null) return null;

    // El insumo todavía no existe: se lo suma a la lista con un id propio para
    // que la IA lo compare con los demás.
    const idNuevo = '__nuevo__';
    final nuevo = Insumo(
      id: idNuevo,
      nombre: nombre,
      tipo: _tipo,
      stock: 0,
      ubicacion: '',
      umbralMinimo: 0,
      marca: marca == null || marca.isEmpty ? null : marca,
    );
    final porId = {for (final i in existentes) i.id: i};
    final conocidos = {for (final i in yaMostrados) i.id};

    final sugerencias = SynonymDetectionService(modelo)
        .buscar([...existentes, nuevo]).then((hallazgos) {
      final ids = <String>{};
      for (final h in hallazgos) {
        if (!h.insumoIds.contains(idNuevo)) continue;
        final otro = h.insumoIds.firstWhere((id) => id != idNuevo);
        if (!conocidos.contains(otro)) ids.add(otro);
      }
      return [
        for (final id in ids)
          if (porId[id] != null) porId[id]!,
      ];
    });
    // Si la IA falla antes de que la ventana empiece a esperar el resultado,
    // el error no tiene que perderse como "error sin manejar": la ventana lo
    // recibe igual cuando se suscribe y lo muestra como aviso.
    sugerencias.ignore();
    return sugerencias;
  }

  Future<void> _guardar() async {
  if (!_formKey.currentState!.validate()) return;

  try {
    final insumo = Insumo(
      id: '',
      nombre: _nombreController.text,
      tipo: _tipo,
      stock: int.parse(_stockController.text),
      ubicacion: _ubicacionController.text,
      umbralMinimo: num.parse(
  _umbralMinimoController.text,
),

      categoria: _categoriaController.text.isEmpty
          ? null
          : _categoriaController.text,

      unidad: _unidadController.text.isEmpty
          ? null
          : _unidadController.text,

      codigoBarras: _codigoBarrasController.text.isEmpty
          ? null
          : _codigoBarrasController.text,

      marca: _tipo == InsumoTipo.comprado
          ? _marcaController.text
          : null,

      proveedor: _tipo == InsumoTipo.comprado
          ? _proveedorController.text
          : null,

      formula: _tipo == InsumoTipo.comprado &&
              _formulaController.text.trim().isNotEmpty
          ? _formulaController.text.trim()
          : null,

      pesoMolecular: _tipo == InsumoTipo.comprado &&
              _pesoMolecularController.text.isNotEmpty
          ? double.parse(_pesoMolecularController.text)
          : null,

      concentracion: _tipo == InsumoTipo.solucion
          ? _concentracionController.text
          : null,

      preparadoPor: _tipo == InsumoTipo.solucion
          ? _preparadoPorController.text
          : null,

      fechaElaboracion: _fechaElaboracion,
      fechaVencimiento: _fechaVencimiento,
    );

    // Guarda el insumo y, si trae stock, su entrada en el historial.
    await StockService().registrarAlta(insumo);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Insumo guardado correctamente'),
      ),
    );

    context.pop();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
      ),
    );
  }
}
}