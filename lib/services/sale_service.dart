import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sale_model.dart';

class SaleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _salesRef {
    return _firestore.collection('ventas');
  }

  /// ttiempo real de todas las ventas ordenadas por fecha descendente
  Stream<List<SaleModel>> getSalesStream() {
    return _salesRef.orderBy('fecha', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return SaleModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Agregar una nueva venta y actualizar el stock de los productos vendidos
  Future<String> addSale(SaleModel sale) async {
    // 1. Agregar la venta a la colección 'ventas'
    final docRef = await _salesRef.add(sale.toMap());

    // 2. Descontar stock de los productos vendidos en lote (batch)
    final batch = _firestore.batch();
    for (var item in sale.items) {
      if (item.id.isNotEmpty) {
        final productDocRef = _firestore.collection('productos').doc(item.id);
        batch.update(productDocRef, {
          'stock': FieldValue.increment(-item.quantity),
        });
      }
    }
    await batch.commit();

    return docRef.id;
  }
}
