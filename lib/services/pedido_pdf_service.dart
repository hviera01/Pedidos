import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/order_item.dart';
import '../models/pdf_field_options.dart';
import 'image_bytes_service.dart';

class PedidoPdfService {
  static Future<Uint8List> build({
    required List<OrderItem> items,
    required PdfFieldOptions fields,
    required Map<String, Uint8List?> imageBytes,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) {
          if (context.pageNumber > 1) return pw.SizedBox();
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Text(
              'Pedido de camisas',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
          );
        },
        build: (context) => [
          for (var i = 0; i < items.length; i++) _itemBlock(i + 1, items[i], fields, imageBytes),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _itemBlock(
    int index,
    OrderItem item,
    PdfFieldOptions fields,
    Map<String, Uint8List?> imageBytes,
  ) {
    final mainBytes = imageBytes[item.imgPrincipalUrl];
    final patches = item.imgsParchesUrl.map((u) => imageBytes[u]).whereType<Uint8List>().toList();

    final rows = <pw.Widget>[
      pw.Text('Camisa #$index', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 6),
    ];

    if (fields.cliente) rows.add(_field('Cliente', item.clienteNombre.trim().isEmpty ? '-' : item.clienteNombre.trim()));
    if (fields.version) rows.add(_field('Versión', item.version.trim().isEmpty ? '-' : item.version.trim()));
    if (fields.talla) rows.add(_field('Talla', item.talla.trim().isEmpty ? '-' : item.talla.trim()));
    if (fields.nombreNumero) rows.add(_field('Nombre / Número', item.nombreNumero.trim().isEmpty ? '-' : item.nombreNumero.trim()));
    if (fields.cantidad) rows.add(_field('Cantidad', '${item.cantidad <= 0 ? 1 : item.cantidad}'));
    if (fields.estado) rows.add(_field('Estado', item.entregado ? 'Entregado' : 'Pendiente'));

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (fields.imagenPrincipal)
            pw.Container(
              width: 110,
              height: 110,
              margin: const pw.EdgeInsets.only(right: 12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: mainBytes == null
                  ? pw.Center(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Sin imagen${_shortError(item.imgPrincipalUrl)}',
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(color: PdfColors.red400, fontSize: 7),
                        ),
                      ),
                    )
                  : pw.ClipRRect(
                      horizontalRadius: 8,
                      verticalRadius: 8,
                      child: pw.Image(pw.MemoryImage(mainBytes), width: 110, height: 110, fit: pw.BoxFit.cover),
                    ),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                ...rows,
                if (fields.parches && patches.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  pw.Text('Parches', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                  pw.SizedBox(height: 4),
                  pw.Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: patches.map((bytes) {
                      return pw.Container(
                        width: 46,
                        height: 46,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.ClipRRect(
                          horizontalRadius: 6,
                          verticalRadius: 6,
                          child: pw.Image(pw.MemoryImage(bytes), width: 46, height: 46, fit: pw.BoxFit.cover),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _shortError(String rawUrl) {
    final error = ImageBytesService.lastError(rawUrl);
    if (error == null || error.trim().isEmpty) return '';
    final short = error.length > 60 ? '${error.substring(0, 60)}...' : error;
    return '\n$short';
  }

  static pw.Widget _field(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
