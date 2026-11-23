import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/app_strings.dart';
import '../core/app_text_styles.dart';

/// Cómo se arma la cámara del escáner: recibe un callback que se llama con el
/// código leído. La pantalla recibe esta función para poder reemplazar la
/// cámara real por una falsa en las pruebas, que no tienen cámara.
typedef ConstructorDeCamara = Widget Function(
  BuildContext context,
  ValueChanged<String> onCodigo,
);

/// La cámara que lee códigos de barras (la de `mobile_scanner`). Pide permiso
/// de cámara solo; si no se puede abrir, lo dice en vez de quedar en negro.
///
/// Avisa de cada código leído una sola vez mientras siga a la vista, y se
/// frena sola a la espera de que quien la usa decida qué hacer: para volver a
/// leer hay que dejarla de usar y crearla de nuevo.
class CamaraEscaner extends StatefulWidget {
  const CamaraEscaner({required this.onCodigo, super.key});

  final ValueChanged<String> onCodigo;

  /// Es el [ConstructorDeCamara] que usa la pantalla por defecto.
  static Widget construir(BuildContext context, ValueChanged<String> onCodigo) {
    return CamaraEscaner(onCodigo: onCodigo);
  }

  @override
  State<CamaraEscaner> createState() => _CamaraEscanerState();
}

class _CamaraEscanerState extends State<CamaraEscaner> {
  // Solo los códigos de barras de productos: sin QR ni otros formatos, que
  // distraen y dan falsos positivos.
  final _controlador = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
    ],
  );

  bool _yaLeyo = false;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: _controlador,
      onDetect: _alDetectar,
      errorBuilder: (context, error) => _ErrorDeCamara(error: error),
    );
  }

  void _alDetectar(BarcodeCapture captura) {
    if (_yaLeyo) return;
    final codigo = captura.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .where((valor) => valor.trim().isNotEmpty)
        .firstOrNull;
    if (codigo == null) return;

    _yaLeyo = true;
    widget.onCodigo(codigo);
  }
}

class _ErrorDeCamara extends StatelessWidget {
  const _ErrorDeCamara({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final sinPermiso = error.errorCode == MobileScannerErrorCode.permissionDenied;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Text(
          sinPermiso
              ? AppStrings.escanerSinPermiso
              : AppStrings.escanerCamaraError,
          textAlign: TextAlign.center,
          style: AppTextStyles.listItemSubtitle.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
