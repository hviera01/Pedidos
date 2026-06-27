import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_item.dart';
import '../../models/customer.dart';
import '../../repositories/customer_repository.dart';
import '../../repositories/order_repository.dart';
import '../../services/storage_service.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/smart_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  final repo = OrderRepository();
  String? selectedPedidoId;
  bool loadingPedidoGuardado = true;
  bool desktopCardsView = false;

  String get _activeKey {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    return 'pedido_activo_$uid';
  }

  @override
  void initState() {
    super.initState();
    cargarPedidoGuardado();
  }

  Future<void> cargarPedidoGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    final pid = prefs.getString(_activeKey);

    if (!mounted) return;

    setState(() {
      selectedPedidoId = pid;
      loadingPedidoGuardado = false;
    });
  }

  Future<void> guardarPedidoActivo(String? pedidoId) async {
    final prefs = await SharedPreferences.getInstance();

    if (pedidoId == null || pedidoId.isEmpty) {
      await prefs.remove(_activeKey);
    } else {
      await prefs.setString(_activeKey, pedidoId);
    }
  }

  Future<void> openForm([OrderItem? item]) async {
  await showDialog(
    context: context,
    builder: (_) => _OrderItemDialog(
      item: item,
      pedidoId: selectedPedidoId,
    ),
  );
}

  Future<void> openImages(OrderItem item) async {
    await showDialog(
      context: context,
      builder: (_) => _ImagesDialog(item: item),
    );
  }

  Future<void> openPay(OrderItem item) async {
    await showDialog(
      context: context,
      builder: (_) => _PayDialog(item: item),
    );
  }

  Future<void> openHistory() async {
  final pedidoId = await showDialog<String>(
    context: context,
    builder: (_) => const _HistoryDialog(),
  );

  if (!mounted || pedidoId == null || pedidoId.isEmpty) return;

  await guardarPedidoActivo(pedidoId);
  setState(() => selectedPedidoId = pedidoId);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Pedido abierto')),
  );
}

  Future<void> newOrder() async {
  final pid = await repo.createBlankOrder();

  if (!mounted) return;

  await guardarPedidoActivo(pid);
  setState(() => selectedPedidoId = pid);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Nuevo pedido creado')),
  );
}

  Future<void> share() async {
  try {
    final pid = selectedPedidoId ?? await repo.getOrCreateActiveOrder();

    await repo.enablePublicAccess(pid);

    final base = Uri.base.origin + Uri.base.path;
    final url = '${base.endsWith('/') ? base : '$base/'}#/public/$pid';

    try {
      await Share.share(url);
    } catch (_) {}

    try {
      await Clipboard.setData(ClipboardData(text: url));
    } catch (_) {}

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Enlace listo: $url'),
        duration: const Duration(seconds: 5),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se pudo compartir: $e')),
    );
  }
}
  
Future<void> deleteItem(OrderItem item) async {
  final messenger = ScaffoldMessenger.of(context);

  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.panel,
      title: const Text('Eliminar camisa'),
      content: const Text('¿Seguro que querés eliminar esta camisa del pedido?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );

  if (ok != true) return;

  try {
    await repo.deleteItem(item);

    if (!mounted) return;

    setState(() {});

    messenger.showSnackBar(
      const SnackBar(content: Text('Camisa eliminada correctamente')),
    );
  } catch (e) {
    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(content: Text('No se pudo eliminar: $e')),
    );
  }
}

  Future<void> closeOrder() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.panel,
        title: const Text('Cerrar pedido'),
        content: const Text('Se cerrará el pedido activo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await repo.closeOrder(selectedPedidoId);
      await guardarPedidoActivo(null);
      setState(() => selectedPedidoId = null);
    }
  }

  @override
