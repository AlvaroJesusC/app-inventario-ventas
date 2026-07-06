import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/supplier_model.dart';

class SupplierService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'proveedores';

  CollectionReference<Map<String, dynamic>> get _ref => _firestore.collection(_collection);

  /// Stream en tiempo real de proveedores
  Stream<List<SupplierModel>> getSuppliersStream() {
    return _ref.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => SupplierModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      return list;
    });
  }

  /// Agregar un proveedor
  Future<String> addSupplier(SupplierModel supplier) async {
    final docRef = await _ref.add(supplier.toMap());
    return docRef.id;
  }
}