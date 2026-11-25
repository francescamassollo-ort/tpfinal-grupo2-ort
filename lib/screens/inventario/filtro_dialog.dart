import 'package:flutter/material.dart';

import '../../core/breakpoints.dart';
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
  late EstadoStock? _estado = widget.filtroActual.estado;

  @override
  Widget build(BuildContext context) {
    // Opciones sin repetir, sacadas de los insumos cargados.
    // whereType<String>() descarta los null (insumos sin categoría).
    final categorias =
        widget.insumos.map((i) => i.categoria).whereType<String>().toSet().toList()
          ..sort();
    final ubicaciones =
        widget.insumos.map((i) => i.ubicacion).toSet().toList()..sort();

    // Si lo que estaba elegido ya no existe (por ej. se movió el único
    // insumo de esa ubicación), volvemos a "Todas". El desplegable falla si
    // su valor no está entre las opciones.
    if (!categorias.contains(_categoria)) _categoria = null;
    if (!ubicaciones.contains(_ubicacion)) _ubicacion = null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Breakpoints.maxDialogWidth),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min, // el diálogo ocupa solo lo necesario
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<InventarioSort>(
                isExpanded: true,
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
                isExpanded: true,
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
                isExpanded: true,
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
                // Las ubicaciones largas ("Laboratorio 403 - Armario N°1")
                // se cortan con puntos suspensivos en vez de desbordar.
                isExpanded: true,
                initialValue: _ubicacion,
                decoration: const InputDecoration(labelText: 'Ubicación'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todas')),
                  ...ubicaciones.map(
                    (u) => DropdownMenuItem(
                      value: u,
                      child: Text(u, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _ubicacion = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<EstadoStock?>(
                isExpanded: true,
                initialValue: _estado,
                decoration: const InputDecoration(labelText: 'Estado del stock'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  for (final estado in EstadoStock.values)
                    DropdownMenuItem(value: estado, child: Text(estado.etiqueta)),
                ],
                onChanged: (value) => setState(() => _estado = value),
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
                    estado: _estado,
                  ),
                ),
                child: const Text('Filtrar'),
              ),
              // Deja todo como al principio; después se toca "Filtrar" para
              // aplicarlo (igual que cualquier otro cambio del panel).
              TextButton(
                onPressed: () => setState(() {
                  _sort = InventarioSort.nombre;
                  _categoria = null;
                  _tipo = null;
                  _ubicacion = null;
                  _estado = null;
                }),
                child: const Text('Borrar filtros'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
