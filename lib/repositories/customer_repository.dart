import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';

class CustomerRepository {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Stream<List<Customer>> streamCustomers() {
    return db.collection('clientes').snapshots().map((snap) {
      final list = snap.docs.map((d) => Customer.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => a.nombre.compareTo(b.nombre));
      return list;
    });
  }

  Future<void> saveCustomer(Customer customer) async {
    if (customer.id.isEmpty) {
      await db.collection('clientes').add(customer.toMap());
    } else {
      await db.collection('clientes').doc(customer.id).set(customer.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteCustomer(String id) async {
    await db.collection('clientes').doc(id).delete();
  }
}