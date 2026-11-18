import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/insumo_providers.dart';
import '../../services/stock_service.dart';

class ConsumoScreen extends ConsumerStatefulWidget {
  const ConsumoScreen({super.key});

  @override
  ConsumerState<ConsumoScreen> createState() => _ConsumoScreenState();
}

class _ConsumoScreenState extends ConsumerState<ConsumoScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _insumoId;

  final _cantidadController = TextEditingController();

  String _motivo = 'TP';

  final _otroController = TextEditingController();
  @override
Widget build(BuildContext context) {
  final insumosAsync = ref.watch(insumosProvider);

  return SafeArea(
    child: insumosAsync.when(
      data: (insumos) {
        final insumoSeleccionado = _insumoId == null
    ? null
    : insumos.firstWhere((i) => i.id == _insumoId);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text(
                  'Registrar consumo',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _insumoId,
                  decoration: const InputDecoration(
                    labelText: 'Insumo',
                  ),
                  items: insumos.map((insumo) {
                    return DropdownMenuItem(
                      value: insumo.id,
                      child: Text(insumo.nombre),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _insumoId = value;
                    });
                  },
                ),
                if (insumoSeleccionado != null) ...[
                  const SizedBox(height: 8),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Stock actual: ${insumoSeleccionado.stock} ${insumoSeleccionado.unidad ?? 'unidades'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                TextFormField(
                  controller: _cantidadController,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese una cantidad';
                    }
                    if (int.tryParse(value) == null) {
                     return 'Ingrese un número válido';
                    }
                    final cantidad = int.tryParse(value);

                    if (cantidad == null || cantidad <= 0) {
                      return 'La cantidad debe ser mayor a 0';
                    }
                    if (insumoSeleccionado != null &&
                      cantidad > insumoSeleccionado.stock) {
                    return 'No hay stock suficiente';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: _motivo,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'TP',
                      child: Text('TP'),
                    ),
                    DropdownMenuItem(
                      value: 'Clase',
                      child: Text('Clase'),
                    ),
                    DropdownMenuItem(
                      value: 'Investigación',
                      child: Text('Investigación'),
                    ),
                    DropdownMenuItem(
                      value: 'Otro',
                      child: Text('Otro'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _motivo = value!;
                    });
                  },
                ),
                if (_motivo == 'Otro') ...[
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _otroController,
                    decoration: const InputDecoration(
                      labelText: 'Detalle del motivo',
                    ),
                    validator: (value) {
                      if (_motivo == 'Otro' &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Ingrese un detalle';
                      }
                      return null;
                    },
                  ),
                ],
              

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  if (_insumoId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Seleccione un insumo'),
                      ),
                    );
                    return;
                  }

                  try {
                    await StockService().registrarSalida(
                      _insumoId!,
                      int.parse(_cantidadController.text),
                      _motivo == 'Otro' 
                      ? _otroController.text 
                      : _motivo,
                    );

                  if (!mounted) return;
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Consumo registrado correctamente'),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al registrar consumo: $e'),
                    ),
                  );
                  }  
                },
                child: const Text('Registrar consumo'),
              ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    ),
  );
}

}