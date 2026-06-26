import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/customer.dart';
import '../../repositories/customer_repository.dart';
import '../../widgets/page_frame.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final repo = CustomerRepository();
  String search = '';

  Future<void> openForm([Customer? customer]) async {
    await showDialog(
      context: context,
      builder: (_) => _CustomerDialog(customer: customer),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Clientes',
      subtitle: 'Registro rápido de clientes para pedidos y cobranzas.',
      actions: [
        FilledButton.icon(onPressed: () => openForm(), icon: const Icon(Icons.add_rounded), label: const Text('Nuevo cliente')),
      ],
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), labelText: 'Buscar cliente'),
            onChanged: (v) => setState(() => search = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Customer>>(
            stream: repo.streamCustomers(),
            builder: (context, snap) {
              final list = (snap.data ?? []).where((x) {
                final q = '${x.nombre} ${x.telefono}'.toLowerCase();
                return q.contains(search);
              }).toList();

              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.panel,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    const _Header(),
                    ...list.map((c) {
                      return ListTile(
                        title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text(c.telefono.isEmpty ? 'Sin teléfono' : c.telefono),
                        trailing: Wrap(
                          children: [
                            IconButton(onPressed: () => openForm(c), icon: const Icon(Icons.edit_rounded)),
                            IconButton(onPressed: () => repo.deleteCustomer(c.id), icon: const Icon(Icons.delete_rounded, color: AppTheme.danger)),
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: const Row(
        children: [
          Expanded(child: Text('Nombre', style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w900))),
          Expanded(child: Text('Teléfono', style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w900))),
          SizedBox(width: 110, child: Text('Acciones', style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

class _CustomerDialog extends StatefulWidget {
  final Customer? customer;

  const _CustomerDialog({this.customer});

  @override
  State<_CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<_CustomerDialog> {
  final nombre = TextEditingController();
  final telefono = TextEditingController();

  @override
  void initState() {
    super.initState();
    nombre.text = widget.customer?.nombre ?? '';
    telefono.text = widget.customer?.telefono ?? '';
  }

  @override
  void dispose() {
    nombre.dispose();
    telefono.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (nombre.text.trim().isEmpty) return;

    await CustomerRepository().saveCustomer(
      Customer(
        id: widget.customer?.id ?? '',
        nombre: nombre.text.trim(),
        telefono: telefono.text.trim(),
        activo: true,
      ),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.panel,
      title: Text(widget.customer == null ? 'Nuevo cliente' : 'Editar cliente'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombre, decoration: const InputDecoration(labelText: 'Nombre')),
            const SizedBox(height: 12),
            TextField(controller: telefono, decoration: const InputDecoration(labelText: 'Teléfono')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: save, child: const Text('Guardar')),
      ],
    );
  }
}