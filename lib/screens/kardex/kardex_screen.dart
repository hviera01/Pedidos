import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/page_frame.dart';

class KardexScreen extends StatelessWidget {
  const KardexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Kardex',
      subtitle: 'Historial de entradas, salidas y ajustes de inventario.',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('kardex').orderBy('fecha', descending: true).snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];

          return Container(
            decoration: BoxDecoration(
              color: AppTheme.panel,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                const _Header(),
                ...docs.map((d) {
                  final x = d.data();
                  return ListTile(
                    title: Text((x['descripcion'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text((x['motivo'] ?? '').toString()),
                    trailing: Text(
                      '${x['stockAnterior'] ?? 0} → ${x['stockNuevo'] ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  );
                }),
              ],
            ),
          );
        },
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
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border))),
      child: const Row(
        children: [
          Icon(Icons.history_rounded, color: AppTheme.accent),
          SizedBox(width: 10),
          Text('Movimientos recientes', style: TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}