import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../models/insumo.dart';
import '../../providers/insumo_providers.dart';
import '../../providers/role_provider.dart';
import '../../models/usuario.dart';


// Detalle de un insumo. Recibe solo el id (viene en la ruta /insumo/:id)
// y busca el insumo actualizado con insumoPorIdProvider: si alguien registra
// un consumo, el stock de esta pantalla se actualiza solo.
class InsumoDetalleScreen extends ConsumerWidget {
  const InsumoDetalleScreen({required this.insumoId, super.key});

  final String insumoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insumoAsync = ref.watch(insumoPorIdProvider(insumoId));
    // El Docente solo puede mirar: no edita, no da de baja ni registra salidas.
    final puedeEditar = ref.watch(roleProvider) != UserRole.docente;

    return SafeArea(
      child: insumoAsync.when(
        data: (insumo) {
          if (insumo == null) {
            return const Center(child: Text('El insumo no existe'));
          }
          return _DetalleContenido(insumo: insumo, puedeEditar: puedeEditar);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

// El contenido ya con el insumo cargado. Es un StatelessWidget aparte para
// que el build de arriba quede corto (solo decide cargando/error/datos).
class _DetalleContenido extends StatelessWidget {
  const _DetalleContenido({required this.insumo, required this.puedeEditar});

  final Insumo insumo;
  final bool puedeEditar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado: volver, nombre y (si el rol lo permite) editar/baja.
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Volver',
                // pop: saca el Detalle de la pila y vuelve a Inventario.
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Text(
                  insumo.nombre,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (puedeEditar) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar',
                  onPressed: () => _proximamente(context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Dar de baja',
                  onPressed: () => _proximamente(context),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Expanded + scroll: la ficha puede ser larga, y los botones de
          // abajo tienen que quedar siempre visibles.
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _StockCard(insumo: insumo),
                  const SizedBox(height: 12),
                  _FichaCard(insumo: insumo),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/historial'),
                  child: const Text('Historial'),
                ),
              ),
              if (puedeEditar) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/consumo'),
                    child: const Text('Registrar consumo'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Editar y Baja todavía no están hechos: avisamos con un mensaje abajo.
  void _proximamente(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Próximamente')));
  }
}

// Tarjeta "STOCK ACTUAL": cantidad grande y la etiqueta de estado.
// Usa la misma regla de colores que la tarjeta de Inventario (rojo gana).
class _StockCard extends StatelessWidget {
  const _StockCard({required this.insumo});

  final Insumo insumo;

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.stockOk;
    String etiqueta = 'Stock OK';
    if (insumo.stockBajo) {
      color = AppColors.stockDanger;
      etiqueta = 'Stock bajo';
    } else if (insumo.porVencer) {
      color = AppColors.stockWarning;
      etiqueta = 'Por vencer';
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STOCK ACTUAL',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${insumo.stock} unidades',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('Mínimo: ${insumo.umbralMinimo}'),
                ],
              ),
            ),
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: color),
                const SizedBox(width: 6),
                Text(
                  etiqueta,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Tarjeta con la ficha completa. Los datos cambian según el tipo:
// un producto comprado muestra marca, fórmula, etc.; una solución muestra
// concentración, quién la preparó, etc.
class _FichaCard extends StatelessWidget {
  const _FichaCard({required this.insumo});

  final Insumo insumo;

  @override
  Widget build(BuildContext context) {
    final esSolucion = insumo.tipo == InsumoTipo.solucion;

    // Lista de pares (título, valor). Si un valor es null se muestra "—".
    final List<(String, String?)> filas = esSolucion
        ? [
            ('Tipo de material', 'Solución preparada'),
            ('Concentración', insumo.concentracion),
            ('Fecha de elaboración', _fecha(insumo.fechaElaboracion)),
            ('Materia', insumo.materia),
            ('Preparado por', insumo.preparadoPor),
            ('Ubicación', insumo.ubicacion),
            ('Vencimiento', _fecha(insumo.fechaVencimiento)),
          ]
        : [
            ('Marca', insumo.marca),
            ('Tipo de material', 'Producto comprado'),
            ('Cant. por envase', _cantidadPorEnvase()),
            ('Ubicación', insumo.ubicacion),
            ('Fórmula', insumo.formula),
            ('Peso molecular', insumo.pesoMolecular?.toString()),
            ('Vencimiento', _fecha(insumo.fechaVencimiento)),
          ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          // map: convierte cada par (título, valor) en una fila de la tarjeta.
          children: filas
              .map((fila) => _FilaDato(titulo: fila.$1, valor: fila.$2))
              .toList(),
        ),
      ),
    );
  }

  // "500 ml" si hay unidad, "500" si no, null si no se cargó.
  String? _cantidadPorEnvase() {
    final cantidad = insumo.cantidadPorEnvase;
    if (cantidad == null) return null;
    return insumo.unidad == null ? '$cantidad' : '$cantidad ${insumo.unidad}';
  }

  // Fecha en formato dd/mm/aaaa (sin paquetes extra).
  String? _fecha(DateTime? fecha) {
    if (fecha == null) return null;
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }
}

// Una fila de la ficha: título a la izquierda, valor a la derecha.
class _FilaDato extends StatelessWidget {
  const _FilaDato({required this.titulo, required this.valor});

  final String titulo;
  final String? valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(titulo)),
          Text(
            valor ?? '—',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
