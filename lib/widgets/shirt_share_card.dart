import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/order_item.dart';

/// Tarjeta limpia (sin datos de dinero) para compartir una camisa como imagen.
class ShirtShareCard extends StatelessWidget {
  final OrderItem item;
  final Uint8List? mainImageBytes;
  final List<Uint8List> patchImageBytes;

  const ShirtShareCard({
    super.key,
    required this.item,
    required this.mainImageBytes,
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
      width: 480,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: AppTheme.bg),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppTheme.panel,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.checkroom_rounded, color: AppTheme.accent, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Confirmación de camisa',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.panel2,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    version,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.panel2,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: 1,
                child: mainImageBytes == null
                    ? const Center(
                        child: Icon(Icons.image_rounded, color: AppTheme.muted, size: 40),
                      )
                    : Image.memory(mainImageBytes!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Pill(title: 'Cliente', value: cliente),
                _Pill(title: 'Talla', value: talla),
                _Pill(title: 'Cantidad', value: '$cantidad'),
                _Pill(title: 'Nombre', value: nombre),
                _Pill(title: 'Número', value: numero),
              ],
            ),
            if (patchImageBytes.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text('Parches', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: patchImageBytes.map((bytes) {
                  return Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.panel2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.memory(bytes, fit: BoxFit.cover),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'Generado ${Formatters.date(DateTime.now())} · Por favor confirmá que esta info sea correcta.',
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
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
      constraints: const BoxConstraints(minWidth: 130, maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.panel2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.muted, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
