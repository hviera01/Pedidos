import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/product.dart';
import '../../repositories/product_repository.dart';
import '../../services/storage_service.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/smart_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final repo = ProductRepository();
  String search = '';
  String filter = 'conStock';

  Future<void> openForm([Product? product]) async {
    await showDialog(
      context: context,
      builder: (_) => _ProductDialog(product: product),
    );
  }

  Future<void> openStock(Product product) async {
    await showDialog(
      context: context,
      builder: (_) => _StockDialog(product: product),
    );
  }

  Future<void> openHistory(Product product) async {
  await showDialog(
    context: context,
    builder: (_) => _ProductHistoryDialog(product: product),
  );
}

  Future<void> removeProduct(Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppTheme.panel,
          title: const Text('Eliminar producto'),
          content: Text('¿Eliminar ${product.descripcion}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
          ],
        );
      },
    );

    if (ok == true) {
      await repo.deleteProduct(product.id);
    }
  }

  @override
Widget build(BuildContext context) {
  final mobile = MediaQuery.of(context).size.width < 760;

  return PageFrame(
    title: 'Inventario',
    subtitle: 'Productos, imágenes, precios, existencias y ajustes de stock.',
    actions: mobile
        ? []
        : [
            FilledButton.icon(
              onPressed: () => openForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuevo producto'),
            ),
          ],
    child: StreamBuilder<List<Product>>(
      stream: repo.streamProducts(),
      builder: (context, snap) {
        var list = snap.data ?? [];

        list = list.where((x) {
          final q = '${x.codigo} ${x.descripcion}'.toLowerCase();
          final matchText = q.contains(search);
          final matchStock = filter == 'todos' || (filter == 'conStock' && x.stock > 0) || (filter == 'sinStock' && x.stock <= 0);
          return matchText && matchStock;
        }).toList();

        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (mobile) {
          return SizedBox(
            height: MediaQuery.of(context).size.height - 105,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              cacheExtent: 650,
              itemCount: list.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => openForm(),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Nuevo producto'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search_rounded),
                            labelText: 'Buscar producto',
                          ),
                          onChanged: (v) => setState(() => search = v.trim().toLowerCase()),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: filter,
                          decoration: const InputDecoration(labelText: 'Stock'),
                          items: const [
                            DropdownMenuItem(value: 'conStock', child: Text('Con stock')),
                            DropdownMenuItem(value: 'sinStock', child: Text('Sin stock')),
                            DropdownMenuItem(value: 'todos', child: Text('Todos')),
                          ],
                          onChanged: (v) => setState(() => filter = v ?? filter),
                        ),
                      ],
                    ),
                  );
                }

                final p = list[index - 1];

                return RepaintBoundary(
                  child: _ProductCard(
                    product: p,
                    onEdit: () => openForm(p),
                    onStock: () => openStock(p),
                    onHistory: () => openHistory(p),
                    onDelete: () => removeProduct(p),
                  ),
                );
              },
            ),
          );
        }

        return Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 420,
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      labelText: 'Buscar producto',
                    ),
                    onChanged: (v) => setState(() => search = v.trim().toLowerCase()),
                  ),
                ),
                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<String>(
                    value: filter,
                    decoration: const InputDecoration(labelText: 'Stock'),
                    items: const [
                      DropdownMenuItem(value: 'conStock', child: Text('Con stock')),
                      DropdownMenuItem(value: 'sinStock', child: Text('Sin stock')),
                      DropdownMenuItem(value: 'todos', child: Text('Todos')),
                    ],
                    onChanged: (v) => setState(() => filter = v ?? filter),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = constraints.maxWidth < 1140 ? 1140.0 : constraints.maxWidth;

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
                          const _InventoryHeader(),
                          ...list.map((p) {
                            return _ProductRow(
                              product: p,
                              onEdit: () => openForm(p),
                              onStock: () => openStock(p),
                              onHistory: () => openHistory(p),
                              onDelete: () => removeProduct(p),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    ),
  );
}
}

