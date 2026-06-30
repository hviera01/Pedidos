import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_item.dart';

class OrderRepository {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<String> getOrCreateActiveOrder() async {
    final snap = await db.collection('pedidos').where('estado', isEqualTo: 'activo').limit(1).get();

    if (snap.docs.isNotEmpty) {
      return snap.docs.first.id;
    }

    return await createBlankOrder();
  }

  Future<String> createBlankOrder() async {
    final active = await db.collection('pedidos').where('estado', isEqualTo: 'activo').get();

    final batch = db.batch();

    for (final d in active.docs) {
      batch.update(d.reference, {
        'estado': 'abierto',
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    }

    final ref = db.collection('pedidos').doc();

    batch.set(ref, {
      'estado': 'activo',
      'camisasCount': 0,
      'totalVenta': 0,
      'totalPagado': 0,
      'totalDebe': 0,
      'creadoEn': FieldValue.serverTimestamp(),
      'actualizadoEn': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return ref.id;
  }

  Stream<List<OrderItem>> streamActiveItems() async* {
  final snap = await db.collection('pedidos').where('estado', isEqualTo: 'activo').limit(1).get();

  if (snap.docs.isEmpty) {
    yield <OrderItem>[];
    return;
  }

  final pedidoId = snap.docs.first.id;

  yield* streamOrderItems(pedidoId);
}

  Stream<List<OrderItem>> streamOrderItems(String pedidoId) {
  final pid = pedidoId.trim();

  if (pid.isEmpty) {
    return Stream.value(<OrderItem>[]);
  }

  return db
      .collection('pedidos')
      .doc(pid)
      .collection('camisas')
      .orderBy('creadoEn', descending: false)
      .snapshots()
      .map((snap) {
    return snap.docs.map((d) {
      return OrderItem.fromMap(d.id, pid, d.data());
    }).where((x) {
      return x.manual == false && x.version.toUpperCase() != 'CRÉDITO';
    }).toList();
  });
}

  Future<List<OrderItem>> getOrderItemsOnce(String pedidoId) async {
  final camisas = await db
      .collection('pedidos')
      .doc(pedidoId)
      .collection('camisas')
      .orderBy('creadoEn', descending: false)
      .get();

  return camisas.docs.map((d) {
    return OrderItem.fromMap(d.id, pedidoId, d.data());
  }).where((x) {
    return x.manual == false && x.version.toUpperCase() != 'CRÉDITO';
  }).toList();
}

  Stream<List<OrderItem>> streamAllItems() {
    return db.collectionGroup('camisas').snapshots().map((snap) {
      return snap.docs.map((d) {
        final pedidoId = d.reference.parent.parent?.id ?? '';
        return OrderItem.fromMap(d.id, pedidoId, d.data());
      }).where((x) {
        return x.manual == false && x.version.toUpperCase() != 'CRÉDITO';
      }).toList();
    });
  }

  Stream<List<OrderItem>> streamCxcItems() {
    return db.collection('creditos').snapshots().map((snap) {
      return snap.docs.map((d) {
        return OrderItem.fromMap(d.id, 'manual', {
          ...d.data(),
          'manual': true,
        });
      }).toList();
    });
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getHistory({
  required DateTime desde,
  required DateTime hasta,
  required bool soloCerrados,
}) async {
  final start = DateTime(desde.year, desde.month, desde.day);
  final end = DateTime(hasta.year, hasta.month, hasta.day, 23, 59, 59, 999);

  final snap = await db
      .collection('pedidos')
      .where('creadoEn', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('creadoEn', isLessThanOrEqualTo: Timestamp.fromDate(end))
      .orderBy('creadoEn', descending: true)
      .limit(120)
      .get(const GetOptions(source: Source.serverAndCache));

  if (!soloCerrados) return snap.docs;

  return snap.docs.where((d) {
    final estado = (d.data()['estado'] ?? '').toString().toLowerCase();
    return estado == 'cerrado';
  }).toList();
}

  Future<void> addItem({
    required String clienteNombre,
    required String version,
    required String talla,
    required String nombreNumero,
    required int cantidad,
    required double precioUnit,
    required double pagado,
    required String imgPrincipalUrl,
    required List<String> imgsParchesUrl,
    String? pedidoId,
  }) async {
    final pid = pedidoId ?? await getOrCreateActiveOrder();
    final totalVenta = precioUnit * cantidad;
    final debe = totalVenta - pagado;

    await db.collection('pedidos').doc(pid).collection('camisas').add({
      'clienteNombre': clienteNombre,
      'version': version,
      'talla': talla,
      'nombreNumero': nombreNumero,
      'cantidad': cantidad,
      'precioUnit': precioUnit,
      'totalVenta': totalVenta,
      'pagado': pagado,
      'debe': debe < 0 ? 0 : debe,
      'imgPrincipalUrl': imgPrincipalUrl,
      'imgsParchesUrl': imgsParchesUrl,
      'entregado': false,
      'manual': false,
      'creadoEn': FieldValue.serverTimestamp(),
      'actualizadoEn': FieldValue.serverTimestamp(),
    });

    await recalculateOrder(pid);
  }

  Future<void> addManualCredit({
    required String clienteNombre,
    required String detalle,
    required double total,
  }) async {
    await db.collection('creditos').add({
      'clienteNombre': clienteNombre,
      'version': 'CRÉDITO',
      'talla': '',
      'nombreNumero': detalle,
      'cantidad': 1,
      'precioUnit': total,
      'totalVenta': total,
      'pagado': 0,
      'debe': total,
      'imgPrincipalUrl': '',
      'imgsParchesUrl': [],
      'entregado': false,
      'manual': true,
      'estado': 'pendiente',
      'creadoEn': FieldValue.serverTimestamp(),
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateItemText({
  required OrderItem item,
  required String clienteNombre,
  required String version,
  required String talla,
  required String nombreNumero,
  required int cantidad,
  required double precioUnit,
}) async {
  final safeCantidad = cantidad <= 0 ? 1 : cantidad;
  final total = safeCantidad * precioUnit;
  final debe = total - item.pagado;
  final safeDebe = debe < 0 ? 0 : debe;

  if (item.manual || item.pedidoId == 'manual') {
    await db.collection('creditos').doc(item.id).update({
      'clienteNombre': clienteNombre,
      'version': version,
      'talla': talla,
      'nombreNumero': nombreNumero,
      'cantidad': safeCantidad,
      'precioUnit': precioUnit,
      'totalVenta': total,
      'debe': safeDebe,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });

    return;
  }

  final pedidoId = item.pedidoId.trim();
  final camisaId = item.id.trim();

  if (pedidoId.isEmpty || camisaId.isEmpty) {
    throw Exception('ID inválido para actualizar camisa.');
  }

  final oldTotal = item.totalVenta;
  final oldPagado = item.pagado;
  final oldDebe = item.debe;
  final oldCantidad = item.cantidad <= 0 ? 1 : item.cantidad;

  final batch = db.batch();

  final camisaRef = db
      .collection('pedidos')
      .doc(pedidoId)
      .collection('camisas')
      .doc(camisaId);

  final pedidoRef = db.collection('pedidos').doc(pedidoId);

  batch.update(camisaRef, {
    'clienteNombre': clienteNombre,
    'version': version,
    'talla': talla,
    'nombreNumero': nombreNumero,
    'cantidad': safeCantidad,
    'precioUnit': precioUnit,
    'totalVenta': total,
    'debe': safeDebe,
    'actualizadoEn': FieldValue.serverTimestamp(),
  });

  batch.set(pedidoRef, {
    'camisasCount': FieldValue.increment(safeCantidad - oldCantidad),
    'totalVenta': FieldValue.increment(total - oldTotal),
    'totalPagado': FieldValue.increment(item.pagado - oldPagado),
    'totalDebe': FieldValue.increment(safeDebe - oldDebe),
    'actualizadoEn': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  await batch.commit();
}

  Future<void> updateItemImages({
  required OrderItem item,
  required String imgPrincipalUrl,
  required List<String> imgsParchesUrl,
}) async {
  if (item.manual || item.pedidoId == 'manual') {
    return;
  }

  final pedidoId = item.pedidoId.trim();
  final camisaId = item.id.trim();

  if (pedidoId.isEmpty || camisaId.isEmpty) {
    throw Exception('ID inválido para actualizar imágenes.');
  }

  final cleanPatches = imgsParchesUrl
      .map((x) => x.trim())
      .where((x) => x.isNotEmpty)
      .toList();

  await db
      .collection('pedidos')
      .doc(pedidoId)
      .collection('camisas')
      .doc(camisaId)
      .update({
    'imgPrincipalUrl': imgPrincipalUrl.trim(),
    'imgsParchesUrl': cleanPatches,
    'actualizadoEn': FieldValue.serverTimestamp(),
  });
}

  Future<void> updatePayment(
    OrderItem item,
    double monto, {
    String metodo = 'Efectivo',
    String nota = '',
  }) async {
    final nuevoPagado = item.pagado + monto;
    final nuevoDebe = item.totalVenta - nuevoPagado;

    if (item.manual || item.pedidoId == 'manual') {
      await db.collection('creditos').doc(item.id).update({
        'pagado': nuevoPagado,
        'debe': nuevoDebe < 0 ? 0 : nuevoDebe,
        'estado': nuevoDebe <= 0 ? 'saldado' : 'pendiente',
        'actualizadoEn': FieldValue.serverTimestamp(),
      });

      await db.collection('pagos').add({
        'pedidoId': 'manual',
        'creditoId': item.id,
        'camisaId': item.id,
        'clienteNombre': item.clienteNombre,
        'monto': monto,
        'metodo': metodo,
        'nota': nota,
        'fecha': FieldValue.serverTimestamp(),
        'creadoEn': FieldValue.serverTimestamp(),
      });

      return;
    }

    final pedidoRef = db.collection('pedidos').doc(item.pedidoId);
    final camisaRef = pedidoRef.collection('camisas').doc(item.id);
    final pagoRef = db.collection('pagos').doc();

    final debeAnterior = item.debe;
    final debeNuevo = nuevoDebe < 0 ? 0 : nuevoDebe;

    final batch = db.batch();

    batch.update(camisaRef, {
      'pagado': nuevoPagado,
      'debe': debeNuevo,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });

    batch.set(pagoRef, {
      'pedidoId': item.pedidoId,
      'creditoId': null,
      'camisaId': item.id,
      'clienteNombre': item.clienteNombre,
      'monto': monto,
      'metodo': metodo,
      'nota': nota,
      'fecha': FieldValue.serverTimestamp(),
      'creadoEn': FieldValue.serverTimestamp(),
    });

    batch.set(pedidoRef, {
      'totalPagado': FieldValue.increment(monto),
      'totalDebe': FieldValue.increment(debeNuevo - debeAnterior),
      'actualizadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> setDelivered(OrderItem item, bool value) async {
    if (item.manual || item.pedidoId == 'manual') {
      return;
    }

    await db.collection('pedidos').doc(item.pedidoId).collection('camisas').doc(item.id).update({
      'entregado': value,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteItem(OrderItem item) async {
  if (item.manual || item.pedidoId == 'manual') {
    await db.collection('creditos').doc(item.id).delete();
    return;
  }

  final pedidoId = item.pedidoId.trim();
  final camisaId = item.id.trim();

  if (pedidoId.isEmpty || camisaId.isEmpty) {
    throw Exception('ID inválido para eliminar.');
  }

  final camisaRef = db.collection('pedidos').doc(pedidoId).collection('camisas').doc(camisaId);

  await camisaRef.delete();

  await recalculateOrder(pedidoId);
}

  Future<void> closeOrder(String? pedidoId) async {
    if (pedidoId != null && pedidoId.isNotEmpty) {
      await db.collection('pedidos').doc(pedidoId).update({
        'estado': 'cerrado',
        'cerradoEn': FieldValue.serverTimestamp(),
        'actualizadoEn': FieldValue.serverTimestamp(),
      });

      return;
    }

    final snap = await db.collection('pedidos').where('estado', isEqualTo: 'activo').limit(1).get();

    if (snap.docs.isEmpty) {
      return;
    }

    await snap.docs.first.reference.update({
      'estado': 'cerrado',
      'cerradoEn': FieldValue.serverTimestamp(),
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  Future<void> closeActiveOrder() async {
    await closeOrder(null);
  }

  Future<void> deleteOrderCompletely(String pedidoId) async {
    final pid = pedidoId.trim();

    if (pid.isEmpty) {
      throw Exception('ID de pedido inválido.');
    }

    final pedidoRef = db.collection('pedidos').doc(pid);

    final camisasSnap = await pedidoRef.collection('camisas').get();
    final pagosSnap = await db.collection('pagos').where('pedidoId', isEqualTo: pid).get();

    final batch = db.batch();

    for (final d in camisasSnap.docs) {
      batch.delete(d.reference);
    }

    for (final d in pagosSnap.docs) {
      batch.delete(d.reference);
    }

    batch.delete(pedidoRef);

    await batch.commit();
  }

  Future<void> enablePublicAccess(String pedidoId) async {
  await db.collection('pedidos').doc(pedidoId).set({
    'publicAccess': true,
    'publicAccessUpdatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

 Future<void> recalculateOrder(String pid) async {
  final pedidoId = pid.trim();

  if (pedidoId.isEmpty || pedidoId == 'manual') {
    return;
  }

  final pedidoRef = db.collection('pedidos').doc(pedidoId);
  final pedidoSnap = await pedidoRef.get();

  if (!pedidoSnap.exists) {
    return;
  }

  final snap = await pedidoRef.collection('camisas').get();

  int count = 0;
  double venta = 0;
  double pagado = 0;
  double debe = 0;

  for (final d in snap.docs) {
    final item = OrderItem.fromMap(d.id, pedidoId, d.data());

    if (item.manual || item.version.toUpperCase() == 'CRÉDITO') {
      continue;
    }

    count += item.cantidad;
    venta += item.totalVenta;
    pagado += item.pagado;
    debe += item.debe;
  }

  await pedidoRef.set({
    'camisasCount': count,
    'totalVenta': venta,
    'totalPagado': pagado,
    'totalDebe': debe,
    'actualizadoEn': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
}