import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/insumo.dart';
import '../../services/insumo_service.dart';

class InsumoAltaScreen extends StatefulWidget {
  const InsumoAltaScreen({super.key});

  @override
  State<InsumoAltaScreen> createState() => _InsumoAltaScreenState();
}

class _InsumoAltaScreenState extends State<InsumoAltaScreen> {
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
  final _pesoMolecularController = TextEditingController();

  final _concentracionController = TextEditingController();
  final _preparadoPorController = TextEditingController();

  DateTime? _fechaElaboracion;
  DateTime? _fechaVencimiento;

  final bool _guardando = false;

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

    await InsumoService().agregarInsumo(insumo);

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