import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductRepository {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Stream<List<Product>> streamProducts() {
    return db.collection('productos').snapshots().map((snap) {
      final list = snap.docs.map((d) => Product.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => a.descripcion.compareTo(b.descripcion));
      return list;
    });
  }

  Future<void> saveProduct(Product product) async {
    final data = product.toMap();

    if (product.id.isEmpty) {
      final ref = await db.collection('productos').add(data);

      final stockInicial = product.stock < 0 ? 0 : product.stock;

      if (stockInicial > 0) {
        await db.collection('movimientos_inventario').add({
          'productoId': ref.id,
          'productoCodigo': product.codigo,
          'productoDescripcion': product.descripcion,
          'tipo': 'Entrada',
          'cantidad': stockInicial,
          'stockAnterior': 0,
          'stockNuevo': stockInicial,
          'motivo': 'Stock inicial',
          'usuario': 'admin',
          'fecha': FieldValue.serverTimestamp(),
        });
      }
    } else {
      final ref = db.collection('productos').doc(product.id);
      final snap = await ref.get();
      final anterior = snap.data()?['stock'];
      final stockAnterior = anterior is int ? anterior : int.tryParse((anterior ?? 0).toString()) ?? 0;
      final stockNuevo = product.stock < 0 ? 0 : product.stock;

      await ref.set(data, SetOptions(merge: true));

      if (stockNuevo != stockAnterior) {
        final diferencia = stockNuevo - stockAnterior;
        final tipo = diferencia >= 0 ? 'Entrada' : 'Salida';

        await db.collection('movimientos_inventario').add({
          'productoId': product.id,
          'productoCodigo': product.codigo,
          'productoDescripcion': product.descripcion,
          'tipo': tipo,
          'cantidad': diferencia.abs(),
          'stockAnterior': stockAnterior,
          'stockNuevo': stockNuevo,
          'motivo': 'Edición de producto',
          'usuario': 'admin',
          'fecha': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Future<void> adjustStock({
    required Product product,
    required int newStock,
    required String motivo,
    required String usuario,
  }) async {
    final anterior = product.stock;
    final stockNuevo = newStock < 0 ? 0 : newStock;
    final diferencia = stockNuevo - anterior;
    final tipo = diferencia >= 0 ? 'Entrada' : 'Salida';
    final cantidad = diferencia.abs();

    await db.collection('productos').doc(product.id).set({
      'stock': stockNuevo,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (cantidad > 0) {
      await db.collection('movimientos_inventario').add({
        'productoId': product.id,
        'productoCodigo': product.codigo,
        'productoDescripcion': product.descripcion,
        'tipo': tipo,
        'cantidad': cantidad,
        'stockAnterior': anterior,
        'stockNuevo': stockNuevo,
        'motivo': motivo,
        'usuario': usuario,
        'fecha': FieldValue.serverTimestamp(),
      });

      await db.collection('kardex').add({
        'codigo': product.codigo,
        'descripcion': product.descripcion,
        'stockAnterior': anterior,
        'stockNuevo': stockNuevo,
        'delta': diferencia,
        'motivo': motivo,
        'usuario': usuario,
        'fecha': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> deleteProduct(String id) async {
    await db.collection('productos').doc(id).delete();
  }
}