/// el modelo de producto para el inventario
class ProductModel {
  final String id;
  final String nombre;
  final double precio;
  final int stock;
  final String? categoria;
  final String? codigoBarras;

  ProductModel({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.stock,
    this.categoria,
    this.codigoBarras,
  });

  // estado de stock del producto
  String get stockLabel {
    if (stock <= 0) return 'Agotado';
    if (stock <= 10) return 'Bajo: $stock';
    return '$stock en stock';
  }

  //tipo de estado para colores en la ui
  StockStatus get stockStatus {
    if (stock <= 0) return StockStatus.empty;
    if (stock <= 10) return StockStatus.low;
    return StockStatus.inStock;
  }

  //convierte desde un documento de firestore → productmodel
  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductModel(
      id: documentId,
      nombre: map['nombre'] ?? '',
      precio: (map['precio'] ?? 0).toDouble(),
      stock: (map['stock'] ?? 0).toInt(),
      categoria: map['categoria'],
      codigoBarras: map['codigoBarras'],
    );
  }

  //convierte de productmodel → map para guardar en firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'precio': precio,
      'stock': stock,
      'categoria': categoria,
      'codigoBarras': codigoBarras,
    };
  }
}

//Estados posibles del stock
enum StockStatus {
  inStock, // stock > 10
  low, // stock entre 1 y 10
  empty, // stock = 0
}
