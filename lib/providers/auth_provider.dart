import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_logic/auth_service.dart';

// El servicio que habla con Firebase Authentication. Las pantallas lo piden por
// acá, y no con AuthService() directo, para poder reemplazarlo por uno falso en
// las pruebas (que no tienen Firebase).
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
