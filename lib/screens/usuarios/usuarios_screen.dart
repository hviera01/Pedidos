import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/page_frame.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  Future<void> openForm([String? id, Map<String, dynamic>? data]) async {
    await showDialog(
      context: context,
      builder: (_) => _UserDialog(id: id, data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Usuarios',
      subtitle: 'Accesos por código, roles y estado de usuarios.',
      actions: [
        FilledButton.icon(onPressed: () => openForm(), icon: const Icon(Icons.add_rounded), label: const Text('Nuevo usuario')),
      ],
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];

          return Container(
            decoration: BoxDecoration(
              color: AppTheme.panel,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: docs.map((d) {
                final x = d.data();
                return ListTile(
                  title: Text((x['nombre'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text('Código: ${d.id} • Rol: ${(x['rol'] ?? 'operador').toString()}'),
                  trailing: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(
                        label: Text(x['activo'] == false ? 'Inactivo' : 'Activo'),
                        backgroundColor: x['activo'] == false ? AppTheme.danger.withOpacity(.2) : AppTheme.ok.withOpacity(.2),
                      ),
                      IconButton(onPressed: () => openForm(d.id, x), icon: const Icon(Icons.edit_rounded)),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class _UserDialog extends StatefulWidget {
  final String? id;
  final Map<String, dynamic>? data;

  const _UserDialog({
    this.id,
    this.data,
  });

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  final codigo = TextEditingController();
  final nombre = TextEditingController();
  final password = TextEditingController();
  String rol = 'operador';
  bool activo = true;

  @override
  void initState() {
    super.initState();
    codigo.text = widget.id ?? '';
    nombre.text = (widget.data?['nombre'] ?? '').toString();
    password.text = (widget.data?['password'] ?? '').toString();
    rol = (widget.data?['rol'] ?? 'operador').toString();
    activo = widget.data?['activo'] != false;
  }

  @override
  void dispose() {
    codigo.dispose();
    nombre.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final id = codigo.text.trim();
    if (id.isEmpty || nombre.text.trim().isEmpty || password.text.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection('usuarios').doc(id).set({
      'nombre': nombre.text.trim(),
      'password': password.text.trim(),
      'rol': rol,
      'activo': activo,
      'actualizadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.panel,
      title: Text(widget.id == null ? 'Nuevo usuario' : 'Editar usuario'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: codigo, enabled: widget.id == null, decoration: const InputDecoration(labelText: 'Código')),
              const SizedBox(height: 12),
              TextField(controller: nombre, decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 12),
              TextField(controller: password, decoration: const InputDecoration(labelText: 'Contraseña')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: rol,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'operador', child: Text('Operador')),
                  DropdownMenuItem(value: 'publico', child: Text('Público')),
                ],
                onChanged: (v) => setState(() => rol = v ?? rol),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: activo,
                title: const Text('Activo'),
                onChanged: (v) => setState(() => activo = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: save, child: const Text('Guardar')),
      ],
    );
  }
}