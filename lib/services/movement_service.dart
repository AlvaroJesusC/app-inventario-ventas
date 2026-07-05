import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_movement_model.dart';

class MovementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'movimientos_inventario';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(_collection);

  /// Registrar un movimiento de inventario en la colección /movimientos_inventario
  Future<String> registrarMovimiento(MovementModel movimiento) async {
    final docRef = await _ref.add(movimiento.toMap());
    return docRef.id;
  }
}
