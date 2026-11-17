import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/archivo_service.dart';

/// El servicio que comparte y guarda archivos. Se pide desde un provider para
/// poder reemplazarlo en los tests por uno que no abra el menú del sistema.
final archivoServiceProvider = Provider((ref) => const ArchivoService());
