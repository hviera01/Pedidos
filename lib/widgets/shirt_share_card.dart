import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/order_item.dart';

/// Tarjeta limpia (sin datos de dinero) para compartir una camisa como imagen.
class ShirtShareCard extends StatelessWidget {
  final OrderItem item;
  final Uint8List? mainImageBytes;
  final String? mainImageError;
  final List<Uint8List> patchImageBytes;

  const ShirtShareCard({
    super.key,
    required this.item,
    required this.mainImageBytes,
    this.mainImageError,
    required this.patchImageBytes,
  });

  @override
  Widget build(BuildContext context) {
    final version = item.version.trim().isEmpty ? 'Sin versión' : item.version.trim();
    final talla = item.talla.trim().isEmpty ? 'Sin talla' : item.talla.trim();
    final cantidad = item.cantidad <= 0 ? 1 : item.cantidad;
    final cliente = item.clienteNombre.trim().isEmpty ? 'Sin cliente' : item.clienteNombre.trim();
    final nombreNumero = item.nombreNumero.trim().isEmpty ? 'No especificado' : item.nombreNumero.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(color: AppTheme.bg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.panel,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.checkroom_rounded, color: AppTheme.accent, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Confirmación de camisa',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.panel2,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    version,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.panel2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: 1,
                child: mainImageBytes == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.image_not_supported_rounded, color: AppTheme.muted, size: 32),
                              if (mainImageError != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  mainImageError!,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppTheme.danger, fontSize: 10),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : Image.memory(mainImageBytes!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _Pill(title: 'Talla', value: talla)),
                const SizedBox(width: 8),
                Expanded(child: _Pill(title: 'Cantidad', value: '$cantidad')),
              ],
            ),
            const SizedBox(height: 8),
            _Pill(title: 'Nombre / Número', value: nombreNumero, fullWidth: true),
            const SizedBox(height: 8),
            _Pill(title: 'Cliente', value: cliente, fullWidth: true),
            if (patchImageBytes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Parches', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: patchImageBytes.map((bytes) {
                  return Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.panel2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.memory(bytes, fit: BoxFit.cover),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Generado ${Formatters.date(DateTime.now())} · Por favor confirmá que esta info sea correcta.',
              style: const TextStyle(color: AppTheme.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String title;
  final String value;
  final bool fullWidth;

  const _Pill({required this.title, required this.value, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.panel2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
