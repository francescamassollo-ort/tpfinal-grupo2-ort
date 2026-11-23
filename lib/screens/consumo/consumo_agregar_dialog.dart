import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../models/insumo.dart';
import '../../services/similitud_texto.dart';

/// Panel para elegir un insumo más para retirar. Tiene un buscador que filtra
/// por nombre sin mirar mayúsculas ni tildes. Mismo estilo que los otros
/// paneles (un Dialog con StatefulWidget común, sin Riverpod).
///
/// Al tocar un insumo se cierra y lo devuelve. Si se cierra tocando afuera o
/// con "Cancelar" devuelve null y no se agrega nada.
class ConsumoAgregarDialog extends StatefulWidget {
  const ConsumoAgregarDialog({required this.insumos, super.key});

  /// Los insumos que se pueden elegir: la pantalla manda solo los que tienen
  /// stock y todavía no están en la lista.
  final List<Insumo> insumos;

  /// Abre el panel y espera lo que se eligió.
  static Future<Insumo?> mostrar(BuildContext context, List<Insumo> insumos) {
    return showDialog<Insumo>(
      context: context,
      builder: (_) => ConsumoAgregarDialog(insumos: insumos),
    );
  }

  @override
  State<ConsumoAgregarDialog> createState() => _ConsumoAgregarDialogState();
}

class _ConsumoAgregarDialogState extends State<ConsumoAgregarDialog> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final buscado = SimilitudTexto.normalizar(_busqueda);
    final insumos = [
      for (final insumo in widget.insumos)
        if (buscado.isEmpty ||
            SimilitudTexto.normalizar(insumo.nombre).contains(buscado))
          insumo,
    ]..sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.consumoAgregarTitulo,
              style: AppTextStyles.listItemTitle,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: AppStrings.consumoBuscarInsumo,
              ),
              onChanged: (texto) => setState(() => _busqueda = texto),
            ),
            const SizedBox(height: 8),
            // Con muchos insumos la lista se desplaza en vez de agrandar la
            // ventana más que la pantalla.
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: insumos.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          AppStrings.consumoSinCoincidencias,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.listItemSubtitle,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: insumos.length,
                        itemBuilder: (context, index) {
                          final insumo = insumos[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              insumo.nombre,
                              style: AppTextStyles.listItemTitle,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${insumo.ubicacion} · '
                              '${AppStrings.consumoDisponible(insumo.stock, insumo.unidad ?? AppStrings.consumoUnidadPorDefecto)}',
                              style: AppTextStyles.listItemSubtitle,
                            ),
                            onTap: () => Navigator.of(context).pop(insumo),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.cancelar),
            ),
          ],
        ),
      ),
    );
  }
}
