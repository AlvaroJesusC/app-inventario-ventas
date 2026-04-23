class UserModel {
  final String uid;
  final String nombre;
  final String email;
  final String rol;

  UserModel({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  /// Crea un objeto vacío/por defecto
  factory UserModel.empty(String uid, String email) {
    return UserModel(
      uid: uid,
      nombre: 'Nuevo Usuario',
      email: email,
      rol: 'Administrador Principal',
    );
  }

  /// Convierte desde un mapa de Firestore
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      nombre: map['nombre'] ?? 'Usuario',
      email: map['email'] ?? '',
      rol: map['rol'] ?? 'Administrador Principal',
    );
  }

  /// Convierte a mapa para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'email': email,
      'rol': rol,
    };
  }

  /// Copia con nuevos valores
  UserModel copyWith({
    String? nombre,
    String? email,
    String? rol,
  }) {
    return UserModel(
      uid: uid,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rol: rol ?? this.rol,
    );
  }

  /// Iniciales para el avatar
  String get initials {
    if (nombre.isEmpty) return 'U';
    final parts = nombre.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nombre.substring(0, nombre.length > 1 ? 2 : 1).toUpperCase();
  }
}
