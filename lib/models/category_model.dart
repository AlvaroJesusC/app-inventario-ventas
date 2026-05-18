class CategoryModel {
  final String id;
  final String nombre;
  final String descripcion;
  final String colorHex;
  final bool activo;

  CategoryModel({
    required this.id,
    required this.nombre,
    this.descripcion = '',
    this.colorHex = '#4CAF50', // Color verde por defecto
    this.activo = true,
  });

  /// Convierte desde un documento de Firestore a CategoryModel
  factory CategoryModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CategoryModel(
      id: documentId,
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      colorHex: map['colorHex'] ?? '#4CAF50',
      activo: map['activo'] ?? true,
    );
  }

  /// Convierte de CategoryModel a Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'colorHex': colorHex,
      'activo': activo,
    };
  }
}
