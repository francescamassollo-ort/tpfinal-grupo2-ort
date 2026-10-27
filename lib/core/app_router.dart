import 'package:go_router/go_router.dart';

import '../screens/alertas/alertas_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/compras/compras_screen.dart';
import '../screens/consumo/consumo_screen.dart';
import '../screens/historial/historial_screen.dart';
import '../screens/inventario/buscar_filtro_screen.dart';
import '../screens/inventario/insumo_alta_screen.dart';
import '../screens/inventario/insumo_detalle_screen.dart';
import '../screens/inventario/inventario_screen.dart';
import '../screens/inventario/scanner_screen.dart';
import '../screens/perfil/perfil_screen.dart';
import '../screens/tp/tp_detalle_screen.dart';
import '../screens/tp/tp_editar_screen.dart';
import '../screens/tp/tp_lista_screen.dart';
import '../screens/usuarios/usuarios_screen.dart';
import 'app_shell.dart';

// Login queda para el final (lo pidió el profe), por eso se arranca
// directo en /inventario en vez de /welcome o /login.
final GoRouter appRouter = GoRouter(
  initialLocation: '/inventario',
  routes: [
    // Pantallas sin barra ni drawer (todavía no hay sesión iniciada).
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),

    // ShellRoute: todas estas rutas comparten el mismo AppShell
    // (barra inferior + drawer), que no se reconstruye al navegar entre ellas.
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/inventario', builder: (context, state) => const InventarioScreen()),
        GoRoute(path: '/inventario/filtro', builder: (context, state) => const BuscarFiltroScreen()),
        GoRoute(path: '/insumo', builder: (context, state) => const InsumoDetalleScreen()),
        GoRoute(path: '/insumo/alta', builder: (context, state) => const InsumoAltaScreen()),
        GoRoute(path: '/scanner', builder: (context, state) => const ScannerScreen()),
        GoRoute(path: '/consumo', builder: (context, state) => const ConsumoScreen()),
        GoRoute(path: '/historial', builder: (context, state) => const HistorialScreen()),
        GoRoute(path: '/alertas', builder: (context, state) => const AlertasScreen()),
        GoRoute(path: '/compras', builder: (context, state) => const ComprasScreen()),
        GoRoute(path: '/tp', builder: (context, state) => const TpListaScreen()),
        GoRoute(path: '/tp/detalle', builder: (context, state) => const TpDetalleScreen()),
        GoRoute(path: '/tp/nuevo', builder: (context, state) => const TpEditarScreen()),
        GoRoute(path: '/usuarios', builder: (context, state) => const UsuariosScreen()),
        GoRoute(path: '/perfil', builder: (context, state) => const PerfilScreen()),
      ],
    ),
  ],
);
