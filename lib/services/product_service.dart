import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

/// Servicio de productos con Cloud Firestore
///
/// Colección: /productos
/// Campos por documento: nombre (string), precio (number), stock (number)
/// El ID del documento lo genera Firestore automáticamente
class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Referencia a la colección "productos"
  CollectionReference<Map<String, dynamic>> get _productosRef {
    return _firestore.collection('productos');
  }

  // ─── LECTURA ───────────────────────────────────────────────

  /// Stream en tiempo real de todos los productos (se actualiza solo)
  Stream<List<ProductModel>> getProductsStream() {
    return _productosRef
        .orderBy('nombre')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Obtener un producto por su ID
  Future<ProductModel?> getProductById(String productId) async {
    final doc = await _productosRef.doc(productId).get();
    if (!doc.exists) return null;
    return ProductModel.fromMap(doc.data()!, doc.id);
  }

  // ─── ESCRITURA ─────────────────────────────────────────────

  /// Agregar un nuevo producto
  Future<String> addProduct(ProductModel product) async {
    final docRef = await _productosRef.add(product.toMap());
    return docRef.id;
  }

  /// Actualizar un producto existente
  Future<void> updateProduct(ProductModel product) async {
    await _productosRef.doc(product.id).update(product.toMap());
  }

  /// Eliminar un producto
  Future<void> deleteProduct(String productId) async {
    await _productosRef.doc(productId).delete();
  }

  // ─── STOCK ─────────────────────────────────────────────────

  /// Actualizar solo el stock
  Future<void> updateStock(String productId, int newStock) async {
    await _productosRef.doc(productId).update({'stock': newStock});
  }
}
