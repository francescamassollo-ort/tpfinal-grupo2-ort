import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import 'app_action_button.dart';

/// Fila inferior con los botones Compartir y Descargar, que repiten
/// Historial y Compras. Los callbacks son opcionales: mientras no estén
/// implementados, los botones se muestran pero no hacen nada.
class ShareDownloadActions extends StatelessWidget {
  const ShareDownloadActions({this.onShare, this.onDownload, super.key});

  final VoidCallback? onShare;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      // Abajo, como mínimo 46 (Figma) o el área segura del dispositivo.
      padding: EdgeInsets.fromLTRB(32, 12, 32, math.max(46, bottomInset + 12)),
      child: Row(
        children: [
          Expanded(
            child: AppActionButton(
              label: AppStrings.compartir,
              variant: AppActionButtonVariant.secondary,
              onPressed: onShare,
            ),
          ),
          const SizedBox(width: 26),
          Expanded(
            child: AppActionButton(
              label: AppStrings.descargar,
              onPressed: onDownload,
            ),
          ),
        ],
      ),
    );
  }
}