class _InventoryHeader extends StatelessWidget {
  const _InventoryHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w900, fontSize: 12);

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border))),
      child: const Row(
        children: [
          SizedBox(width: 120, child: Text('Imagen', style: style)),
          SizedBox(width: 150, child: Text('Código', style: style)),
          Expanded(child: Text('Descripción', style: style)),
          SizedBox(width: 90, child: Text('Stock', style: style)),
          SizedBox(width: 120, child: Text('Precio', style: style)),
          SizedBox(width: 220, child: Text('Acciones', style: style)),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onStock;
  final VoidCallback onHistory;
  final VoidCallback onDelete;

  const _ProductRow({
    required this.product,
    required this.onEdit,
    required this.onStock,
    required this.onHistory,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border))),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: SmartNetworkImage(
              url: product.imgUrl,
              width: 92,
              height: 66,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(width: 150, child: Text(product.codigo, overflow: TextOverflow.ellipsis)),
          Expanded(
            child: Text(
              product.descripcion,
              style: const TextStyle(fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          SizedBox(width: 90, child: Text('${product.stock}')),
          SizedBox(width: 120, child: Text(Formatters.money(product.precio))),
          SizedBox(
            width: 220,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded)),
                IconButton(onPressed: onStock, icon: const Icon(Icons.swap_vert_rounded)),
                IconButton(onPressed: onHistory, icon: const Icon(Icons.history_rounded)),
                IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_rounded, color: AppTheme.danger)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onStock;
  final VoidCallback onHistory;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onStock,
    required this.onHistory,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
  width: double.infinity,
  height: 210,
  padding: const EdgeInsets.all(10),
  decoration: BoxDecoration(
    color: AppTheme.panel2,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AppTheme.border),
  ),
  child: SmartNetworkImage(
    url: product.imgUrl,
    width: double.infinity,
    height: 210,
    fit: BoxFit.contain,
  ),
),
          const SizedBox(height: 12),
          Text(product.descripcion, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 6),
          Text(product.codigo, style: const TextStyle(color: AppTheme.muted)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MiniBox(title: 'Stock', value: '${product.stock}')),
              const SizedBox(width: 8),
              Expanded(child: _MiniBox(title: 'Precio', value: Formatters.money(product.precio))),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_rounded), label: const Text('Editar')),
              OutlinedButton.icon(onPressed: onStock, icon: const Icon(Icons.swap_vert_rounded), label: const Text('Stock')),
              OutlinedButton.icon(onPressed: onHistory, icon: const Icon(Icons.history_rounded), label: const Text('Historial')),
              OutlinedButton.icon(onPressed: onDelete, icon: const Icon(Icons.delete_rounded, color: AppTheme.danger), label: const Text('Eliminar')),
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

class _ProductDialog extends StatefulWidget {
  final Product? product;

  const _ProductDialog({this.product});

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final codigo = TextEditingController();
  final descripcion = TextEditingController();
  final precio = TextEditingController();
  final stock = TextEditingController();
  XFile? image;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    codigo.text = p?.codigo ?? '';
    descripcion.text = p?.descripcion ?? '';
    precio.text = p == null ? '0' : p.precio.toString();
    stock.text = p == null ? '0' : p.stock.toString();
  }

  @override
  void dispose() {
    codigo.dispose();
    descripcion.dispose();
    precio.dispose();
    stock.dispose();
    super.dispose();
  }

 Future<void> pickImage() async {
  final selected = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1200,
    maxHeight: 1200,
    imageQuality: 72,
  );

  if (selected != null) {
    setState(() => image = selected);
  }
}

  Future<void> save() async {
    if (loading) return;
    if (descripcion.text.trim().isEmpty) return;

    setState(() => loading = true);

    try {
      var imgUrl = widget.product?.imgUrl ?? '';

      if (image != null) {
        imgUrl = await StorageService().uploadXFile(image!, 'productos');
      }

      await ProductRepository().saveProduct(
        Product(
          id: widget.product?.id ?? '',
          codigo: codigo.text.trim(),
          descripcion: descripcion.text.trim(),
          precio: double.tryParse(precio.text.trim()) ?? 0,
          stock: int.tryParse(stock.text.trim()) ?? 0,
          imgUrl: imgUrl,
          activo: true,
        ),
      );

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.panel,
      title: Text(widget.product == null ? 'Nuevo producto' : 'Editar producto'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: codigo, decoration: const InputDecoration(labelText: 'Código')),
              const SizedBox(height: 12),
              TextField(controller: descripcion, decoration: const InputDecoration(labelText: 'Descripción')),
              const SizedBox(height: 12),
              TextField(controller: precio, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio')),
              const SizedBox(height: 12),
              TextField(controller: stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.image_rounded),
                label: Text(image == null ? 'Seleccionar imagen' : image!.name),
              ),
            ],
          ),
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

