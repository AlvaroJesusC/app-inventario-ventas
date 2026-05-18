import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'categorias';

  // Obtener todas las categorías activas en tiempo real (Para llenar el Dropdown)
  Stream<List<CategoryModel>> getCategoriesStream() {
    return _firestore
        .collection(_collection)
        .where('activo', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
          .toList();
          
      // Ordenamos localmente para evitar que Firebase pida un Índice Compuesto
      list.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      
      return list;
    });
  }

  // Agregar una nueva categoría
  Future<String> addCategory(CategoryModel category) async {
    try {
      DocumentReference docRef = await _firestore.collection(_collection).add(category.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al agregar categoría: $e');
    }
  }

  // Actualizar una categoría
  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _firestore.collection(_collection).doc(category.id).update(category.toMap());
    } catch (e) {
      throw Exception('Error al actualizar categoría: $e');
    }
  }

  // "Eliminar" categoría (Soft delete: solo la ocultamos)
  Future<void> deleteCategory(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({'activo': false});
    } catch (e) {
      throw Exception('Error al eliminar categoría: $e');
    }
  }
}
