import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order_item.dart';
import '../../models/product.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/page_frame.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Inicio',
      subtitle: 'Panel rápido para gestionar pedidos, cobros e inventario.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeroHome(),
          const SizedBox(height: 22),
          const Text(
            'Accesos rápidos',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 720;
              final cardWidth = isMobile ? constraints.maxWidth : (constraints.maxWidth - 28) / 3;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _ShortcutCard(
                    width: cardWidth,
                    title: 'Nuevo pedido',
                    subtitle: 'Crear pedido desde cero',
                    icon: Icons.add_rounded,
                    color: const Color(0xFFFF2E7E),
                    onTap: () => context.go('/pedidos'),
                  ),
                  _ShortcutCard(
                    width: cardWidth,
                    title: 'Cobrar cuenta',
                    subtitle: 'Registrar abonos pendientes',
                    icon: Icons.payments_rounded,
                    color: const Color(0xFF22C55E),
                    onTap: () => context.go('/cxc'),
                  ),
                  _ShortcutCard(
                    width: cardWidth,
                    title: 'Inventario',
                    subtitle: 'Revisar productos y stock',
                    icon: Icons.inventory_2_rounded,
                    color: const Color(0xFF3B82F6),
                    onTap: () => context.go('/inventario'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          StreamBuilder<List<OrderItem>>(
            stream: OrderRepository().streamAllItems(),
            builder: (context, snap) {
              final items = snap.data ?? [];
              final pendientes = items.where((x) => x.debe > 0).length;
              final total = items.length;

              return StreamBuilder<List<Product>>(
                stream: ProductRepository().streamProducts(),
                builder: (context, prodSnap) {
                  final productos = prodSnap.data ?? [];
                  final bajo = productos.where((x) => x.stock <= 5).length;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 720;
                      final infoWidth = isMobile ? constraints.maxWidth : (constraints.maxWidth - 14) / 2;

                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          _MiniInfoCard(
                            width: infoWidth,
                            title: 'Pedidos',
                            main: '$total registrados',
                            helper: pendientes > 0 ? '$pendientes con saldo pendiente' : 'Todo al día',
                            icon: Icons.checkroom_rounded,
                          ),
                          _MiniInfoCard(
                            width: infoWidth,
                            title: 'Inventario',
                            main: '${productos.length} productos',
                            helper: bajo > 0 ? '$bajo con stock bajo' : 'Stock estable',
                            icon: Icons.widgets_rounded,
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 22),
          _EmptyActivity(
            onTapPedidos: () => context.go('/pedidos'),
            onTapCxc: () => context.go('/cxc'),
          ),
        ],
      ),
    );
  }
}

class _HeroHome extends StatelessWidget {
  const _HeroHome();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF111827),
            Color(0xFF24174A),
            Color(0xFFFF2E7E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(.10)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(.18),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 680;

          return Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: isMobile ? 0 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 58,
                      width: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.14),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.checkroom_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Bienvenido a tu panel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gestioná pedidos, cobros e inventario de forma rápida y sencilla.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile) const SizedBox(width: 18),
              if (isMobile) const SizedBox(height: 22),
              Container(
                height: isMobile ? 150 : 180,
                width: isMobile ? double.infinity : 260,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.10),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(.12)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      right: 28,
                      top: 24,
                      child: Container(
                        height: 82,
                        width: 82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(.08),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      bottom: 20,
                      child: Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accent.withOpacity(.35),
                        ),
                      ),
                    ),
                    const Icon(Icons.sports_soccer_rounded, color: Colors.white, size: 86),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final double width;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: color.withOpacity(.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Text(subtitle, style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: Colors.white.withOpacity(.55)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniInfoCard extends StatelessWidget {
  final double width;
  final String title;
  final String main;
  final String helper;
  final IconData icon;

  const _MiniInfoCard({
    required this.width,
    required this.title,
    required this.main,
    required this.helper,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withOpacity(.08),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                const SizedBox(height: 5),
                Text(main, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(helper, style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  final VoidCallback onTapPedidos;
  final VoidCallback onTapCxc;

  const _EmptyActivity({
    required this.onTapPedidos,
    required this.onTapCxc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(.08),
            child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 14),
          const Text(
            'Todo listo para trabajar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Usá los accesos rápidos para crear pedidos o registrar cobros sin entrar a muchas pantallas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.muted, height: 1.4),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: onTapPedidos,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nuevo pedido'),
              ),
              OutlinedButton.icon(
                onPressed: onTapCxc,
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('Cobrar cuenta'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}