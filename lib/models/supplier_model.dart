class SupplierModel {
  final String id;
  final String nombre;
  final String? telefono;
  final String? ruc;

  SupplierModel({
    required this.id,
    required this.nombre,
    this.telefono,
    this.ruc,
  });

  factory SupplierModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SupplierModel(
      id: documentId,
      nombre: map['nombre'] ?? '',
      telefono: map['telefono'],
      ruc: map['ruc'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      if (telefono != null) 'telefono': telefono,
      if (ruc != null) 'ruc': ruc,
    };
  }
}
