import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/stock_service.dart';

// El servicio que cambia el stock y deja constancia en el historial. Se pide
// por acá, y no con StockService() directo, para poder reemplazarlo por uno
// falso en las pruebas de las pantallas.
final stockServiceProvider = Provider<StockService>((ref) => StockService());
