import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../models/alerta.dart';
import '../../models/filtro_alertas.dart';
import '../../core/breakpoints.dart';

/// Panel de filtros que se abre encima de Alertas. Mismo estilo que el del
/// Historial: un StatefulWidget común, sin Riverpod.
///
/// Lo elegido se guarda acá con setState y recién al tocar "Filtrar" (o
/// "Limpiar") el diálogo se cierra y devuelve el filtro a quien lo abrió. Si se
/// cierra tocando afuera devuelve null y no cambia nada.
class AlertasFiltroDialog extends StatefulWidget {
  const AlertasFiltroDialog({required this.filtroActual, super.key});

  /// Lo que ya estaba elegido, para que el panel abra con esos valores.
  final FiltroAlertas filtroActual;

  /// Abre el panel y espera lo que se eligió. Devuelve null si se cerró sin
  /// elegir.
  static Future<FiltroAlertas?> mostrar(
    BuildContext context,
    FiltroAlertas filtroActual,
  ) {
    return showDialog<FiltroAlertas>(
      context: context,
      builder: (_) => AlertasFiltroDialog(filtroActual: filtroActual),
    );
  }

  /// Cómo se llama cada tipo en el desplegable. Son los mismos textos que se
  /// ven en las alertas, sin la fecha ni el trabajo práctico que traen algunas.
  static String nombreDelTipo(TipoAlerta tipo) => switch (tipo) {
        TipoAlerta.sinStock => AppStrings.alertaSinStock,
        TipoAlerta.stockBajo => AppStrings.alertaStockBajo,
        TipoAlerta.vencido => AppStrings.alertaVencido,
        TipoAlerta.vencimientoCercano => AppStrings.alertaVencimientoCercano,
        TipoAlerta.agotamientoProximo => AppStrings.alertaAgotamientoProximo,
        TipoAlerta.tpSinCobertura => AppStrings.alertaTpSinCobertura,
      };

  @override
  State<AlertasFiltroDialog> createState() => _AlertasFiltroDialogState();
}

class _AlertasFiltroDialogState extends State<AlertasFiltroDialog> {
  late TipoAlerta? _tipo = widget.filtroActual.tipo;
  late EstadoVistaAlerta _estado = widget.filtroActual.estado;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Breakpoints.maxDialogWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<TipoAlerta?>(
                initialValue: _tipo,
                // Algunos nombres de tipo son largos: que no desborden.
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: AppStrings.alertasFiltroTipo,
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text(AppStrings.alertasFiltroTodos),
                  ),
                  for (final tipo in TipoAlerta.values)
                    DropdownMenuItem(
                      value: tipo,
                      child: Text(
                        AlertasFiltroDialog.nombreDelTipo(tipo),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _tipo = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<EstadoVistaAlerta>(
                initialValue: _estado,
                decoration: const InputDecoration(
                  labelText: AppStrings.alertasFiltroEstado,
                ),
                items: const [
                  DropdownMenuItem(
                    value: EstadoVistaAlerta.todas,
                    child: Text(AppStrings.alertasFiltroTodas),
                  ),
                  DropdownMenuItem(
                    value: EstadoVistaAlerta.sinVer,
                    child: Text(AppStrings.alertasFiltroSinVer),
                  ),
                  DropdownMenuItem(
                    value: EstadoVistaAlerta.vistas,
                    child: Text(AppStrings.alertasFiltroVistas),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _estado = value);
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      // Cierra devolviendo un filtro vacío: se ve todo.
                      onPressed: () =>
                          Navigator.of(context).pop(const FiltroAlertas()),
                      child: const Text(AppStrings.limpiar),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(
                        FiltroAlertas(tipo: _tipo, estado: _estado),
                      ),
                      child: const Text(AppStrings.filtrar),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      
    );
  }
}
