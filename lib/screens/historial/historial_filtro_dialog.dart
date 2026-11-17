import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../models/filtro_historial.dart';
import '../../models/insumo.dart';
import '../../models/movimiento_stock.dart';

/// Panel de filtros que se abre encima del Historial. Mismo estilo que el
/// panel de Inventario (FiltroDialog): un StatefulWidget común, sin Riverpod.
/// Lo elegido se guarda acá con setState y recién al tocar "Filtrar" (o
/// "Limpiar") el diálogo se cierra y devuelve el filtro a quien lo abrió. Si se
/// cierra tocando afuera devuelve null y no cambia nada.
class HistorialFiltroDialog extends StatefulWidget {
  const HistorialFiltroDialog({
    required this.filtroActual,
    required this.insumos,
    super.key,
  });

  /// Lo que ya estaba elegido, para que el panel abra con esos valores.
  final FiltroHistorial filtroActual;

  /// Todos los insumos, para armar las opciones del desplegable de Insumo.
  final List<Insumo> insumos;

  @override
  State<HistorialFiltroDialog> createState() => _HistorialFiltroDialogState();
}

class _HistorialFiltroDialogState extends State<HistorialFiltroDialog> {
  static final DateTime _primerDia = DateTime(2000);

  late TipoMovimiento? _tipo = widget.filtroActual.tipo;
  late String? _productoId = widget.filtroActual.productoId;
  late DateTime? _desde = widget.filtroActual.desde;
  late DateTime? _hasta = widget.filtroActual.hasta;

  @override
  Widget build(BuildContext context) {
    final insumos = [...widget.insumos]
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

    // Si el insumo elegido ya no existe, se vuelve a "Todos": el desplegable
    // falla si su valor no está entre las opciones.
    if (!insumos.any((i) => i.id == _productoId)) _productoId = null;

    // Dos insumos pueden llamarse igual (por ejemplo, el mismo producto en dos
    // armarios). A esos se les suma la ubicación para poder distinguirlos.
    final repetidos = _nombresRepetidos(insumos);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<TipoMovimiento?>(
              initialValue: _tipo,
              decoration: const InputDecoration(
                labelText: AppStrings.historialFiltroTipo,
              ),
              items: const [
                DropdownMenuItem(
                  value: null,
                  child: Text(AppStrings.historialFiltroTodos),
                ),
                DropdownMenuItem(
                  value: TipoMovimiento.entrada,
                  child: Text(AppStrings.historialFiltroEntrada),
                ),
                DropdownMenuItem(
                  value: TipoMovimiento.salida,
                  child: Text(AppStrings.historialFiltroSalida),
                ),
                DropdownMenuItem(
                  value: TipoMovimiento.ajuste,
                  child: Text(AppStrings.historialFiltroAjuste),
                ),
              ],
              onChanged: (value) => setState(() => _tipo = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _productoId,
              // Los nombres de insumo pueden ser largos: que no desborden.
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: AppStrings.historialFiltroInsumo,
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text(AppStrings.historialFiltroTodos),
                ),
                ...insumos.map(
                  (i) => DropdownMenuItem(
                    value: i.id,
                    child: Text(
                      _etiqueta(i, repetidos),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _productoId = value),
            ),
            const SizedBox(height: 12),
            _CampoFecha(
              etiqueta: AppStrings.historialFiltroDesde,
              fecha: _desde,
              onTap: _elegirDesde,
              onBorrar: () => setState(() => _desde = null),
            ),
            const SizedBox(height: 12),
            _CampoFecha(
              etiqueta: AppStrings.historialFiltroHasta,
              fecha: _hasta,
              onTap: _elegirHasta,
              onBorrar: () => setState(() => _hasta = null),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    // Cierra devolviendo un filtro vacío: se ve todo.
                    onPressed: () =>
                        Navigator.of(context).pop(const FiltroHistorial()),
                    child: const Text(AppStrings.limpiar),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(
                      FiltroHistorial(
                        productoId: _productoId,
                        // No hay campo de persona en el panel, pero si el
                        // filtro ya traía una se conserva.
                        usuarioId: widget.filtroActual.usuarioId,
                        desde: _desde,
                        hasta: _hasta,
                        tipo: _tipo,
                      ),
                    ),
                    child: const Text(AppStrings.filtrar),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // "Desde" no puede ser posterior a "Hasta" (ni a hoy, porque no hay
  // movimientos en el futuro), y "Hasta" no puede ser anterior a "Desde". Así
  // el rango nunca queda al revés.
  Future<void> _elegirDesde() async {
    final elegida = await _pedirFecha(
      actual: _desde,
      primero: _primerDia,
      ultimo: _hasta ?? _hoy(),
    );
    if (elegida != null) setState(() => _desde = elegida);
  }

  Future<void> _elegirHasta() async {
    final elegida = await _pedirFecha(
      actual: _hasta,
      primero: _desde ?? _primerDia,
      ultimo: _hoy(),
    );
    if (elegida != null) setState(() => _hasta = elegida);
  }

  Future<DateTime?> _pedirFecha({
    required DateTime? actual,
    required DateTime primero,
    required DateTime ultimo,
  }) {
    // initialDate tiene que estar dentro del rango permitido.
    var inicial = actual ?? _hoy();
    if (inicial.isBefore(primero)) inicial = primero;
    if (inicial.isAfter(ultimo)) inicial = ultimo;

    return showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: primero,
      lastDate: ultimo,
    );
  }

  static DateTime _hoy() {
    final ahora = DateTime.now();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  // Nombres que tienen más de un insumo, sin distinguir mayúsculas.
  static Set<String> _nombresRepetidos(List<Insumo> insumos) {
    final vistos = <String>{};
    final repetidos = <String>{};
    for (final insumo in insumos) {
      final nombre = insumo.nombre.toLowerCase();
      if (!vistos.add(nombre)) repetidos.add(nombre);
    }
    return repetidos;
  }

  // "Algodon - Armario 5" si el nombre se repite; si no, solo el nombre.
  static String _etiqueta(Insumo insumo, Set<String> repetidos) {
    final repetido = repetidos.contains(insumo.nombre.toLowerCase());
    return repetido ? '${insumo.nombre} - ${insumo.ubicacion}' : insumo.nombre;
  }
}

/// Campo de fecha que se toca para abrir el calendario y tiene una cruz para
/// borrar la fecha elegida.
class _CampoFecha extends StatelessWidget {
  const _CampoFecha({
    required this.etiqueta,
    required this.fecha,
    required this.onTap,
    required this.onBorrar,
  });

  final String etiqueta;
  final DateTime? fecha;
  final VoidCallback onTap;
  final VoidCallback onBorrar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,
          suffixIcon: fecha == null
              ? const Icon(Icons.calendar_today_outlined, size: 20)
              : IconButton(
                  onPressed: onBorrar,
                  icon: const Icon(Icons.clear, size: 20),
                ),
        ),
        child: Text(
          fecha == null
              ? AppStrings.historialFiltroCualquierFecha
              : _formatear(fecha!),
        ),
      ),
    );
  }

  static String _formatear(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/'
      '${f.month.toString().padLeft(2, '0')}/${f.year}';
}
