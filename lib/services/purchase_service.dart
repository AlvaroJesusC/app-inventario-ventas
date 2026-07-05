import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_movement_model.dart';
import '../models/purchase_model.dart';

class PurchaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'compras';

  CollectionReference<Map<String, dynamic>> get _comprasRef =>
      _firestore.collection(_collection);

  /// Stream en tiempo real de compras ordenadas por fecha descendente
  Stream<List<PurchaseModel>> getPurchasesStream() {
    return _comprasRef
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _getDemoPurchases();
      }
      return snapshot.docs.map((doc) {
        return PurchaseModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Registra una nueva compra e incrementa automáticamente el stock de los productos
  Future<String> addPurchase(PurchaseModel purchase) async {
    final batch = _firestore.batch();

    // 1. Guardar la compra en /compras
    final docRef = _comprasRef.doc();
    batch.set(docRef, purchase.toMap());

    // 2. Incrementar stock de los productos involucrados y registrar trazabilidad Kardex
    for (var item in purchase.articulos) {
      if (item.productId.isNotEmpty) {
        final productDoc = _firestore.collection('productos').doc(item.productId);
        batch.update(productDoc, {
          'stock': FieldValue.increment(item.cantidad),
        });

        // Movimiento de inventario Kardex (tipo: compra)
        final movementDoc = _firestore.collection('movimientos_inventario').doc();
        final movement = MovementModel(
          id: '',
          productoId: item.productId,
          tipo: 'compra',
          cantidad: item.cantidad,
          unidad: item.unidad,
          fecha: purchase.fecha,
          referenciaId: docRef.id,
        );
        batch.set(movementDoc, movement.toMap());
      }
    }

    await batch.commit();
    return docRef.id;
  }

  /// Eliminar una compra
  Future<void> deletePurchase(String purchaseId) async {
    await _comprasRef.doc(purchaseId).delete();
  }

  /// Lista demo inspirada en la captura del diseño (Image 2) cuando no hay datos
  static List<PurchaseModel> _getDemoPurchases() {
    return [
      PurchaseModel(
        id: 'demo_1',
        proveedor: 'Distribuidora Lima Norte',
        fecha: DateTime(2026, 6, 28, 10, 30),
        total: 340.0,
        totalProductos: 3,
        totalUnidades: 120,
        articulos: [
          PurchaseItemModel(productId: '1', nombre: 'Agua de mesa 625ml', sku: 'AGU-001', cantidad: 50, unidad: 'und', costoUnitario: 1.0, costoTotal: 50.0),
          PurchaseItemModel(productId: '2', nombre: 'Gaseosa Inca Kola 1.5L', sku: 'GAS-002', cantidad: 40, unidad: 'und', costoUnitario: 5.0, costoTotal: 200.0),
          PurchaseItemModel(productId: '3', nombre: 'Papas fritas Lay\'s 160g', sku: 'PAP-003', cantidad: 30, unidad: 'und', costoUnitario: 3.0, costoTotal: 90.0),
        ],
      ),
      PurchaseModel(
        id: 'demo_2',
        proveedor: 'Comercial Abastece SAC',
        fecha: DateTime(2026, 6, 24, 15, 45),
        total: 620.50,
        totalProductos: 5,
        totalUnidades: 210,
        articulos: [
          PurchaseItemModel(productId: '4', nombre: 'Pollo Fresco', sku: 'POL-004', cantidad: 50.5, unidad: 'kg', costoUnitario: 8.50, costoTotal: 429.25),
        ],
      ),
      PurchaseModel(
        id: 'demo_3',
        proveedor: 'Inversiones San Pedro SAC',
        fecha: DateTime(2026, 6, 20, 11, 15),
        total: 275.0,
        totalProductos: 4,
        totalUnidades: 85,
        articulos: [],
      ),
      PurchaseModel(
        id: 'demo_4',
        proveedor: 'Bodega Don Pepe E.I.R.L.',
        fecha: DateTime(2026, 6, 16, 09, 00),
        total: 150.0,
        totalProductos: 2,
        totalUnidades: 60,
        articulos: [],
      ),
    ];
  }
}