Widget build(BuildContext context) {
  if (loadingPedidoGuardado) {
    return const Center(child: CircularProgressIndicator());
  }

  final pageIsMobile = MediaQuery.of(context).size.width < 760;

  return PageFrame(
    title: pageIsMobile ? '' : 'Pedidos',
    subtitle: pageIsMobile ? '' : 'Control de camisas, fotos, parches, pagos y saldo pendiente.',
    actions: pageIsMobile
        ? []
        : [
            OutlinedButton.icon(
              onPressed: () => openForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar camisa'),
            ),
            OutlinedButton.icon(
              onPressed: share,
              icon: const Icon(Icons.link_rounded),
              label: const Text('Compartir'),
            ),
            OutlinedButton.icon(
              onPressed: openHistory,
              icon: const Icon(Icons.history_rounded),
              label: const Text('Historial'),
            ),
            OutlinedButton.icon(
              onPressed: closeOrder,
              icon: const Icon(Icons.lock_rounded),
              label: const Text('Cerrar pedido'),
            ),
            OutlinedButton.icon(
              onPressed: newOrder,
              icon: const Icon(Icons.note_add_rounded),
              label: const Text('Nuevo pedido'),
            ),
            if (selectedPedidoId != null)
              OutlinedButton.icon(
                onPressed: () async {
                  await guardarPedidoActivo(null);
                  if (!context.mounted) return;
                  setState(() => selectedPedidoId = null);
                },
                icon: const Icon(Icons.home_rounded),
                label: const Text('Pedido activo'),
              ),
          ],
    child: StreamBuilder<List<OrderItem>>(
      stream: selectedPedidoId == null ? repo.streamActiveItems() : repo.streamOrderItems(selectedPedidoId!),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              'Error: ${snap.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final items = snap.data ?? [];
        final total = items.fold<double>(0, (a, b) => a + b.totalVenta);
        final pagado = items.fold<double>(0, (a, b) => a + b.pagado);
        final debe = items.fold<double>(0, (a, b) => a + b.debe);
        final isMobile = MediaQuery.of(context).size.width < 760;

        if (isMobile) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return SizedBox(
            height: MediaQuery.of(context).size.height - 95,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              cacheExtent: 700,
              itemCount: items.isEmpty ? 3 : items.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pedidos',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Control de camisas, fotos, parches, pagos y saldo pendiente.',
                          style: TextStyle(
                            color: AppTheme.muted,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => openForm(),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Agregar camisa'),
                            ),
                            OutlinedButton.icon(
                              onPressed: share,
                              icon: const Icon(Icons.link_rounded),
                              label: const Text('Compartir'),
                            ),
                            OutlinedButton.icon(
                              onPressed: openHistory,
                              icon: const Icon(Icons.history_rounded),
                              label: const Text('Historial'),
                            ),
                            OutlinedButton.icon(
                              onPressed: closeOrder,
                              icon: const Icon(Icons.lock_rounded),
                              label: const Text('Cerrar pedido'),
                            ),
                            OutlinedButton.icon(
                              onPressed: newOrder,
                              icon: const Icon(Icons.note_add_rounded),
                              label: const Text('Nuevo pedido'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                if (index == 1) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _KpiGrid(
                      items: [
                        _KpiData(title: 'Camisas', value: '${items.length}', icon: Icons.checkroom_rounded),
                        _KpiData(title: 'Total', value: Formatters.money(total), icon: Icons.sell_rounded),
                        _KpiData(title: 'Pagado', value: Formatters.money(pagado), icon: Icons.payments_rounded),
                        _KpiData(title: 'Pendiente', value: Formatters.money(debe), icon: Icons.warning_rounded),
                      ],
                    ),
                  );
                }

                if (items.isEmpty) {
                  return const _EmptyState();
                }

                final item = items[index - 2];

                return RepaintBoundary(
                  child: _MobileOrderCard(
                    index: index - 1,
                    item: item,
                    onEdit: () => openForm(item),
                    onImages: () => openImages(item),
                    onPay: () => openPay(item),
                    onDelete: () => deleteItem(item),
                  ),
                );
              },
            ),
          );
        }

        return Column(
          children: [
            _KpiGrid(
              items: [
                _KpiData(title: 'Camisas', value: '${items.length}', icon: Icons.checkroom_rounded),
                _KpiData(title: 'Total', value: Formatters.money(total), icon: Icons.sell_rounded),
                _KpiData(title: 'Pagado', value: Formatters.money(pagado), icon: Icons.payments_rounded),
                _KpiData(title: 'Pendiente', value: Formatters.money(debe), icon: Icons.warning_rounded),
              ],
            ),
            const SizedBox(height: 14),
            if (items.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.table_rows_rounded),
                      label: Text('Tabla'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.dashboard_rounded),
                      label: Text('Cards'),
                    ),
                  ],
                  selected: {desktopCardsView},
                  onSelectionChanged: (value) {
                    setState(() => desktopCardsView = value.first);
                  },
                ),
              ),
            const SizedBox(height: 18),
            if (snap.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (items.isEmpty)
              const _EmptyState()
            else if (desktopCardsView)
              _DesktopOrderCards(
                items: items,
                onEdit: openForm,
                onImages: openImages,
                onPay: openPay,
                onDelete: deleteItem,
              )
            else
              _DesktopOrderTable(
                items: items,
                onEdit: openForm,
                onImages: openImages,
                onPay: openPay,
                onDelete: deleteItem,
              ),
          ],
        );
      },
    ),
  );
}
}

class _KpiData {
  final String title;
  final String value;
  final IconData icon;

  const _KpiData({
    required this.title,
    required this.value,
    required this.icon,
  });
}

class _KpiGrid extends StatelessWidget {
  final List<_KpiData> items;

  const _KpiGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final mobile = c.maxWidth < 760;
        final itemWidth = mobile ? (c.maxWidth - 10) / 2 : 245.0;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((x) {
            return SizedBox(
              width: itemWidth,
              child: _Kpi(data: x, compact: mobile),
            );
          }).toList(),
        );
      },
    );
  }
}

class _Kpi extends StatelessWidget {
  final _KpiData data;
  final bool compact;

