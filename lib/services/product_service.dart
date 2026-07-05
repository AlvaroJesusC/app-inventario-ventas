import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_movement_model.dart';
import '../models/product_model.dart';
import 'movement_service.dart';

/// Servicio de productos con Cloud Firestore
///
/// Colección: /productos
/// Campos por documento: nombre (string), precio (number), stock (number)
/// El ID del documento lo genera Firestore automáticamente
class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MovementService _movementService = MovementService();

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

    // Si Stock Inicial > 0, registrar trazabilidad Kardex (tipo: inventario_inicial)
    if (product.stock > 0) {
      final movement = MovementModel(
        id: '',
        productoId: docRef.id,
        tipo: 'inventario_inicial',
        cantidad: product.stock,
        unidad: product.unidadMedida,
        fecha: DateTime.now(),
        referenciaId: null,
      );
      await _movementService.registrarMovimiento(movement);
    }

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
  Future<void> updateStock(String productId, double newStock) async {
    await _productosRef.doc(productId).update({'stock': newStock});
  }

  // ─── BÚSQUEDA ──────────────────────────────────────────────

  /// Obtener un producto por código de barras
  Future<ProductModel?> getProductByBarcode(String barcode) async {
    final snapshot = await _productosRef
        .where('codigoBarras', isEqualTo: barcode)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return ProductModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
  }
}