class _StockDialog extends StatefulWidget {
  final Product product;

  const _StockDialog({required this.product});

  @override
  State<_StockDialog> createState() => _StockDialogState();
}

class _StockDialogState extends State<_StockDialog> {
  final cantidad = TextEditingController();
  final motivo = TextEditingController(text: 'Ajuste manual');
  String tipo = 'sumar';

  @override
  void dispose() {
    cantidad.dispose();
    motivo.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final value = int.tryParse(cantidad.text.trim()) ?? 0;

    if (value <= 0) {
      return;
    }

    final nuevo = tipo == 'sumar' ? widget.product.stock + value : widget.product.stock - value;

    await ProductRepository().adjustStock(
      product: widget.product,
      newStock: nuevo < 0 ? 0 : nuevo,
      motivo: motivo.text.trim(),
      usuario: 'admin',
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.panel,
      title: const Text('Ajustar stock'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.product.descripcion, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: tipo,
              decoration: const InputDecoration(labelText: 'Movimiento'),
              items: const [
                DropdownMenuItem(value: 'sumar', child: Text('Sumar')),
                DropdownMenuItem(value: 'restar', child: Text('Restar')),
              ],
              onChanged: (v) => setState(() => tipo = v ?? tipo),
            ),
            const SizedBox(height: 12),
            TextField(controller: cantidad, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cantidad')),
            const SizedBox(height: 12),
            TextField(controller: motivo, decoration: const InputDecoration(labelText: 'Motivo')),
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




class _ProductHistoryDialog extends StatelessWidget {
  final Product product;

  const _ProductHistoryDialog({required this.product});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('movimientos_inventario')
        .where('productoId', isEqualTo: product.id);

    return AlertDialog(
      backgroundColor: AppTheme.panel,
      title: Text('Historial de ${product.descripcion}'),
      content: SizedBox(
        width: 760,
        height: 450,
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
              return const Center(child: Text('No hay movimientos registrados.'));
            }

            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(color: AppTheme.border),
              itemBuilder: (context, index) {
                final x = docs[index].data();
                final fechaRaw = x['fecha'];
                final fecha = fechaRaw is Timestamp ? Formatters.dateTime(fechaRaw.toDate()) : 'Sin fecha';
                final tipo = (x['tipo'] ?? 'Movimiento').toString();
                final motivo = (x['motivo'] ?? '').toString();
                final cantidad = int.tryParse((x['cantidad'] ?? 0).toString()) ?? 0;
                final stockAnterior = int.tryParse((x['stockAnterior'] ?? 0).toString()) ?? 0;
                final stockNuevo = int.tryParse((x['stockNuevo'] ?? 0).toString()) ?? 0;

                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(tipo == 'Entrada' ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
                  ),
                  title: Text('$tipo • $cantidad unidades'),
                  subtitle: Text('Fecha: $fecha\nStock: $stockAnterior → $stockNuevo${motivo.isEmpty ? '' : '\nMotivo: $motivo'}'),
                );
              },
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

