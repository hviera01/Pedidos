import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../repositories/auth_repository.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/pedidos/pedidos_screen.dart';
import '../../screens/clientes/clientes_screen.dart';
import '../../screens/inventario/inventario_screen.dart';
import '../../screens/kardex/kardex_screen.dart';
import '../../screens/usuarios/usuarios_screen.dart';
import '../../screens/reportes/reportes_screen.dart';
import '../../screens/cxc/cxc_screen.dart';
import '../../screens/public/public_pedido_screen.dart';
import '../../widgets/app_shell.dart';

class AppRouter {
  static GoRouter create(BuildContext context) {
    final auth = Provider.of<AuthRepository>(context, listen: false);

    return GoRouter(
      initialLocation: auth.isLogged ? '/home' : '/login',
      refreshListenable: auth,
      redirect: (context, state) {
        final logged = auth.isLogged;
        final path = state.uri.path;
        final isLogin = path == '/login';
        final isPublic = path.startsWith('/public/');

        if (isPublic) {
          return null;
        }

        if (!logged && !isLogin) {
          return '/login';
        }

        if (logged && isLogin) {
          return '/home';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/public/:pedidoId',
          builder: (context, state) {
            final pedidoId = state.pathParameters['pedidoId'] ?? '';
            return PublicPedidoScreen(pedidoId: pedidoId);
          },
        ),
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/pedidos',
              builder: (context, state) => const PedidosScreen(),
            ),
            GoRoute(
              path: '/clientes',
              builder: (context, state) => const ClientesScreen(),
            ),
            GoRoute(
              path: '/inventario',
              builder: (context, state) => const InventarioScreen(),
            ),
            GoRoute(
              path: '/kardex',
              builder: (context, state) => const KardexScreen(),
            ),
            GoRoute(
              path: '/usuarios',
              builder: (context, state) => const UsuariosScreen(),
            ),
            GoRoute(
              path: '/reportes',
              builder: (context, state) => const ReportesScreen(),
            ),
            GoRoute(
              path: '/cxc',
              builder: (context, state) => const CxcScreen(),
            ),
          ],
        ),
      ],
    );
  }
}