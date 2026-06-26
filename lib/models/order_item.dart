class OrderItem {
  final String id;
  final String pedidoId;
  final String clienteNombre;
  final String version;
  final String talla;
  final String nombreNumero;
  final int cantidad;
  final double precioUnit;
  final double totalVenta;
  final double pagado;
  final double debe;
  final String imgPrincipalUrl;
  final List<String> imgsParchesUrl;
  final bool entregado;
  final bool manual;

  const OrderItem({
    required this.id,
    required this.pedidoId,
    required this.clienteNombre,
    required this.version,
    required this.talla,
    required this.nombreNumero,
    required this.cantidad,
    required this.precioUnit,
    required this.totalVenta,
    required this.pagado,
    required this.debe,
    required this.imgPrincipalUrl,
    required this.imgsParchesUrl,
    required this.entregado,
    required this.manual,
  });

  factory OrderItem.fromMap(String id, String pedidoId, Map<String, dynamic> map) {
    final rawPatches = map['imgsParchesUrl'] ?? map['parchesUrls'] ?? map['parches'] ?? map['imgsParches'] ?? map['patches'] ?? [];

    return OrderItem(
      id: id,
      pedidoId: pedidoId,
      clienteNombre: (map['clienteNombre'] ?? map['cliente'] ?? map['nombreCliente'] ?? '').toString(),
      version: (map['version'] ?? map['tipo'] ?? '').toString(),
      talla: (map['talla'] ?? map['size'] ?? '').toString(),
      nombreNumero: (map['nombreNumero'] ?? map['detalle'] ?? map['nombre'] ?? '').toString(),
      cantidad: int.tryParse((map['cantidad'] ?? map['qty'] ?? 1).toString()) ?? 1,
      precioUnit: double.tryParse((map['precioUnit'] ?? map['precio'] ?? map['price'] ?? 0).toString()) ?? 0,
      totalVenta: double.tryParse((map['totalVenta'] ?? map['total'] ?? 0).toString()) ?? 0,
      pagado: double.tryParse((map['pagado'] ?? map['paid'] ?? 0).toString()) ?? 0,
      debe: double.tryParse((map['debe'] ?? map['saldo'] ?? 0).toString()) ?? 0,
      imgPrincipalUrl: (map['imgPrincipalUrl'] ?? map['imgUrl'] ?? map['imagenUrl'] ?? map['imageUrl'] ?? map['fotoUrl'] ?? map['foto'] ?? map['imagen'] ?? map['storagePath'] ?? '').toString(),
      imgsParchesUrl: rawPatches is List ? rawPatches.map((x) => x.toString()).toList() : [],
      entregado: map['entregado'] == true,
      manual: map['manual'] == true,
    );
  }
}