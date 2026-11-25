import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/alerta.dart';
import 'permisos.dart';
import '../providers/alerta_provider.dart';
import '../providers/perfil_provider.dart';
import '../providers/role_provider.dart';
import '../models/usuario.dart';

import 'app_colors.dart';
import 'app_strings.dart';
import 'app_text_styles.dart';
import 'breakpoints.dart';

import '../services/auth_logic/auth_service.dart';

/// Pantallas de la barra inferior y del menú que se abren con `go` (reemplazan
/// la pila). Desde ellas, el "atrás" del sistema vuelve a Inventario en vez de
/// cerrar la app; recién desde Inventario se sale.
const Set<String> rutasRaizDelShell = {
  '/home',
  '/alertas',
  '/perfil',
  '/tp',
  '/usuarios',
  '/importar',
  '/bajas',
};

// Envuelve todas las pantallas "internas" (las que tienen barra + drawer).
// go_router llama a este widget una sola vez y le va cambiando el [child]
// según la ruta actual, por eso la barra y el drawer no "parpadean" al
// navegar entre ellas.
//
// Se adapta al ancho de la ventana (ver [Breakpoints.compact]):
// - Angosto (celular): barra inferior + menú lateral que se abre (drawer).
// - Ancho (escritorio): panel lateral fijo con todos los destinos, sin barra
//   inferior ni drawer.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.location, required this.child, super.key});

  /// Ruta actual, para saber si hay que mostrar el botón flotante.
  final String location;
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  // Para saber si el menú está abierto cuando se toca "atrás".
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final location = widget.location;
    final child = widget.child;
    final role = ref.watch(roleProvider);
    // A dónde lleva el botón flotante en la pantalla actual (null = sin botón).
    final rutaBotonAgregar = _rutaBotonAgregar(location, role);
    // La campana cuenta solo las alertas que la persona todavía no vio.
    // Mientras las alertas cargan, o si fallan, va sin número: no hace falta
    // avisar de nada que todavía no se sabe.
    final alertas = ref.watch(alertasSinVerProvider);
    // El shell ocupa toda la ventana, así que alcanza con el ancho de la
    // ventana para decidir entre el diseño de celular y el de escritorio.
    final ancho = Breakpoints.esAnchoEn(context);

    return PopScope(
      // En las pantallas raíz, "atrás" lleva a Inventario; en Inventario (o en
      // una pantalla abierta encima) hace lo de siempre.
      canPop: !rutasRaizDelShell.contains(location),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Con el menú abierto, "atrás" solo lo cierra.
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          _scaffoldKey.currentState!.closeDrawer();
        } else {
          context.go('/inventario');
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: ancho ? null : _AppDrawer(role: role, location: location),
        body: ancho
            ? Row(
                children: [
                  _PanelLateral(role: role, location: location, alertas: alertas),
                  const VerticalDivider(width: 1),
                  Expanded(child: child),
                ],
              )
            : child,
        floatingActionButton: rutaBotonAgregar != null
            ? FloatingActionButton(
                onPressed: () => context.push(rutaBotonAgregar),
                child: const Icon(Icons.add),
              )
            : null,
        bottomNavigationBar: ancho ? null : BottomAppBar(
          shape: const CircularNotchedRectangle(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Builder(
                builder: (context) => IconButton(
                  tooltip: AppStrings.menuAbrir,
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              _BotonDeBarra(
                tooltip: AppStrings.homeTitulo,
                icono: Icons.home_outlined,
                iconoActivo: Icons.home,
                activo: location == '/home',
                onPressed: () => context.go('/home'),
              ),
              _BotonDeBarra(
                tooltip: AppStrings.menuInventario,
                icono: Icons.inventory_2_outlined,
                iconoActivo: Icons.inventory_2,
                activo: location == '/inventario' || location.startsWith('/insumo/'),
                onPressed: () => context.go('/inventario'),
              ),
              _BotonDeBarra(
                tooltip: AppStrings.perfilTitulo,
                icono: Icons.person_outline,
                iconoActivo: Icons.person,
                activo: location == '/perfil',
                onPressed: () => context.go('/perfil'),
              ),
              _BotonDeBarra(
                tooltip: alertas.isEmpty
                    ? AppStrings.alertasTitulo
                    : AppStrings.alertasConCantidad(alertas.length),
                // El número avisa cuántas alertas hay sin tener que entrar. Va en
                // rojo si alguna es crítica y en naranja si son solo avisos.
                icono: Icons.notifications_outlined,
                iconoActivo: Icons.notifications,
                activo: location == '/alertas',
                conInsignia: true,
                textoInsignia: _textoInsignia(alertas),
                insigniaVisible: alertas.isNotEmpty,
                colorInsignia: _colorInsignia(alertas),
                onPressed: () => context.go('/alertas'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// El número de la insignia de la campana. Lo usan la barra inferior y el panel
// lateral, para que digan siempre lo mismo.
String _textoInsignia(List<Alerta> alertas) =>
    alertas.length > 99 ? '99+' : '${alertas.length}';

// Rojo si alguna alerta es crítica, naranja si son solo avisos.
Color _colorInsignia(List<Alerta> alertas) =>
    alertas.any((a) => a.severidad == SeveridadAlerta.critica)
        ? AppColors.stockDanger
        : AppColors.stockWarning;

// Un botón de la barra inferior: el ícono de la pantalla en la que se está va
// relleno y con el color de la marca, para saber dónde se está parado.
class _BotonDeBarra extends StatelessWidget {
  const _BotonDeBarra({
    required this.tooltip,
    required this.icono,
    required this.iconoActivo,
    required this.activo,
    required this.onPressed,
    this.conInsignia = false,
    this.textoInsignia = '',
    this.insigniaVisible = false,
    this.colorInsignia,
  });

  final String tooltip;
  final IconData icono;
  final IconData iconoActivo;
  final bool activo;
  final VoidCallback onPressed;

  /// La insignia con un número (la campana de alertas).
  final bool conInsignia;
  final String textoInsignia;
  final bool insigniaVisible;
  final Color? colorInsignia;

  @override
  Widget build(BuildContext context) {
    final dibujo = Icon(
      activo ? iconoActivo : icono,
      color: activo ? AppColors.primary : null,
    );

    return IconButton(
      tooltip: tooltip,
      isSelected: activo,
      icon: conInsignia
          ? Badge(
              isLabelVisible: insigniaVisible,
              label: Text(textoInsignia),
              textColor: Colors.white,
              backgroundColor: colorInsignia,
              child: dibujo,
            )
          : dibujo,
      onPressed: onPressed,
    );
  }
}

class _DrawerItem {
  const _DrawerItem(this.label, this.route, {this.fueraDelShell = false});
  final String label;
  final String route;

  /// Pantallas que se abren sin barra inferior ni menú (Historial y Compras):
  /// se abren encima (push) para que el "atrás" vuelva a donde se estaba, igual
  /// que desde Inicio.
  final bool fueraDelShell;
}

// Qué ítems ve cada rol. Docente no ve Lista de compras ni Usuarios;
// Ayudante ve todo menos Usuarios; Administrador ve todo.
List<_DrawerItem> _itemsForRole(UserRole role) {
  final items = [
    const _DrawerItem(AppStrings.menuInventario, '/inventario'),
    const _DrawerItem(AppStrings.menuHistorial, '/historial', fueraDelShell: true),
    const _DrawerItem(AppStrings.menuTps, '/tp'),
  ];
  if (Permisos.puedeVerCompras(role)) {
    items.add(const _DrawerItem(AppStrings.menuCompras, '/compras', fueraDelShell: true));
  }
  if (Permisos.puedeGestionarUsuarios(role)) {
    items.add(const _DrawerItem(AppStrings.menuUsuarios, '/usuarios'));
  }
  if (Permisos.puedeImportar(role)) {
    items.add(const _DrawerItem(AppStrings.menuImportar, '/importar'));
  }
  if (Permisos.puedeEditarOBaja(role)) {
    items.add(const _DrawerItem(AppStrings.insumosDeBajaMenu, '/bajas'));
  }
  return items;
}

// Ruta a la que lleva el botón flotante según la pantalla actual.
// Devuelve null cuando la pantalla no lleva botón.
String? _rutaBotonAgregar(String location, UserRole role) {
  // El diseño de Alertas no lleva el botón flotante.
  if (location == '/alertas') return null;

  // Inicio, Perfil, Usuarios, Importar e Insumos dados de baja no dan de alta
  // nada: un "+" ahí llevaría al Alta sin que tenga que ver con lo que se está
  // viendo.
  if (location == '/home' ||
      location == '/perfil' ||
      location == '/usuarios' ||
      location == '/importar' ||
      location == '/bajas') {
    return null;
  }

  // Lista de TPs: crear un TP (solo admin y docente).
  if (location == '/tp') {
    return Permisos.puedeEditarTps(role) ? '/tp/nuevo' : null;
  }

  // Detalle y edición de TP: sin botón.
  if (location.startsWith('/tp/')) return null;

  // Alta y detalle de un insumo: sin botón. En el Alta llevaría a la misma
  // pantalla en la que ya se está, y en las dos tapa los botones de abajo
  // ("Guardar" y "Registrar consumo").
  if (location.startsWith('/insumo/')) return null;

  // Resto de las pantallas: alta de insumo, solo para quien puede darlos de alta.
  return Permisos.puedeDarDeAlta(role) ? '/insumo/alta' : null;
}

// Si el destino [route] es la sección en la que está la persona. Una pantalla
// "hija" cuenta como su sección: el detalle y el alta de un insumo son parte de
// Inventario, y el detalle y la edición de un TP son parte de TPs.
bool _estaEnSeccion(String route, String location) {
  if (route == '/inventario') {
    return location == route ||
        location.startsWith('$route/') ||
        location.startsWith('/insumo/');
  }
  return location == route || location.startsWith('$route/');
}

// El ícono de cada destino en el panel lateral.
IconData _iconoDe(String route) => switch (route) {
      '/home' => Icons.home_outlined,
      '/inventario' => Icons.inventory_2_outlined,
      '/historial' => Icons.history,
      '/tp' => Icons.science_outlined,
      '/compras' => Icons.shopping_cart_outlined,
      '/usuarios' => Icons.people_outline,
      '/importar' => Icons.upload_file_outlined,
      '/bajas' => Icons.archive_outlined,
      '/alertas' => Icons.notifications_outlined,
      '/perfil' => Icons.person_outline,
      _ => Icons.circle_outlined,
    };

// Panel lateral fijo del diseño de escritorio. Tiene los mismos destinos que el
// menú de celular, más Inicio, Alertas y Perfil, que en celular están en la
// barra inferior.
class _PanelLateral extends StatelessWidget {
  const _PanelLateral({
    required this.role,
    required this.location,
    required this.alertas,
  });

  final UserRole role;
  final String location;
  final List<Alerta> alertas;

  static const double _ancho = 260;

  @override
  Widget build(BuildContext context) {
    final destinos = [
      const _DrawerItem(AppStrings.homeTitulo, '/home'),
      ..._itemsForRole(role),
      const _DrawerItem(AppStrings.alertasTitulo, '/alertas'),
      const _DrawerItem(AppStrings.perfilTitulo, '/perfil'),
    ];

    return SizedBox(
      width: _ancho,
      child: Material(
        color: AppColors.screenBackground,
        child: SafeArea(
          right: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  AppStrings.usuariosRol(role),
                  style: AppTextStyles.itemDetail,
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final destino in destinos)
                      ListTile(
                        leading: _icono(destino),
                        title: Text(destino.label),
                        selected: _estaEnSeccion(destino.route, location),
                        selectedColor: AppColors.primary,
                        onTap: () {
                          // Igual que en el menú de celular: Historial y
                          // Compras se abren encima, el resto reemplaza.
                          if (destino.fueraDelShell) {
                            context.push(destino.route);
                          } else {
                            context.go(destino.route);
                          }
                        },
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text(AppStrings.menuCerrarSesion),
                onTap: () => _AppDrawer.cerrarSesion(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // La campana lleva el número de alertas sin ver, como en la barra inferior.
  Widget _icono(_DrawerItem destino) {
    final icono = Icon(_iconoDe(destino.route));
    if (destino.route != '/alertas') return icono;

    return Badge(
      isLabelVisible: alertas.isNotEmpty,
      label: Text(_textoInsignia(alertas)),
      textColor: Colors.white,
      backgroundColor: _colorInsignia(alertas),
      child: icono,
    );
  }
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer({required this.role, required this.location});

  final UserRole role;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _itemsForRole(role);
    // El nombre sale del documento de la persona; si todavía no llegó (o no se
    // pudo leer), el menú muestra solo el rol.
    final nombre = ref.watch(perfilUsuarioProvider).value?.nombre ?? '';

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 0, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (nombre.isNotEmpty)
                          Text(
                            nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.listItemTitle,
                          ),
                        Text(
                          AppStrings.usuariosRol(role),
                          style: AppTextStyles.itemDetail,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: AppStrings.cerrar,
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            for (final item in items)
              ListTile(
                title: Text(item.label),
                // La pantalla actual va marcada.
                selected: location == item.route,
                selectedColor: AppColors.primary,
                onTap: () {
                  Navigator.of(context).pop();
                  if (item.fueraDelShell) {
                    context.push(item.route);
                  } else {
                    context.go(item.route);
                  }
                },
              ),
            const Spacer(),
            ListTile(
              title: const Text(AppStrings.menuCerrarSesion),
              onTap: () => cerrarSesion(context),
            ),
          ],
        ),
      ),
    );
  }

  // Pregunta antes de cerrar: es fácil tocarlo sin querer al pie del menú. Al
  // cerrar la sesión, el router manda solo a Bienvenida. Es estático para que
  // lo use también el panel lateral de escritorio.
  static Future<void> cerrarSesion(BuildContext context) async {
    final auth = AuthService();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text(AppStrings.menuCerrarTitulo),
        content: const Text(AppStrings.menuCerrarTexto),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(false),
            child: const Text(AppStrings.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(true),
            child: const Text(AppStrings.menuCerrarConfirmar),
          ),
        ],
      ),
    );
    if (confirmado == true) await auth.signOut();
  }
}