import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_logic/auth_service.dart';
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
  initialLocation: 'inventario',
  
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()), 
  redirect: (context, state) {
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null; 
    final String location = state.uri.path; 
    final bool isAuthRoute = location == '/welcome' || location == '/login' || location == '/register'; 
    if (!isLoggedIn && !isAuthRoute) {return '/welcome';} 
    if (isLoggedIn && isAuthRoute) { return '/inventario'; } 
    return null; 
  },
  
  routes: [
    // Pantallas sin barra ni drawer (todavía no hay sesión iniciada).
    GoRoute(path: '/auth', builder: (context, state) => const AuthWrapper()),
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),

    // Historial va sin barra inferior ni botón flotante, como en el diseño.
    GoRoute(path: '/historial', builder: (context, state) => const HistorialScreen()),

    // Lista de compras también va sin barra inferior y con su propio botón
    // flotante, como en el diseño.
    GoRoute(path: '/compras', builder: (context, state) => const ComprasScreen()),

    // El escáner de código de barras es la cámara a pantalla completa, sin barra
    // inferior ni botón flotante, como en el diseño.
    GoRoute(path: '/scanner', builder: (context, state) => const ScannerScreen()),

    // Registro de consumo también va sin barra inferior ni botón flotante, como
    // en el diseño. /consumo?insumo=ID abre la pantalla con ese insumo ya
    // elegido.
    GoRoute(
      path: '/consumo',
      builder: (context, state) =>
          ConsumoScreen(insumoId: state.uri.queryParameters['insumo']),
    ),

    // ShellRoute: todas estas rutas comparten el mismo AppShell
    // (barra inferior + drawer), que no se reconstruye al navegar entre ellas.
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/inventario', builder: (context, state) => const InventarioScreen()),
        GoRoute(path: '/inventario/filtro', builder: (context, state) => const BuscarFiltroScreen()),
        // /insumo/alta va antes que /insumo/:id; si no, go_router tomaría
        // "alta" como si fuera el id de un insumo.
        GoRoute(path: '/insumo/alta', builder: (context, state) => const InsumoAltaScreen()),
        GoRoute(
          path: '/insumo/:id',
          builder: (context, state) =>
              InsumoDetalleScreen(insumoId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/alertas', builder: (context, state) => const AlertasScreen()),
        GoRoute(path: '/tp', builder: (context, state) => const TpListaScreen()),
        //GoRoute(path: '/tp/detalle', builder: (context, state) => const TpDetalleScreen()),
        //GoRoute(path: '/tp/nuevo', builder: (context, state) => const TpEditarScreen()),
        GoRoute(path: '/tp/nuevo', builder: (context, state) => const TpEditarScreen()),
        GoRoute(path: '/tp/detalle/:id',builder: (context, state) => TpDetalleScreen(tpId: state.pathParameters['id']!),),
        GoRoute(path: '/tp/editar/:id', builder: (context, state) => TpEditarScreen(tpId: state.pathParameters['id']),),
        GoRoute(path: '/usuarios', builder: (context, state) => const UsuariosScreen()),
        GoRoute(path: '/perfil', builder: (context, state) => const PerfilScreen()),
      ],
    ),
  ],
);

/*
GoRoute(path: '/tp/nuevo', builder: (context, state) => const TpEditarScreen()),
GoRoute(
  path: '/tp/detalle/:id',
  builder: (context, state) => TpDetalleScreen(tpId: state.pathParameters['id']!),
),
GoRoute(
  path: '/tp/editar/:id',
  builder: (context, state) => TpEditarScreen(tpId: state.pathParameters['id']),
),
*/