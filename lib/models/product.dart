class Product {
  final String id;
  final String codigo;
  final String descripcion;
  final double precio;
  final int stock;
  final String imgUrl;
  final bool activo;

  const Product({
    required this.id,
    required this.codigo,
    required this.descripcion,
    required this.precio,
    required this.stock,
    required this.imgUrl,
    required this.activo,
  });

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      codigo: (map['codigo'] ?? map['sku'] ?? map['code'] ?? id).toString(),
      descripcion: (map['descripcion'] ?? map['nombre'] ?? map['detalle'] ?? map['name'] ?? '').toString(),
      precio: double.tryParse((map['precio'] ?? map['precioVenta'] ?? map['precioUnit'] ?? map['price'] ?? 0).toString()) ?? 0,
      stock: int.tryParse((map['stock'] ?? map['existencia'] ?? map['cantidad'] ?? map['qty'] ?? 0).toString()) ?? 0,
      imgUrl: (map['imgUrl'] ?? map['imagenUrl'] ?? map['imageUrl'] ?? map['fotoUrl'] ?? map['imagen'] ?? map['foto'] ?? map['urlImagen'] ?? map['storagePath'] ?? '').toString(),
      activo: map['activo'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'descripcion': descripcion,
      'precio': precio,
      'stock': stock,
      'imgUrl': imgUrl,
      'activo': activo,
    };
  }
}