  const _Kpi({
    required this.data,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 18),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: compact ? 18 : 22,
            backgroundColor: AppTheme.accent.withOpacity(.18),
            child: Icon(data.icon, color: AppTheme.accent, size: compact ? 19 : 23),
          ),
          SizedBox(width: compact ? 9 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: compact ? 11 : 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 15 : 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopOrderTable extends StatelessWidget {
  final List<OrderItem> items;
  final void Function(OrderItem item) onEdit;
  final void Function(OrderItem item) onImages;
  final void Function(OrderItem item) onPay;
  final void Function(OrderItem item) onDelete;

  const _DesktopOrderTable({
    required this.items,
    required this.onEdit,
    required this.onImages,
    required this.onPay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final tableWidth = c.maxWidth < 1320 ? 1320.0 : c.maxWidth;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  const _TableHeader(),
                  ...items.asMap().entries.map((e) {
                    return _TableRowItem(
                      index: e.key + 1,
                      item: e.value,
                      onEdit: () => onEdit(e.value),
                      onImages: () => onImages(e.value),
                      onPay: () => onPay(e.value),
                      onDelete: () => onDelete(e.value),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DesktopOrderCards extends StatelessWidget {
  final List<OrderItem> items;
  final void Function(OrderItem item) onEdit;
  final void Function(OrderItem item) onImages;
  final void Function(OrderItem item) onPay;
  final void Function(OrderItem item) onDelete;

  const _DesktopOrderCards({
    required this.items,
    required this.onEdit,
    required this.onImages,
    required this.onPay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.asMap().entries.map((entry) {
        return _DesktopOrderCard(
          index: entry.key + 1,
          item: entry.value,
          onEdit: () => onEdit(entry.value),
          onImages: () => onImages(entry.value),
          onPay: () => onPay(entry.value),
          onDelete: () => onDelete(entry.value),
        );
      }).toList(),
    );
  }
}

class _DesktopOrderCard extends StatelessWidget {
  final int index;
  final OrderItem item;
  final VoidCallback onEdit;
  final VoidCallback onImages;
  final VoidCallback onPay;
  final VoidCallback onDelete;

  const _DesktopOrderCard({
    required this.index,
    required this.item,
    required this.onEdit,
    required this.onImages,
    required this.onPay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final version = item.version.trim().isEmpty ? 'FAN' : item.version.trim();
    final talla = item.talla.trim().isEmpty ? 'L' : item.talla.trim();
    final cantidad = item.cantidad <= 0 ? 1 : item.cantidad;
    final cliente = item.clienteNombre.trim().isEmpty ? 'Sin cliente' : item.clienteNombre.trim();
    final nombreNumero = item.nombreNumero.trim();
final parts = nombreNumero.split(RegExp(r'\s+')).where((x) => x.trim().isNotEmpty).toList();
final numeros = parts.where((x) => RegExp(r'\d').hasMatch(x)).toList();
final nombres = parts.where((x) => !RegExp(r'\d').hasMatch(x)).toList();

final numero = numeros.isEmpty ? 'No especificado' : numeros.join(' ');
final nombre = nombres.isEmpty ? 'Sin nombre' : nombres.join(' ');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
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
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppTheme.panel2,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        item.entregado ? 'Entregado' : 'Pendiente',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: item.entregado ? AppTheme.ok : Colors.amber,
                        ),
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      tooltip: 'Opciones',
                      color: AppTheme.panel,
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'images') onImages();
                        if (value == 'pay') onPay();
                        if (value == 'delivered') OrderRepository().setDelivered(item, !item.entregado);
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Editar')),
                        const PopupMenuItem(value: 'images', child: Text('Imágenes')),
                        const PopupMenuItem(value: 'pay', child: Text('Abonar')),
                        PopupMenuItem(value: 'delivered', child: Text(item.entregado ? 'Marcar pendiente' : 'Marcar entregado')),
                        const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _CardInfoBox(title: 'Versión', value: version),
                    _CardInfoBox(title: 'Talla', value: talla),
                    _CardInfoBox(title: 'Cantidad', value: '$cantidad'),
                    _CardInfoBox(title: 'Cliente', value: cliente),
                    _CardInfoBox(title: 'Nombre', value: nombre.isEmpty ? nombreNumero : nombre),
                    _CardInfoBox(title: 'Número', value: numero.isEmpty ? 'No especificado' : numero),
                    _CardInfoBox(title: 'Total', value: Formatters.money(item.totalVenta)),
                    _CardInfoBox(title: 'Pagado', value: Formatters.money(item.pagado)),
                    _CardInfoBox(title: 'Debe', value: Formatters.money(item.debe), danger: item.debe > 0),
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
                _Patches(urls: item.imgsParchesUrl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardInfoBox extends StatelessWidget {
  final String title;
  final String value;
  final bool danger;

  const _CardInfoBox({
    required this.title,
    required this.value,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.panel2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: danger ? AppTheme.accent : AppTheme.border),
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
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: danger ? AppTheme.accent : AppTheme.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: AppTheme.muted,
      fontSize: 12,
      fontWeight: FontWeight.w900,
    );

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: AppTheme.panel2,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 50, child: Text('#', style: style)),
          SizedBox(width: 130, child: Text('Imagen', style: style)),
          SizedBox(width: 230, child: Text('Camisa', style: style)),
          SizedBox(width: 240, child: Text('Cliente', style: style)),
          SizedBox(width: 170, child: Text('Parches', style: style)),
          SizedBox(width: 70, child: Text('Cant', style: style)),
          SizedBox(width: 185, child: Text('Pagos', style: style)),
          SizedBox(width: 95, child: Text('Estado', style: style)),
          SizedBox(width: 80, child: Text('Acciones', style: style)),
        ],
      ),
    );
  }
}

class _TableRowItem extends StatelessWidget {
  final int index;
  final OrderItem item;
  final VoidCallback onEdit;
  final VoidCallback onImages;
  final VoidCallback onPay;
  final VoidCallback onDelete;

  const _TableRowItem({
    required this.index,
    required this.item,
    required this.onEdit,
    required this.onImages,
    required this.onPay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final version = item.version.trim().isEmpty ? 'FAN' : item.version.trim();
    final talla = item.talla.trim().isEmpty ? 'L' : item.talla.trim();
    final cantidad = item.cantidad <= 0 ? 1 : item.cantidad;
    final cliente = item.clienteNombre.trim().isEmpty ? 'Sin cliente' : item.clienteNombre.trim();
    final nombre = item.nombreNumero.trim().isEmpty ? 'Sin nombre' : item.nombreNumero.trim();

    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 50, child: Text('$index', style: const TextStyle(fontWeight: FontWeight.w900))),
          SizedBox(
            width: 130,
            child: SmartNetworkImage(
              url: item.imgPrincipalUrl,
              width: 100,
              height: 82,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(
            width: 230,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$version • $talla', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(nombre, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
              ],
            ),
          ),
          SizedBox(
            width: 240,
            child: Text(cliente, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
          SizedBox(width: 170, child: _Patches(urls: item.imgsParchesUrl)),
          SizedBox(width: 70, child: Text('$cantidad', style: const TextStyle(fontWeight: FontWeight.w900))),
          SizedBox(
            width: 185,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MoneyLine(label: 'Pagado', value: Formatters.money(item.pagado)),
                _MoneyLine(label: 'Total', value: Formatters.money(item.totalVenta)),
                _MoneyLine(label: 'Debe', value: Formatters.money(item.debe), danger: item.debe > 0),
              ],
            ),
          ),
          SizedBox(
  width: 95,
  child: Align(
    alignment: Alignment.centerLeft,
    child: InkWell(
      onTap: () => OrderRepository().setDelivered(item, !item.entregado),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: item.entregado ? AppTheme.ok.withOpacity(.12) : Colors.amber.withOpacity(.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: item.entregado ? AppTheme.ok : Colors.amber),
        ),
        child: Text(
          item.entregado ? 'Entregado' : 'Pendiente',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: item.entregado ? AppTheme.ok : Colors.amber,
          ),
        ),
      ),
    ),
  ),
),
          SizedBox(
  width: 80,
  child: Align(
    alignment: Alignment.center,
    child: PopupMenuButton<String>(
      tooltip: 'Opciones',
      color: AppTheme.panel,
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'images') onImages();
        if (value == 'pay') onPay();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18),
              SizedBox(width: 10),
              Text('Editar'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'images',
          child: Row(
            children: [
              Icon(Icons.image_rounded, size: 18),
              SizedBox(width: 10),
              Text('Imágenes'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'pay',
          child: Row(
            children: [
              Icon(Icons.payments_rounded, size: 18),
              SizedBox(width: 10),
              Text('Abonar'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, size: 18, color: AppTheme.danger),
              SizedBox(width: 10),
              Text('Eliminar'),
            ],
          ),
        ),
      ],
    ),
  ),
),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon, size: 17, color: color),
      style: IconButton.styleFrom(
        minimumSize: const Size(34, 34),
        maximumSize: const Size(34, 34),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  final String label;
  final String value;
  final bool danger;

  const _MoneyLine({
    required this.label,
    required this.value,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: danger ? AppTheme.accent : AppTheme.text,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileOrderCard extends StatelessWidget {
  final int index;
  final OrderItem item;
  final VoidCallback onEdit;
  final VoidCallback onImages;
  final VoidCallback onPay;
  final VoidCallback onDelete;

  const _MobileOrderCard({
    required this.index,
    required this.item,
    required this.onEdit,
    required this.onImages,
    required this.onPay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final version = item.version.trim().isEmpty ? 'FAN' : item.version.trim();
    final talla = item.talla.trim().isEmpty ? 'L' : item.talla.trim();
    final cantidad = item.cantidad <= 0 ? 1 : item.cantidad;
    final cliente = item.clienteNombre.trim().isEmpty ? 'Sin cliente' : item.clienteNombre.trim();
    final nombre = item.nombreNumero.trim().isEmpty ? 'Sin nombre' : item.nombreNumero.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('# $index', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          ),
          const SizedBox(height: 12),
          SmartNetworkImage(
            url: item.imgPrincipalUrl,
            width: 140,
            height: 105,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _MobilePill(label: 'Versión', value: version, wide: false),
              _MobilePill(label: 'Talla', value: talla, wide: false),
              _MobilePill(label: 'Nombre + N°', value: nombre, wide: true),
              _MobilePill(label: 'Cant', value: '$cantidad', wide: false),
            ],
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Parches', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: _Patches(urls: item.imgsParchesUrl),
          ),
          const SizedBox(height: 14),
          _MobilePill(label: 'Cliente', value: cliente, wide: true),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _MiniBox(title: 'Pagado', value: Formatters.money(item.pagado))),
              const SizedBox(width: 8),
              Expanded(child: _MiniBox(title: 'Total', value: Formatters.money(item.totalVenta))),
              const SizedBox(width: 8),
              Expanded(child: _MiniBox(title: 'Debe', value: Formatters.money(item.debe), danger: item.debe > 0)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPay,
                  icon: const Icon(Icons.payments_rounded, size: 18),
                  label: const Text('Abonar'),
                ),
              ),
              const SizedBox(width: 8),
              _RoundMobileButton(icon: Icons.edit_rounded, onPressed: onEdit),
              const SizedBox(width: 8),
              _RoundMobileButton(icon: Icons.image_rounded, onPressed: onImages),
              const SizedBox(width: 8),
              _RoundMobileButton(icon: Icons.delete_rounded, color: AppTheme.danger, onPressed: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobilePill extends StatelessWidget {
  final String label;
  final String value;
  final bool wide;

  const _MobilePill({
    required this.label,
    required this.value,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? 210 : null,
      constraints: BoxConstraints(
        minHeight: 42,
        maxWidth: wide ? 240 : 170,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.panel2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.visible,
              softWrap: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundMobileButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onPressed;

  const _RoundMobileButton({
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      style: IconButton.styleFrom(
        minimumSize: const Size(46, 46),
        maximumSize: const Size(46, 46),
      ),
    );
  }
}

class _MiniBox extends StatelessWidget {
  final String title;
  final String value;
  final bool danger;

  const _MiniBox({
    required this.title,
    required this.value,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.panel2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: danger ? AppTheme.accent : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: danger ? AppTheme.accent : AppTheme.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _Patches extends StatelessWidget {
  final List<String> urls;

  const _Patches({required this.urls});

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return const Text('Sin parches', style: TextStyle(color: AppTheme.muted, fontSize: 13));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: urls.take(5).map((x) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.panel2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          padding: const EdgeInsets.all(4),
          child: SmartNetworkImage(
            url: x,
            width: 46,
            height: 46,
            fit: BoxFit.contain,
          ),
        );
      }).toList(),
    );
  }
}

class _OrderItemDialog extends StatefulWidget {
  final OrderItem? item;
final String? pedidoId;

const _OrderItemDialog({
  this.item,
  this.pedidoId,
});

  @override
  State<_OrderItemDialog> createState() => _OrderItemDialogState();
}

class _OrderItemDialogState extends State<_OrderItemDialog> {
  final formKey = GlobalKey<FormState>();
  final cliente = TextEditingController();
  final clienteFocus = FocusNode();
List<Customer> clientes = [];
bool cargandoClientes = true;
  final nombre = TextEditingController();
final numero = TextEditingController();
  final cantidad = TextEditingController(text: '1');
  final precio = TextEditingController(text: '0');
  final pagado = TextEditingController(text: '0');
  String version = 'FAN';
  String talla = 'S';
  XFile? mainImage;
  final List<XFile> patches = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    cargarClientes();

    final item = widget.item;
    if (item != null) {
      cliente.text = item.clienteNombre;
      final texto = item.nombreNumero.trim();
final partes = texto.split(RegExp(r'\s+'));
final numeroDetectado = partes.where((x) => RegExp(r'\d').hasMatch(x)).join(' ');
final nombreDetectado = numeroDetectado.isEmpty ? texto : texto.replaceAll(numeroDetectado, '').trim();

nombre.text = nombreDetectado;
numero.text = numeroDetectado;
      cantidad.text = item.cantidad.toString();
      precio.text = item.precioUnit.toString();
      pagado.text = item.pagado.toString();
      version = item.version.isEmpty ? 'FAN' : item.version;
      talla = item.talla.isEmpty ? 'S' : item.talla;
    }
  }

  Future<void> cargarClientes() async {
  final list = await CustomerRepository().streamCustomers().first;

  if (!mounted) return;

  setState(() {
    clientes = list.where((x) => x.activo).toList();
    cargandoClientes = false;
  });
}

  @override
  void dispose() {
    cliente.dispose();
    clienteFocus.dispose();
    nombre.dispose();
numero.dispose();
    cantidad.dispose();
    precio.dispose();
    pagado.dispose();
    super.dispose();
  }

  Future<void> pickMain() async {
  final img = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1200,
    maxHeight: 1200,
    imageQuality: 72,
  );

  if (img != null) setState(() => mainImage = img);
}

Future<void> pickPatch() async {
  final imgs = await ImagePicker().pickMultiImage(
    maxWidth: 1200,
    maxHeight: 1200,
    imageQuality: 72,
  );

  if (imgs.isNotEmpty) setState(() => patches.addAll(imgs));
}

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final item = widget.item;

      if (item == null) {
        final storage = StorageService();
        String mainUrl = '';

        if (mainImage != null) {
          mainUrl = await storage.uploadXFile(mainImage!, 'pedidos/principal');
        }

        final patchUrls = <String>[];

        for (final p in patches) {
          patchUrls.add(await storage.uploadXFile(p, 'pedidos/parches'));
        }

        await OrderRepository().addItem(
          clienteNombre: cliente.text.trim(),
          version: version,
          talla: talla,
          nombreNumero: '${nombre.text.trim()} ${numero.text.trim()}'.trim(),
          cantidad: int.tryParse(cantidad.text.trim()) ?? 1,
          precioUnit: double.tryParse(precio.text.trim()) ?? 0,
          pagado: double.tryParse(pagado.text.trim()) ?? 0,
          imgPrincipalUrl: mainUrl,
          imgsParchesUrl: patchUrls,
          pedidoId: widget.pedidoId,
        );
      } else {
        await OrderRepository().updateItemText(
          item: item,
          clienteNombre: cliente.text.trim(),
          version: version,
          talla: talla,
          nombreNumero: '${nombre.text.trim()} ${numero.text.trim()}'.trim(),
          cantidad: int.tryParse(cantidad.text.trim()) ?? 1,
          precioUnit: double.tryParse(precio.text.trim()) ?? 0,
        );
      }

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.panel,
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      widget.item == null ? 'Agregar camisa' : 'Editar camisa',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _FieldBox(
  width: 360,
  child: RawAutocomplete<Customer>(
    textEditingController: cliente,
    focusNode: clienteFocus,
    displayStringForOption: (c) => c.nombre,
    optionsBuilder: (value) {
      final q = value.text.trim().toLowerCase();

      if (q.isEmpty) {
        return clientes.take(8);
      }

      return clientes.where((c) {
        final text = '${c.nombre} ${c.telefono}'.toLowerCase();
        return text.contains(q);
      }).take(8);
    },
    onSelected: (c) {
      cliente.text = c.nombre;
    },
    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
      return TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: 'Cliente',
          hintText: cargandoClientes ? 'Cargando clientes...' : 'Buscar o escribir cliente',
          prefixIcon: const Icon(Icons.search_rounded),
        ),
        validator: _required,
      );
    },
    optionsViewBuilder: (context, onSelected, options) {
      return Align(
        alignment: Alignment.topLeft,
        child: Material(
          color: AppTheme.panel,
          elevation: 10,
          borderRadius: BorderRadius.circular(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 360,
              maxHeight: 260,
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
              itemBuilder: (context, index) {
                final c = options.elementAt(index);

                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.person_rounded),
                  title: Text(
                    c.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    c.telefono.isEmpty ? 'Sin teléfono' : c.telefono,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => onSelected(c),
                );
              },
            ),
          ),
        ),
      );
    },
  ),
),
                    _FieldBox(
  width: 260,
  child: TextFormField(
    controller: nombre,
    decoration: const InputDecoration(labelText: 'Nombre'),
  ),
),
_FieldBox(
  width: 160,
  child: TextFormField(
    controller: numero,
    decoration: const InputDecoration(labelText: 'Número'),
  ),
),
                    _FieldBox(width: 170, child: _Select(value: version, label: 'Versión', values: const ['FAN', 'PLAYER', 'RETRO', 'KID', 'WOMAN', 'CRÉDITO'], onChanged: (v) => setState(() => version = v))),
                    _FieldBox(width: 170, child: _Select(value: talla, label: 'Talla', values: const ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL', '4XL', '16', '18', '20', '22', '24', '26', '28'], onChanged: (v) => setState(() => talla = v))),
                    _FieldBox(width: 170, child: TextFormField(controller: cantidad, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cantidad'), validator: _required)),
                    _FieldBox(width: 170, child: TextFormField(controller: precio, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio unitario'), validator: _required)),
                    _FieldBox(width: 170, child: TextFormField(controller: pagado, enabled: widget.item == null, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pagado'), validator: _required)),
                  ],
                ),
                if (widget.item == null) ...[
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: pickMain,
                        icon: const Icon(Icons.image_rounded),
                        label: Text(mainImage == null ? 'Imagen principal' : mainImage!.name),
                      ),
                      OutlinedButton.icon(
                        onPressed: pickPatch,
                        icon: const Icon(Icons.add_photo_alternate_rounded),
                        label: Text('Parches (${patches.length})'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading ? null : save,
                    child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String? _required(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Requerido';
    return null;
  }
}

class _Select extends StatelessWidget {
  final String value;
  final String label;
  final List<String> values;
  final ValueChanged<String> onChanged;

  const _Select({
    required this.value,
    required this.label,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = values.contains(value) ? value : values.first;

    return DropdownButtonFormField<String>(
      value: safeValue,
      decoration: InputDecoration(labelText: label),
      items: values.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
      onChanged: (v) => onChanged(v ?? safeValue),
    );
  }
}

class _ImagesDialog extends StatefulWidget {
  final OrderItem item;

  const _ImagesDialog({required this.item});

  @override
  State<_ImagesDialog> createState() => _ImagesDialogState();
}

class _ImagesDialogState extends State<_ImagesDialog> {
  XFile? mainImage;
  final List<XFile> newPatches = [];
  late List<String> currentPatches;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    currentPatches = List<String>.from(widget.item.imgsParchesUrl);
  }

  Future<void> pickMain() async {
  final img = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1200,
    maxHeight: 1200,
    imageQuality: 72,
  );

  if (img == null) return;

  setState(() => mainImage = img);
}

Future<void> pickPatch() async {
  final imgs = await ImagePicker().pickMultiImage(
    maxWidth: 1200,
    maxHeight: 1200,
    imageQuality: 72,
  );

  if (imgs.isEmpty) return;

  setState(() => newPatches.addAll(imgs));
}

 void removeCurrentPatchAt(int index) {
  if (index < 0 || index >= currentPatches.length) return;

  setState(() {
    currentPatches.removeAt(index);
  });
}

void removeNewPatchAt(int index) {
  if (index < 0 || index >= newPatches.length) return;

  setState(() {
    newPatches.removeAt(index);
  });
}

  Future<void> save() async {
  if (loading) return;

  setState(() => loading = true);

  try {
    final storage = StorageService();

    final mainFuture = mainImage == null
        ? Future.value(widget.item.imgPrincipalUrl)
        : storage.uploadXFile(mainImage!, 'pedidos/principal');

    final patchesFuture = Future.wait(
      newPatches.map((p) => storage.uploadXFile(p, 'pedidos/parches')),
    );

    final result = await Future.wait([
      mainFuture,
      patchesFuture,
    ]);

    final mainUrl = result[0] as String;
    final uploadedPatches = result[1] as List<String>;

    final patchUrls = <String>[
      ...currentPatches.where((x) => x.trim().isNotEmpty),
      ...uploadedPatches.where((x) => x.trim().isNotEmpty),
    ];

    await OrderRepository().updateItemImages(
      item: widget.item,
      imgPrincipalUrl: mainUrl,
      imgsParchesUrl: patchUrls,
    );

    if (!mounted) return;

    Navigator.pop(context);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se pudieron guardar las imágenes: $e')),
    );
  } finally {
    if (mounted) setState(() => loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final previewMain = mainImage;

    return AlertDialog(
      backgroundColor: AppTheme.panel,
      title: const Text('Editar imágenes'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: 220,
                height: 160,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.panel2,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.border),
                ),
                child: previewMain == null
                    ? SmartNetworkImage(
                        url: widget.item.imgPrincipalUrl,
                        width: 200,
                        height: 140,
                        fit: BoxFit.contain,
                      )
                    : Image.network(
                        previewMain.path,
                        width: 200,
                        height: 140,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) {
                          return const Center(
                            child: Icon(Icons.image_rounded, size: 42),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: loading ? null : pickMain,
                icon: const Icon(Icons.image_rounded),
                label: Text(mainImage == null ? 'Cambiar imagen principal' : mainImage!.name),
              ),
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Parches registrados',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 10),
              if (currentPatches.isEmpty)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Sin parches registrados', style: TextStyle(color: AppTheme.muted)),
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: currentPatches.asMap().entries.map((entry) {
  final index = entry.key;
  final url = entry.value;

  return Stack(
    key: ValueKey('current_patch_${index}_$url'),
    clipBehavior: Clip.none,
    children: [
      Container(
        width: 86,
        height: 86,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppTheme.panel2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: SmartNetworkImage(
          key: ValueKey(url),
          url: url,
          width: 76,
          height: 76,
          fit: BoxFit.contain,
        ),
      ),
      Positioned(
        right: -7,
        top: -7,
        child: InkWell(
          onTap: loading ? null : () => removeCurrentPatchAt(index),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.danger,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(5),
            child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
          ),
        ),
      ),
    ],
  );
}).toList(),
                  ),
                ),
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Parches nuevos',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 10),
              if (newPatches.isEmpty)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('No has agregado nuevos parches', style: TextStyle(color: AppTheme.muted)),
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: newPatches.asMap().entries.map((entry) {
  final index = entry.key;
  final file = entry.value;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 86,
                            height: 86,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppTheme.panel2,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Image.network(
                              file.path,
                              width: 76,
                              height: 76,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) {
                                return const Center(
                                  child: Icon(Icons.image_rounded, size: 32),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            right: -7,
                            top: -7,
                            child: InkWell(
                              onTap: loading ? null : () => removeNewPatchAt(index),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: AppTheme.danger,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(5),
                                child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: loading ? null : pickPatch,
                icon: const Icon(Icons.add_photo_alternate_rounded),
                label: Text('Agregar parches (${newPatches.length})'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: loading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: loading ? null : save,
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

class _PayDialog extends StatefulWidget {
  final OrderItem item;

  const _PayDialog({required this.item});

  @override
  State<_PayDialog> createState() => _PayDialogState();
}

class _PayDialogState extends State<_PayDialog> {
  final monto = TextEditingController();

  @override
  void dispose() {
    monto.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final value = double.tryParse(monto.text.trim()) ?? 0;
    if (value <= 0) return;
    await OrderRepository().updatePayment(widget.item, value);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.panel,
      title: const Text('Registrar abono'),
      content: TextField(
        controller: monto,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: 'Monto', hintText: Formatters.money(widget.item.debe)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: save, child: const Text('Guardar')),
      ],
    );
  }
}

class _HistoryDialog extends StatefulWidget {
  const _HistoryDialog();

  @override
  State<_HistoryDialog> createState() => _HistoryDialogState();
}

class _HistoryDialogState extends State<_HistoryDialog> {
  DateTime desde = DateTime.now().subtract(const Duration(days: 30));
  DateTime hasta = DateTime.now();
  bool soloCerrados = false;
  late Future<dynamic> future;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<dynamic> load() {
    return OrderRepository().getHistory(
      desde: desde,
      hasta: hasta,
      soloCerrados: soloCerrados,
    );
  }

 void buscar() {
  FocusScope.of(context).unfocus();
  setState(() {
    future = load();
  });
}

  Future<void> pickDesde() async {
  final d = await showDatePicker(
    context: context,
    initialDate: desde,
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
    locale: const Locale('es', 'ES'),
  );

  if (d != null && d != desde) {
    setState(() {
      desde = d;
    });
  }
}

Future<void> pickHasta() async {
  final d = await showDatePicker(
    context: context,
    initialDate: hasta,
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
    locale: const Locale('es', 'ES'),
  );

  if (d != null && d != hasta) {
    setState(() {
      hasta = d;
    });
  }
}

  String fmt(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String fmtDate(dynamic value) {
  final d = value is DateTime ? value : value?.toDate();
  if (d is! DateTime) return '—';
  return '${fmt(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.panel,
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('Historial de pedidos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: pickDesde,
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: Text('Desde ${fmt(desde)}'),
                  ),
                  OutlinedButton.icon(
                    onPressed: pickHasta,
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: Text('Hasta ${fmt(hasta)}'),
                  ),
                  FilterChip(
                    label: const Text('Solo cerrados'),
                    selected: soloCerrados,
                    onSelected: (v) => setState(() => soloCerrados = v),
                  ),
                  FilledButton.icon(
                    onPressed: buscar,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Buscar'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
  child: FutureBuilder(
    future: future,
    builder: (context, snap) {
      final docs = snap.data ?? [];
      final isMobile = MediaQuery.of(context).size.width < 650;

      if (snap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (docs.isEmpty) {
        return const Center(child: Text('No hay pedidos en ese rango.'));
      }

      if (isMobile) {
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final d = docs[i];
            final x = d.data();
            final shortId = d.id.substring(0, d.id.length > 8 ? 8 : d.id.length).toUpperCase();
            final estado = (x['estado'] ?? '').toString().toUpperCase();
            final total = double.tryParse((x['totalVenta'] ?? 0).toString()) ?? 0;
            final camisas = (x['camisasCount'] ?? 0).toString();

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.panel2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        shortId,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          estado,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: AppTheme.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Apertura: ${fmtDate(x['creadoEn'])}',
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                  Text(
                    'Cierre: ${fmtDate(x['cerradoEn'])}',
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _MiniBox(title: 'Camisas', value: camisas)),
                      const SizedBox(width: 8),
                      Expanded(child: _MiniBox(title: 'Total', value: Formatters.money(total))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, d.id),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Abrir pedido'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 860,
          child: SingleChildScrollView(
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(120),
                1: FixedColumnWidth(280),
                2: FixedColumnWidth(120),
                3: FixedColumnWidth(90),
                4: FixedColumnWidth(130),
                5: FixedColumnWidth(120),
              },
              border: const TableBorder(
                horizontalInside: BorderSide(color: AppTheme.border),
              ),
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: AppTheme.panel2),
                  children: [
                    _HistoryCell('ID', header: true),
                    _HistoryCell('Apertura / Cierre', header: true),
                    _HistoryCell('Estado', header: true),
                    _HistoryCell('Camisas', header: true),
                    _HistoryCell('Total', header: true),
                    _HistoryCell('Acciones', header: true),
                  ],
                ),
                ...docs.map((d) {
                  final x = d.data();
                  final shortId = d.id.substring(0, d.id.length > 8 ? 8 : d.id.length).toUpperCase();
                  final estado = (x['estado'] ?? '').toString().toUpperCase();
                  final total = double.tryParse((x['totalVenta'] ?? 0).toString()) ?? 0;
                  final camisas = (x['camisasCount'] ?? 0).toString();

                  return TableRow(
                    children: [
                      _HistoryCell(shortId),
                      _HistoryCell(
                        'Apertura: ${fmtDate(x['creadoEn'])}\nCierre: ${fmtDate(x['cerradoEn'])}',
                      ),
                      _HistoryCell(estado),
                      _HistoryCell(camisas),
                      _HistoryCell(Formatters.money(total)),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, d.id),
                          child: const Text('Abrir'),
                        ),
                      ),
                    ],
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
  ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCell extends StatelessWidget {
  final String text;
  final bool header;

  const _HistoryCell(this.text, {this.header = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: header ? FontWeight.w900 : FontWeight.w600,
          color: header ? AppTheme.text : null,
        ),
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  final double width;
  final Widget child;

  const _FieldBox({
    required this.width,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.checkroom_rounded, size: 54, color: AppTheme.muted),
          SizedBox(height: 12),
          Text('No hay camisas en el pedido activo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          SizedBox(height: 4),
          Text('Agregá la primera camisa para iniciar el pedido.', style: TextStyle(color: AppTheme.muted)),
        ],
      ),
    );
  }
}