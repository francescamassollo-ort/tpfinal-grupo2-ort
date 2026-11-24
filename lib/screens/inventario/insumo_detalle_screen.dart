import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/permisos.dart';
import '../../widgets/app_screen_header.dart';
import '../../models/filtro_historial.dart';
import '../../models/insumo.dart';
import '../../providers/historial_provider.dart';
import 'sumar_stock_dialog.dart';
import '../../providers/insumo_providers.dart';
import '../../providers/role_provider.dart';
import '../../providers/stock_provider.dart';
import '../../services/stock_logica.dart';


// Detalle de un insumo. Recibe solo el id (viene en la ruta /insumo/:id)
// y busca el insumo actualizado con insumoPorIdProvider: si alguien registra
// un consumo, el stock de esta pantalla se actualiza solo.
class InsumoDetalleScreen extends ConsumerWidget {
  const InsumoDetalleScreen({required this.insumoId, super.key});

  final String insumoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insumoAsync = ref.watch(insumoPorIdProvider(insumoId));
    // Editar y dar de baja es del administrador; registrar consumo, también
    // del ayudante. El docente solo mira.
    final rol = ref.watch(roleProvider);
    final puedeEditar = Permisos.puedeEditarOBaja(rol);
    final puedeSumar = Permisos.puedeSumarStock(rol);
    final puedeConsumir = Permisos.puedeRegistrarConsumo(rol);

    return SafeArea(
      child: insumoAsync.when(
        data: (insumo) {
          if (insumo == null) {
            return const _SinInsumo(AppStrings.insumoNoExiste);
          }
          return _DetalleContenido(
            insumo: insumo,
            puedeEditar: puedeEditar,
            puedeConsumir: puedeConsumir,
            puedeSumar: puedeSumar,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const _SinInsumo(AppStrings.insumoErrorCarga),
      ),
    );
  }
}

// Cuando no hay insumo que mostrar (no existe o falló la carga): el mensaje y
// la flecha para volver, para no dejar a la persona sin salida.
class _SinInsumo extends StatelessWidget {
  const _SinInsumo(this.mensaje);

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppScreenHeader(title: '', onBack: () => _volver(context)),
        Expanded(child: Center(child: Text(mensaje))),
      ],
    );
  }
}

// Vuelve a donde se estaba; si no hay a dónde (se abrió la ruta directo),
// va a Inventario.
void _volver(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/inventario');
  }
}

// El contenido ya con el insumo cargado. Es un StatelessWidget aparte para
// que el build de arriba quede corto (solo decide cargando/error/datos).
class _DetalleContenido extends ConsumerWidget {
  const _DetalleContenido({
    required this.insumo,
    required this.puedeEditar,
    required this.puedeConsumir,
    required this.puedeSumar,
  });

