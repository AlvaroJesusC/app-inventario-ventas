import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('usuarios');

  /// Obtener el perfil del usuario actual (en un Stream para actualizar en tiempo real)
  Stream<UserModel?> getUserProfileStream(String uid, String email) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        // Autoreparación: Si no existe, genera el default en Firebase
        final newUser = UserModel.empty(uid, email);
        saveUserProfile(newUser); // Guarda silenciosamente de fondo
        return newUser;
      }
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  /// Obtener el perfil como un Future
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  /// Crear o actualizar un perfil completo
  Future<void> saveUserProfile(UserModel user) async {
    await _usersRef.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  /// Actualizar un solo campo (ejemplo: nombre)
  Future<void> updateField(String uid, String field, dynamic value) async {
    await _usersRef.doc(uid).update({field: value});
  }

  /// Obtener todos los usuarios
  Stream<List<UserModel>> getAllUsersStream() {
    return _usersRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}
