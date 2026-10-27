import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/role_provider.dart';

// Envuelve todas las pantallas "internas" (las que tienen barra + drawer).
// go_router llama a este widget una sola vez y le va cambiando el [child]
// según la ruta actual, por eso la barra y el drawer no "parpadean" al
// navegar entre pantallas.
class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleProvider);

    return Scaffold(
      drawer: _AppDrawer(role: role),
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/insumo/alta'),
        child: const Icon(Icons.add),
      ),
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
              icon: const Icon(Icons.notifications_outlined),
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

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final items = _itemsForRole(role);

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
              onTap: () {
                Navigator.of(context).pop();
                context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