  final Insumo insumo;
  final bool puedeEditar;
  final bool puedeConsumir;
  final bool puedeSumar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Mismo encabezado que el resto de las pantallas: volver, nombre y (si
        // el rol lo permite) editar y dar de baja.
        AppScreenHeader(
          title: insumo.nombre,
          onBack: () => _volver(context),
          acciones: [
            if (puedeEditar) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar',
                onPressed: () => context.push('/insumo/editar/${insumo.id}'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Dar de baja',
                onPressed: () => _darDeBaja(context, ref),
              ),
            ],
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  // Abre el Historial ya filtrado por este insumo (R13); al
                  // volver se limpia el filtro para no dejarlo puesto.
                  onPressed: () => _verHistorial(context, ref),
                  child: const Text('Historial'),
                ),
              ),
              if (puedeConsumir) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    // Abre el registro de consumo con este insumo ya elegido.
                    onPressed: () => context.push('/consumo?insumo=${insumo.id}'),
                    child: const Text('Registrar consumo'),
                  ),
                ),
              ],
            ],
          ),
          // Sumar stock: llegó una compra o una donación de un insumo que ya
          // existe. Deja una entrada de "Reposición" en el Historial.
          if (puedeSumar) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _sumarStock(context, ref),
                icon: const Icon(Icons.add),
                label: const Text(AppStrings.detalleSumarStock),
              ),
            ),
          ],
        ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sumarStock(BuildContext context, WidgetRef ref) async {
    // Se toma antes de los await: después la pantalla puede ya no estar.
    final avisos = ScaffoldMessenger.of(context);
    final cantidad = await SumarStockDialog.mostrar(context, insumo);
    if (cantidad == null || !context.mounted) return;

    try {
      await ref.read(stockServiceProvider).registrarEntrada(
            insumo.id,
            cantidad,
            AppStrings.escanerMotivoReposicion,
          );
      avisos.showSnackBar(
        SnackBar(content: Text(AppStrings.escanerStockSumado(cantidad, insumo.nombre))),
      );
    } on StockException catch (error) {
      avisos.showSnackBar(SnackBar(content: Text(error.mensaje)));
    } catch (_) {
      avisos.showSnackBar(const SnackBar(content: Text(AppStrings.escanerErrorSumar)));
    }
  }

  Future<void> _verHistorial(BuildContext context, WidgetRef ref) async {
    final filtro = ref.read(filtroHistorialProvider.notifier);
    filtro.cambiar(FiltroHistorial(productoId: insumo.id));
    await context.push('/historial');
    filtro.limpiar();
  }

  // Baja lógica con confirmación: el insumo deja de aparecer en la app, pero su
  // historial se conserva.
  Future<void> _darDeBaja(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.bajaInsumoTitulo),
        content: Text(AppStrings.bajaInsumoMensaje(insumo.nombre)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.bajaInsumoConfirmar),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;

    // Se toman antes del await: después la pantalla puede ya no estar.
    final avisos = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(insumoServiceProvider).darDeBaja(insumo.id);
    } catch (_) {
      avisos.showSnackBar(
        const SnackBar(content: Text(AppStrings.bajaInsumoError)),
      );
      return;
    }
    avisos.showSnackBar(
      SnackBar(content: Text(AppStrings.bajaInsumoHecha(insumo.nombre))),
    );
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/inventario');
    }
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
    if (insumo.stock <= 0) {
      color = AppColors.stockAgotado;
      etiqueta = 'Sin stock';
    } else if (insumo.stockBajo) {
      color = AppColors.stockDanger;
      etiqueta = 'Stock bajo';
    } else if (insumo.porVencer) {
      color = AppColors.stockWarning;
      etiqueta = 'Por vencer';
    }

    return Card(
      color: insumo.stock <= 0 ? const Color(0xFFF1F2F4) : null,
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
            ('Categoría', insumo.categoria),
            ('Concentración', insumo.concentracion),
            ('Fecha de elaboración', _fecha(insumo.fechaElaboracion)),
            ('Materia', insumo.materia),
            ('Preparado por', insumo.preparadoPor),
            ('Ubicación', insumo.ubicacion),
            ('Vencimiento', _fecha(insumo.fechaVencimiento)),
          ]
        : [
            ('Marca', insumo.marca),
            ('Proveedor', insumo.proveedor),
            ('Tipo de material', 'Producto comprado'),
            ('Categoría', insumo.categoria),
            ('Cant. por envase', _cantidadPorEnvase()),
            ('Ubicación', insumo.ubicacion),
            ('Fórmula', insumo.formula),
            ('Peso molecular', insumo.pesoMolecular?.toString()),
            ('Vencimiento', _fecha(insumo.fechaVencimiento)),
          ];

    // Los datos que no todos los insumos tienen: solo se muestran si están.
    final extras = <(String, String?)>[
      if (insumo.codigoInterno != null)
        (AppStrings.codigoInterno, insumo.codigoInterno),
      if (insumo.otrosNombres.isNotEmpty)
        (AppStrings.otrosNombres, insumo.otrosNombres.join(', ')),
      if (insumo.controlado) (AppStrings.controlado, 'Sí'),
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          // map: convierte cada par (título, valor) en una fila de la tarjeta.
          children: [...filas, ...extras]
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título y valor se reparten el ancho y hacen salto de línea si son
          // largos ("Sustancia controlada (Sedronar)", una ubicación con varios
          // niveles, letra grande).
          Expanded(flex: 2, child: Text(titulo)),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              valor ?? '—',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
