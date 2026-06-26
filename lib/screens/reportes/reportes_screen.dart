import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_item.dart';
import '../../models/product.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/page_frame.dart';

class ReportesScreen extends StatelessWidget {
  const ReportesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Reportes',
      subtitle: 'Vista general de pedidos, entregas, cuentas pendientes e inventario.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<List<OrderItem>>(
            stream: OrderRepository().streamAllItems(),
            builder: (context, orderSnap) {
              final items = orderSnap.data ?? [];
              final totalCamisas = items.fold<int>(0, (a, b) => a + b.cantidad);
              final pedidosPendientes = items.where((x) => !x.entregado).length;
              final pedidosEntregados = items.where((x) => x.entregado).length;
              final conSaldo = items.where((x) => x.debe > 0).length;
              final saldoPendiente = items.fold<double>(0, (a, b) => a + b.debe);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      _ReportCard(
                        title: 'Camisas en pedidos',
                        value: '$totalCamisas',
                        hint: 'Cantidad total solicitada',
                        icon: Icons.checkroom_rounded,
                        color: const Color(0xFF3B82F6),
                      ),
                      _ReportCard(
                        title: 'Pendientes',
                        value: '$pedidosPendientes',
                        hint: 'Aún no entregados',
                        icon: Icons.pending_actions_rounded,
                        color: const Color(0xFFF59E0B),
                      ),
                      _ReportCard(
                        title: 'Entregados',
                        value: '$pedidosEntregados',
                        hint: 'Pedidos finalizados',
                        icon: Icons.verified_rounded,
                        color: const Color(0xFF22C55E),
                      ),
                      _ReportCard(
                        title: 'Con saldo',
                        value: '$conSaldo',
                        hint: Formatters.money(saldoPendiente),
                        icon: Icons.receipt_long_rounded,
                        color: const Color(0xFFFF2E7E),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _OrdersSummary(items: items),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          StreamBuilder<List<Product>>(
            stream: ProductRepository().streamProducts(),
            builder: (context, snap) {
              final products = snap.data ?? [];
              final bajo = products.where((x) => x.stock <= 5).toList();

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.panel,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Alertas de inventario',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(.12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '${bajo.length} bajos',
                            style: const TextStyle(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (bajo.isEmpty)
                      const _EmptyBox(
                        icon: Icons.inventory_2_rounded,
                        title: 'Inventario estable',
                        text: 'No hay productos con stock bajo por ahora.',
                      )
                    else
                      ...bajo.map((x) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white.withOpacity(.08),
                                child: const Icon(Icons.warning_rounded, color: Color(0xFFF59E0B)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  x.descripcion,
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                              Text(
                                '${x.stock}',
                                style: const TextStyle(
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OrdersSummary extends StatelessWidget {
  final List<OrderItem> items;

  const _OrdersSummary({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final pendientes = items.where((x) => !x.entregado).take(5).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pedidos por revisar',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (pendientes.isEmpty)
            const _EmptyBox(
              icon: Icons.task_alt_rounded,
              title: 'Sin pedidos pendientes',
              text: 'Todos los pedidos registrados aparecen como entregados.',
            )
          else
            ...pendientes.map((x) {
              final cliente = x.clienteNombre.trim().isEmpty ? 'Sin nombre' : x.clienteNombre.trim();

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.accent.withOpacity(.14),
                      child: const Icon(Icons.checkroom_rounded, color: AppTheme.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cliente,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${x.cantidad} camisa${x.cantidad == 1 ? '' : 's'}',
                            style: const TextStyle(color: AppTheme.muted),
                          ),
                        ],
                      ),
                    ),
                    if (x.debe > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF2E7E).withOpacity(.13),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          Formatters.money(x.debe),
                          style: const TextStyle(
                            color: Color(0xFFFF2E7E),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withOpacity(.13),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'Pagado',
                          style: TextStyle(
                            color: Color(0xFF22C55E),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final String hint;
  final IconData icon;
  final Color color;

  const _ReportCard({
    required this.title,
    required this.value,
    required this.hint,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _EmptyBox({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(.08),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}