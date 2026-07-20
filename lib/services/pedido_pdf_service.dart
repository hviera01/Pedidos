import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/utils/formatters.dart';
import '../models/order_item.dart';
import '../models/pdf_field_options.dart';

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
          if (fields.anyMoney) _totalsBlock(items, fields),
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
    if (fields.precioUnit) rows.add(_field('Precio unitario', Formatters.money(item.precioUnit)));
    if (fields.totalVenta) rows.add(_field('Total', Formatters.money(item.totalVenta)));
    if (fields.pagado) rows.add(_field('Pagado', Formatters.money(item.pagado)));
    if (fields.debe) rows.add(_field('Debe', Formatters.money(item.debe)));

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
              height: 100,
              alignment: pw.Alignment.center,
              margin: const pw.EdgeInsets.only(right: 12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: mainBytes == null
                  ? pw.Text('Sin imagen', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9))
                  : pw.Image(pw.MemoryImage(mainBytes), fit: pw.BoxFit.contain),
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
                        alignment: pw.Alignment.center,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
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

  static pw.Widget _totalsBlock(List<OrderItem> items, PdfFieldOptions fields) {
    final total = items.fold<double>(0, (a, b) => a + b.totalVenta);
    final pagado = items.fold<double>(0, (a, b) => a + b.pagado);
    final debe = items.fold<double>(0, (a, b) => a + b.debe);

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Totales del pedido', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          if (fields.totalVenta) _field('Total', Formatters.money(total)),
          if (fields.pagado) _field('Pagado', Formatters.money(pagado)),
          if (fields.debe) _field('Debe', Formatters.money(debe)),
        ],
      ),
    );
  }
}
