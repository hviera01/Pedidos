import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../repositories/auth_repository.dart';
import '../core/theme/app_theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF05070C),
        title: const Text(
          'Gestor de Camisas',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        leading: isMobile
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
        actions: isMobile
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    backgroundColor: AppTheme.accent,
                    child: Text(
                      (auth.user?.nombre ?? 'U').substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ]
            : [
                _TopNavItem(label: 'Inicio', icon: Icons.dashboard_rounded, path: '/home'),
                _TopNavItem(label: 'Pedidos', icon: Icons.checkroom_rounded, path: '/pedidos'),
                _TopNavItem(label: 'Cobranzas', icon: Icons.payments_rounded, path: '/cxc'),
                _TopNavItem(label: 'Inventario', icon: Icons.inventory_2_rounded, path: '/inventario'),
                _TopNavItem(label: 'Clientes', icon: Icons.groups_rounded, path: '/clientes'),
                _TopNavItem(label: 'Reportes', icon: Icons.bar_chart_rounded, path: '/reportes'),
                _TopNavItem(label: 'Usuarios', icon: Icons.admin_panel_settings_rounded, path: '/usuarios'),
                const SizedBox(width: 16),
                Text(auth.user?.nombre ?? '', style: const TextStyle(color: AppTheme.muted)),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: AppTheme.accent,
                  child: Text(
                    (auth.user?.nombre ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => auth.logout(),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Salir'),
                ),
                const SizedBox(width: 18),
              ],
      ),
      drawer: isMobile ? _MobileDrawer(auth: auth) : null,
      body: child,
    );
  }
}

class _TopNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final String path;

  const _TopNavItem({
    required this.label,
    required this.icon,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    final selected = GoRouterState.of(context).uri.path == path;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TextButton.icon(
        onPressed: () => context.go(path),
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: TextButton.styleFrom(
          backgroundColor: selected ? AppTheme.accent : Colors.transparent,
          foregroundColor: selected ? Colors.white : AppTheme.muted,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  final AuthRepository auth;

  const _MobileDrawer({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF05070C),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),
            Container(
              width: 74,
              height: 74,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [AppTheme.accent, AppTheme.accent2]),
              ),
              child: const Icon(Icons.checkroom_rounded, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 14),
            const Text('Gestor de Camisas', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const Text('Pedidos • Cobros • Inventario', style: TextStyle(color: AppTheme.muted, fontSize: 12)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: const [
                  _DrawerItem(label: 'Inicio', icon: Icons.dashboard_rounded, path: '/home'),
                  _DrawerItem(label: 'Pedidos', icon: Icons.checkroom_rounded, path: '/pedidos'),
                  _DrawerItem(label: 'Cobranzas', icon: Icons.payments_rounded, path: '/cxc'),
                  _DrawerItem(label: 'Inventario', icon: Icons.inventory_2_rounded, path: '/inventario'),
                  _DrawerItem(label: 'Clientes', icon: Icons.groups_rounded, path: '/clientes'),
                  _DrawerItem(label: 'Reportes', icon: Icons.bar_chart_rounded, path: '/reportes'),
                  _DrawerItem(label: 'Usuarios', icon: Icons.admin_panel_settings_rounded, path: '/usuarios'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await auth.logout();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesión'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final String path;

  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    final selected = GoRouterState.of(context).uri.path == path;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        selected: selected,
        selectedTileColor: AppTheme.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: selected ? Colors.white : AppTheme.muted),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          context.go(path);
        },
      ),
    );
  }
}