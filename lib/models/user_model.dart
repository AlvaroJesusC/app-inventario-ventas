class UserModel {
  final String uid;
  final String nombre;
  final String email;
  final String rol;
  final bool activo;

  UserModel({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
    this.activo = true,
  });

  /// crea un objeto vacío/por defecto
  factory UserModel.empty(String uid, String email) {
    return UserModel(
      uid: uid,
      nombre: 'Nuevo Usuario',
      email: email,
      rol: 'Administrador Principal',
      activo: true,
    );
  }

  /// convierte desde un mapa de Firestore
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      nombre: map['nombre'] ?? 'Usuario',
      email: map['email'] ?? '',
      rol: map['rol'] ?? 'Administrador Principal',
      activo: map['activo'] ?? true,
    );
  }

  /// Convierte a mapa para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {'nombre': nombre, 'email': email, 'rol': rol, 'activo': activo};
  }

  /// Copia con nuevos valores
  UserModel copyWith({
    String? nombre,
    String? email,
    String? rol,
    bool? activo,
  }) {
    return UserModel(
      uid: uid,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
    );
  }

  /// Iniciales para el avatar
  String get initials {
    if (nombre.trim().isEmpty) return 'U';
    final parts = nombre.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      if (parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
    }
    final cleanName = nombre.trim();
    return cleanName.substring(0, cleanName.length > 1 ? 2 : 1).toUpperCase();
  }
}
