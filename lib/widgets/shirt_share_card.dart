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

    final nombreNumero = item.nombreNumero.trim();
    final parts = nombreNumero.split(RegExp(r'\s+')).where((x) => x.trim().isNotEmpty).toList();
    final numeros = parts.where((x) => RegExp(r'\d').hasMatch(x)).toList();
    final nombres = parts.where((x) => !RegExp(r'\d').hasMatch(x)).toList();
    final numero = numeros.isEmpty ? 'No especificado' : numeros.join(' ');
    final nombre = nombres.isEmpty ? 'Sin nombre' : nombres.join(' ');

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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(title: 'Cliente', value: cliente),
                _Pill(title: 'Talla', value: talla),
                _Pill(title: 'Cantidad', value: '$cantidad'),
                _Pill(title: 'Nombre', value: nombre),
                _Pill(title: 'Número', value: numero),
              ],
            ),
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

  const _Pill({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100, maxWidth: 200),
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
