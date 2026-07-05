import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_item.dart';
import '../../repositories/order_repository.dart';
import '../../widgets/page_frame.dart';

class CxcScreen extends StatefulWidget {
  const CxcScreen({super.key});

  @override
  State<CxcScreen> createState() => _CxcScreenState();
}

class _CxcScreenState extends State<CxcScreen> {
  final repo = OrderRepository();
  String filtro = 'pendientes';
  String search = '';

 Future<void> eliminarCredito(OrderItem item) async {
    if (!item.manual) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.panel,
        title: const Text('Eliminar crédito'),
        content: Text('¿Eliminar el crédito de ${item.clienteNombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repo.deleteItem(item);
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Crédito eliminado')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> pay(OrderItem item) async {
    await showDialog(
      context: context,
      builder: (_) => _CxcPayDialog(item: item),
    );
  }

  Future<void> nuevoCredito() async {
    await showDialog(
      context: context,
      builder: (_) => const _ManualCreditDialog(),
    );
  }

  Future<void> historialGeneral() async {
    await showDialog(
      context: context,
      builder: (_) => const _PaymentsHistoryDialog(),
    );
  }

  Future<void> historialCredito(OrderItem item) async {
    await showDialog(
      context: context,
      builder: (_) => _PaymentsHistoryDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width < 760;

    return PageFrame(
      title: 'Cobranzas',
      subtitle: 'Control de saldos pendientes, pagos y créditos.',
      actions: [
        OutlinedButton.icon(
          onPressed: historialGeneral,
          icon: const Icon(Icons.history_rounded),
          label: const Text('Historial pagos'),
        ),
        FilledButton.icon(
          onPressed: nuevoCredito,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nuevo crédito'),
        ),
      ],
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: mobile ? double.infinity : 230,
                child: DropdownButtonFormField<String>(
                  value: filtro,
                  decoration: const InputDecoration(labelText: 'Filtro'),
                  items: const [
                    DropdownMenuItem(value: 'pendientes', child: Text('Pendientes')),
                    DropdownMenuItem(value: 'saldadas', child: Text('Saldadas')),
                    DropdownMenuItem(value: 'todas', child: Text('Todas')),
                  ],
                  onChanged: (v) => setState(() => filtro = v ?? filtro),
                ),
              ),
              SizedBox(
                width: mobile ? double.infinity : 420,
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    labelText: 'Buscar cliente',
                  ),
                  onChanged: (v) => setState(() => search = v.trim().toLowerCase()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<OrderItem>>(
            stream: repo.streamAllItems(),
            builder: (context, snapPedidos) {
              return StreamBuilder<List<OrderItem>>(
                stream: repo.streamCxcItems(),
                builder: (context, snapCreditos) {
                  var items = <OrderItem>[
                    ...(snapPedidos.data ?? <OrderItem>[]),
                    ...(snapCreditos.data ?? <OrderItem>[]),
                  ];
              items = items.where((x) {
                final q = '${x.clienteNombre} ${x.nombreNumero} ${x.version}'.toLowerCase();
                final okSearch = q.contains(search);
                final okFiltro = filtro == 'todas' || (filtro == 'pendientes' && x.debe > 0) || (filtro == 'saldadas' && x.debe <= 0);
                return okSearch && okFiltro;
              }).toList();

              final pendiente = items.fold<double>(0, (a, b) => a + b.debe);

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accent.withOpacity(.95),
                          AppTheme.accent2.withOpacity(.75),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saldo pendiente', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.money(pendiente),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (mobile)
                    Column(
                      children: items.map((x) {
                        return _CxcMobileCard(
                          item: x,
                          onPay: () => pay(x),
                          onHistory: () => historialCredito(x),
                          onDelete: () => eliminarCredito(x),
                        );
                      }).toList(),
                    )
                  else
                   _CxcTable(
                      items: items,
                      onPay: pay,
                      onHistory: historialCredito,
                      onDelete: eliminarCredito,
                    ),
                ],
              );
          },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CxcTable extends StatelessWidget {
  final List<OrderItem> items;
  final void Function(OrderItem item) onPay;
  final void Function(OrderItem item) onHistory;
  final void Function(OrderItem item) onDelete;

  const _CxcTable({
    required this.items,
    required this.onPay,
    required this.onHistory,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1120),
          child: Column(
            children: [
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.border)),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 180, child: Text('Cliente', style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w900))),
                    SizedBox(width: 330, child: Text('Detalle', style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w900))),
                    SizedBox(width: 120, child: Text('Total', style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w900))),
                    SizedBox(width: 120, child: Text('Pagado', style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w900))),
                    SizedBox(width: 120, child: Text('Debe', style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w900))),
                    SizedBox(width: 250, child: Text('Acciones', style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w900))),
                  ],
                ),
              ),
              ...items.map((x) {
                return ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 66),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppTheme.border)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 180,
                          child: Text(
                            x.clienteNombre,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: 330,
                          child: Text(
                            '${x.version} ${x.talla} ${x.nombreNumero}'.trim(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 120, child: Text(Formatters.money(x.totalVenta))),
                        SizedBox(width: 120, child: Text(Formatters.money(x.pagado))),
                        SizedBox(
                          width: 120,
                          child: Text(
                            Formatters.money(x.debe),
                            style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w900),
                          ),
                        ),
                        SizedBox(
                          width: 250,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton(
                                onPressed: x.debe <= 0 ? null : () => onPay(x),
                                child: const Text('Cobrar'),
                              ),
                              OutlinedButton(
                                onPressed: () => onHistory(x),
                                child: const Text('Historial'),
                              ),
                              if (x.manual)
                                OutlinedButton(
                                  onPressed: () => onDelete(x),
                                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger),
                                  child: const Text('Eliminar'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _CxcMobileCard extends StatelessWidget {
  final OrderItem item;
  final VoidCallback onPay;
  final VoidCallback onHistory;
  final VoidCallback onDelete;

  const _CxcMobileCard({
    required this.item,
    required this.onPay,
    required this.onHistory,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.clienteNombre, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 4),
          Text('${item.version} ${item.talla} ${item.nombreNumero}'.trim(), style: const TextStyle(color: AppTheme.muted)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MiniBox(title: 'Total', value: Formatters.money(item.totalVenta))),
              const SizedBox(width: 8),
              Expanded(child: _MiniBox(title: 'Pagado', value: Formatters.money(item.pagado))),
            ],
          ),
          const SizedBox(height: 8),
          _MiniBox(title: 'Debe', value: Formatters.money(item.debe)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: item.debe <= 0 ? null : onPay,
                icon: const Icon(Icons.payments_rounded),
                label: const Text('Cobrar'),
              ),
              OutlinedButton.icon(
                onPressed: onHistory,
                icon: const Icon(Icons.history_rounded),
                label: const Text('Historial'),
              ),
              if (item.manual)
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_rounded, color: AppTheme.danger),
                  label: const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBox extends StatelessWidget {
  final String title;
  final String value;

  const _MiniBox({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.panel2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ManualCreditDialog extends StatefulWidget {
  const _ManualCreditDialog();

  @override
  State<_ManualCreditDialog> createState() => _ManualCreditDialogState();
}

class _ManualCreditDialogState extends State<_ManualCreditDialog> {
  final cliente = TextEditingController();
  final detalle = TextEditingController();
  final monto = TextEditingController();
  bool loading = false;
  String error = '';

  @override
  void dispose() {
    cliente.dispose();
    detalle.dispose();
    monto.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (loading) return;

    final total = double.tryParse(monto.text.trim()) ?? 0;

    if (cliente.text.trim().isEmpty || detalle.text.trim().isEmpty || total <= 0) {
      setState(() => error = 'Complete cliente, detalle y monto válido.');
      return;
    }

    setState(() {
      loading = true;
      error = '';
    });

    try {
      await OrderRepository().addManualCredit(
        clienteNombre: cliente.text.trim(),
        detalle: detalle.text.trim(),
        total: total,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.panel,
      title: const Text('Nuevo crédito'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: cliente, decoration: const InputDecoration(labelText: 'Cliente')),
            const SizedBox(height: 12),
            TextField(controller: monto, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto')),
            const SizedBox(height: 12),
            TextField(controller: detalle, maxLines: 3, decoration: const InputDecoration(labelText: 'Detalle')),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(error, style: const TextStyle(color: AppTheme.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: loading ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: loading ? null : save,
          child: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'),
        ),
      ],
    );
  }
}

class _CxcPayDialog extends StatefulWidget {
  final OrderItem item;

  const _CxcPayDialog({required this.item});

  @override
  State<_CxcPayDialog> createState() => _CxcPayDialogState();
}

class _CxcPayDialogState extends State<_CxcPayDialog> {
  final monto = TextEditingController();
  final nota = TextEditingController();
  String metodo = 'Efectivo';
  bool loading = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    monto.text = widget.item.debe.toStringAsFixed(0);
  }

  @override
  void dispose() {
    monto.dispose();
    nota.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (loading) return;

    final value = double.tryParse(monto.text.trim()) ?? 0;

    if (value <= 0) {
      setState(() => error = 'Ingrese un monto válido.');
      return;
    }

    setState(() {
      loading = true;
      error = '';
    });

   try {
      await OrderRepository().updatePayment(
        widget.item,
        value,
        metodo: metodo,
        nota: nota.text.trim(),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.panel,
      title: const Text('Registrar pago'),
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text('${widget.item.clienteNombre} — Debe: ${Formatters.money(widget.item.debe)}'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: monto,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Monto'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: metodo,
                    decoration: const InputDecoration(labelText: 'Método'),
                    items: const [
                      DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                      DropdownMenuItem(value: 'Transferencia', child: Text('Transferencia')),
                      DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta')),
                    ],
                    onChanged: (v) => setState(() => metodo = v ?? metodo),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nota,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Nota'),
            ),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(error, style: const TextStyle(color: AppTheme.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: loading ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: loading ? null : save,
          child: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'),
        ),
      ],
    );
  }
}

class _PaymentsHistoryDialog extends StatelessWidget {
  final OrderItem? item;

  const _PaymentsHistoryDialog({this.item});

  @override
  Widget build(BuildContext context) {
    final query = item == null
        ? FirebaseFirestore.instance.collection('pagos')
        : FirebaseFirestore.instance.collection('pagos').where('camisaId', isEqualTo: item!.id);

    return AlertDialog(
      backgroundColor: AppTheme.panel,
      title: Text(item == null ? 'Historial de pagos' : 'Historial de ${item!.clienteNombre}'),
      content: SizedBox(
        width: 700,
        height: 430,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: query.snapshots(),
          builder: (context, snap) {
            final docs = [...(snap.data?.docs ?? [])];

docs.sort((a, b) {
  final af = a.data()['fecha'];
  final bf = b.data()['fecha'];
  final ad = af is Timestamp ? af.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
  final bd = bf is Timestamp ? bf.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
  return bd.compareTo(ad);
});

            if (docs.isEmpty) {
              return const Center(child: Text('No hay pagos registrados.'));
            }

            return ListView(
              children: docs.map((d) {
                final x = d.data();
                final monto = double.tryParse((x['monto'] ?? 0).toString()) ?? 0;
                final metodo = (x['metodo'] ?? 'N/A').toString();
                final nota = (x['nota'] ?? '').toString();
                final fechaRaw = x['fecha'];
final fecha = fechaRaw is Timestamp ? Formatters.dateTime(fechaRaw.toDate()) : 'Sin fecha';

                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.payments_rounded)),
                  title: Text((x['clienteNombre'] ?? '').toString()),
                  subtitle: Text('Fecha: $fecha\nMétodo: $metodo${nota.isEmpty ? '' : ' • $nota'}'),
                  trailing: Text(Formatters.money(monto), style: const TextStyle(fontWeight: FontWeight.w900)),
                );
              }).toList(),
            );
          },
        ),
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
      ],
    );
  }
}