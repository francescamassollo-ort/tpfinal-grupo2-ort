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

  final _marcaController = TextEditingController();
  final _proveedorController = TextEditingController();
  final _pesoMolecularController = TextEditingController();

  final _concentracionController = TextEditingController();
  final _preparadoPorController = TextEditingController();

  DateTime? _fechaElaboracion;
  DateTime? _fechaVencimiento;

  bool _guardando = false;

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
                value: _tipo,
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
            ],
          ),
        ),
      ),
    );
  }
}