import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/alerta.dart';
import '../providers/alerta_provider.dart';
import '../providers/role_provider.dart';
import '../models/usuario.dart';

import 'app_colors.dart';
import 'app_strings.dart';

import '../services/auth_logic/auth_service.dart';

// Envuelve todas las pantallas "internas" (las que tienen barra + drawer).
// go_router llama a este widget una sola vez y le va cambiando el [child]
// según la ruta actual, por eso la barra y el drawer no "parpadean" al
// navegar entre pantallas.
class AppShell extends ConsumerWidget {
  const AppShell({required this.location, required this.child, super.key});

  /// Ruta actual, para saber si hay que mostrar el botón flotante.
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleProvider);
    // A dónde lleva el botón flotante en la pantalla actual (null = sin botón).
    final rutaBotonAgregar = _rutaBotonAgregar(location, role);
    // La campana cuenta solo las alertas que la persona todavía no vio.
    // Mientras las alertas cargan, o si fallan, va sin número: no hace falta
    // avisar de nada que todavía no se sabe.
    final alertas = ref.watch(alertasSinVerProvider);

    return Scaffold(
      drawer: _AppDrawer(role: role),
      body: child,
      floatingActionButton: rutaBotonAgregar != null
          ? FloatingActionButton(
              onPressed: () => context.push(rutaBotonAgregar),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.inventory_2_outlined),
              onPressed: () => context.go('/inventario'),
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.go('/perfil'),
            ),
            IconButton(
              tooltip: alertas.isEmpty
                  ? AppStrings.alertasTitulo
                  : AppStrings.alertasConCantidad(alertas.length),
              // El número avisa cuántas alertas hay sin tener que entrar. Va en
              // rojo si alguna es crítica y en naranja si son solo avisos.
              icon: Badge(
                isLabelVisible: alertas.isNotEmpty,
                label: Text(alertas.length > 99 ? '99+' : '${alertas.length}'),
                textColor: Colors.white,
                backgroundColor:
                    alertas.any((a) => a.severidad == SeveridadAlerta.critica)
                        ? AppColors.stockDanger
                        : AppColors.stockWarning,
                child: const Icon(Icons.notifications_outlined),
              ),
              onPressed: () => context.go('/alertas'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem {
  const _DrawerItem(this.label, this.route);
  final String label;
  final String route;
}

// Qué ítems ve cada rol. Docente no ve Lista de compras ni Usuarios;
// Ayudante ve todo menos Usuarios; Administrador ve todo.
List<_DrawerItem> _itemsForRole(UserRole role) {
  final items = [
    const _DrawerItem('Inventario', '/inventario'),
    const _DrawerItem('Historial', '/historial'),
    const _DrawerItem('Lista para trabajos prácticos', '/tp'),
  ];
  if (role != UserRole.docente) {
    items.add(const _DrawerItem('Lista de compras', '/compras'));
  }
  if (role == UserRole.administrador) {
    items.add(const _DrawerItem('Usuarios', '/usuarios'));
  }
  return items;
}

// Ruta a la que lleva el botón flotante según la pantalla actual.
// Devuelve null cuando la pantalla no lleva botón.
String? _rutaBotonAgregar(String location, UserRole role) {
  // El diseño de Alertas no lleva el botón flotante.
  if (location == '/alertas') return null;

  // Lista de TPs: crear un TP (solo admin y docente).
  if (location == '/tp') {
    final puedeCrearTp =
        role == UserRole.administrador || role == UserRole.docente;
    return puedeCrearTp ? '/tp/nuevo' : null;
  }

  // Detalle y edición de TP: sin botón.
  if (location.startsWith('/tp/')) return null;

  // Resto de las pantallas: alta de insumo, como antes.
  return '/insumo/alta';
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final items = _itemsForRole(role);
    AuthService auth = AuthService();

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            for (final item in items)
              ListTile(
                title: Text(item.label),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go(item.route);
                },
              ),
            const Spacer(),
            ListTile(
              title: const Text('Cerrar sesión'),
              onTap: () async {
                //Navigator.of(context).pop();
                //context.go('/login');
                await auth.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}