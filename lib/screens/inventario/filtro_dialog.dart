import 'package:flutter/material.dart';

import '../../models/insumo.dart';
import '../../providers/inventario_filter_provider.dart';

// Panel de filtros que se abre encima del Inventario.
// Es un StatefulWidget común (sin Riverpod): mientras el usuario elige
// opciones, se guardan acá con setState. Recién al tocar "Filtrar" se
// cierra el diálogo y le devuelve a la pantalla lo elegido.
class FiltroDialog extends StatefulWidget {
  const FiltroDialog({
    required this.filtroActual,
    required this.insumos,
    super.key,
  });

  // Lo que ya estaba elegido, para que el panel abra con esos valores.
  final InventarioFilter filtroActual;
  // Todos los insumos, para armar las opciones de Categoría y Ubicación.
  final List<Insumo> insumos;

  @override
  State<FiltroDialog> createState() => _FiltroDialogState();
}

class _FiltroDialogState extends State<FiltroDialog> {
  // late SI deja leer widget.filtroActual cuandose  crea el campo
  late InventarioSort _sort = widget.filtroActual.sort;
  late String? _categoria = widget.filtroActual.categoria;
  late InsumoTipo? _tipo = widget.filtroActual.tipo;
  late String? _ubicacion = widget.filtroActual.ubicacion;

  @override
  Widget build(BuildContext context) {
    // Opciones sin repetir, sacadas de los insumos cargados.
    // whereType<String>() descarta los null (insumos sin categoría).
    final categorias =
        widget.insumos.map((i) => i.categoria).whereType<String>().toSet().toList()
          ..sort();
    final ubicaciones =
        widget.insumos.map((i) => i.ubicacion).toSet().toList()..sort();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min, // el diálogo ocupa solo lo necesario
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<InventarioSort>(
              initialValue: _sort,
              decoration: const InputDecoration(labelText: 'Ordenar por'),
              items: const [
                DropdownMenuItem(
                  value: InventarioSort.nombre,
                  child: Text('Nombre (A-Z)'),
                ),
                DropdownMenuItem(
                  value: InventarioSort.stockMenor,
                  child: Text('Stock (menor a mayor)'),
                ),
                DropdownMenuItem(
                  value: InventarioSort.stockMayor,
                  child: Text('Stock (mayor a menor)'),
                ),
              ],
              // "!" porque este desplegable no tiene opción vacía.
              onChanged: (value) => setState(() => _sort = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _categoria,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: [
                // value null = "Todas" (no filtra por categoría).
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ...categorias.map(
                  (c) => DropdownMenuItem(value: c, child: Text(c)),
                ),
              ],
              onChanged: (value) => setState(() => _categoria = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<InsumoTipo?>(
              initialValue: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo de material'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos')),
                DropdownMenuItem(
                  value: InsumoTipo.comprado,
                  child: Text('Producto comprado'),
                ),
                DropdownMenuItem(
                  value: InsumoTipo.solucion,
                  child: Text('Solución preparada'),
                ),
              ],
              onChanged: (value) => setState(() => _tipo = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _ubicacion,
              decoration: const InputDecoration(labelText: 'Ubicación'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ...ubicaciones.map(
                  (u) => DropdownMenuItem(value: u, child: Text(u)),
                ),
              ],
              onChanged: (value) => setState(() => _ubicacion = value),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              // Cierra el diálogo y "devuelve" el filtro elegido a quien
              // lo abrió (la pantalla de Inventario).
              onPressed: () => Navigator.of(context).pop(
                InventarioFilter(
                  sort: _sort,
                  categoria: _categoria,
                  tipo: _tipo,
                  ubicacion: _ubicacion,
                ),
              ),
              child: const Text('Filtrar'),
            ),
          ],
        ),
      ),
    );
  }
}
