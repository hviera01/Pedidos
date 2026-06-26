import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order_item.dart';
import '../../repositories/order_repository.dart';
import '../../widgets/smart_network_image.dart';

class PublicPedidoScreen extends StatelessWidget {
  final String pedidoId;

  const PublicPedidoScreen({
    super.key,
    required this.pedidoId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: StreamBuilder<List<OrderItem>>(
          stream: OrderRepository().streamOrderItems(pedidoId),
          builder: (context, snap) {
            final items = snap.data ?? [];

            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (items.isEmpty) {
              return const Center(
                child: Text('Este pedido no está disponible.'),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppTheme.panel,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(.16),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.checkroom_rounded,
                                color: AppTheme.accent,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Pedido compartido',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${items.length} ${items.length == 1 ? 'camisa registrada' : 'camisas registradas'}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      ...items.asMap().entries.map((entry) {
                        return _PublicItemCard(
                          index: entry.key + 1,
                          item: entry.value,
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PublicItemCard extends StatelessWidget {
  final int index;
  final OrderItem item;

  const _PublicItemCard({
    required this.index,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final version = item.version.trim().isEmpty ? 'Sin versión' : item.version.trim();
    final talla = item.talla.trim().isEmpty ? 'Sin talla' : item.talla.trim();
    final nombreNumero = item.nombreNumero.trim().isEmpty ? 'Sin nombre o número' : item.nombreNumero.trim();
    final cantidad = item.cantidad <= 0 ? 1 : item.cantidad;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.border),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final mobile = c.maxWidth < 720;

          if (mobile) {
            return Column(
              children: [
                _ImageBox(item: item),
                const SizedBox(height: 18),
                _InfoBox(
                  index: index,
                  version: version,
                  talla: talla,
                  nombreNumero: nombreNumero,
                  cantidad: cantidad,
                  item: item,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ImageBox(item: item),
              const SizedBox(width: 22),
              Expanded(
                child: _InfoBox(
                  index: index,
                  version: version,
                  talla: talla,
                  nombreNumero: nombreNumero,
                  cantidad: cantidad,
                  item: item,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ImageBox extends StatelessWidget {
  final OrderItem item;

  const _ImageBox({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      height: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.panel2,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Center(
        child: SmartNetworkImage(
          url: item.imgPrincipalUrl,
          width: 190,
          height: 170,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final int index;
  final String version;
  final String talla;
  final String nombreNumero;
  final int cantidad;
  final OrderItem item;

  const _InfoBox({
    required this.index,
    required this.version,
    required this.talla,
    required this.nombreNumero,
    required this.cantidad,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final parts = nombreNumero.split(RegExp(r'\s+'));
    final possibleNumber = parts.where((x) => RegExp(r'\d').hasMatch(x)).join(' ');
    final possibleName = nombreNumero.replaceAll(possibleNumber, '').trim();

    final nombre = possibleName.isEmpty ? nombreNumero : possibleName;
    final numero = possibleNumber.isEmpty ? 'No especificado' : possibleNumber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Camisa #$index',
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.panel2,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                version,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _DetailPill(title: 'Talla', value: talla),
            _DetailPill(title: 'Cantidad', value: '$cantidad'),
            _DetailPill(title: 'Nombre', value: nombre),
            _DetailPill(title: 'Número', value: numero),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Parches',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        if (item.imgsParchesUrl.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.panel2,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Text(
              'Sin parches registrados',
              style: TextStyle(color: AppTheme.muted),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: item.imgsParchesUrl.map((url) {
              return Container(
                width: 78,
                height: 78,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.panel2,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.border),
                ),
                child: SmartNetworkImage(
                  url: url,
                  width: 66,
                  height: 66,
                  fit: BoxFit.contain,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _DetailPill extends StatelessWidget {
  final String title;
  final String value;

  const _DetailPill({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 150,
        maxWidth: 250,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.panel2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}