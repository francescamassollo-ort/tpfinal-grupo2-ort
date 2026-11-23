import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/barcode_service.dart';

// El servicio que averigua de qué insumo es un código de barras. Se pide por
// acá, y no con BarcodeService() directo, para poder reemplazarlo por uno falso
// en las pruebas de las pantallas.
final barcodeServiceProvider = Provider<BarcodeService>((ref) => BarcodeService());
