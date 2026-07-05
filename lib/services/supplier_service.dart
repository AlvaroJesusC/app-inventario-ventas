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

  /// Proveedores por defecto (demo / fallback)
  static List<SupplierModel> get defaultSuppliers => [
    SupplierModel(id: 'sup_1', nombre: 'Distribuidora Lima Norte', telefono: '987654321', ruc: '20123456789'),
    SupplierModel(id: 'sup_2', nombre: 'Comercial Abastece SAC', telefono: '912345678', ruc: '20987654321'),
    SupplierModel(id: 'sup_3', nombre: 'Inversiones San Pedro SAC', telefono: '955443322', ruc: '20554433221'),
    SupplierModel(id: 'sup_4', nombre: 'Bodega Don Pepe E.I.R.L.', telefono: '944332211', ruc: '20443322110'),
  ];
}