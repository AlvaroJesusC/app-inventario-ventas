import 'sku.dart';

/// el modelo de producto para el inventario
class ProductModel {
  final String id;
  final String nombre;
  final double precio;
  final double stock;
  final String? categoria;
  final String? codigoBarras;
  final String sku;
  final bool ventaPorPeso;
  final String unidadMedida;

  ProductModel({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.stock,
    this.categoria,
    this.codigoBarras,
    required this.sku,
    this.ventaPorPeso = false,
    this.unidadMedida = 'und',
  });

  // estado de stock del producto
  String get stockLabel {
    final cleanStock = stock % 1 == 0 ? stock.toInt().toString() : stock.toString();
    final suffix = unidadMedida.isNotEmpty ? unidadMedida : 'und';
    if (stock <= 0) return 'Agotado';
    if (stock <= 10) return '$cleanStock $suffix: Bajo Stock';
    return '$cleanStock $suffix: En Stock';
  }

  //tipo de estado para colores en la ui
  StockStatus get stockStatus {
    if (stock <= 0) return StockStatus.empty;
    if (stock <= 10) return StockStatus.low;
    return StockStatus.inStock;
  }

  //convierte desde un documento de firestore → productmodel
  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    final String nombre = map['nombre'] ?? '';
    final String categoria = map['categoria'] ?? 'General';
    final String skuGenerado = Sku.generar(nombre: nombre, categoria: categoria).valor;

    return ProductModel(
      id: documentId,
      nombre: nombre,
      precio: (map['precio'] ?? 0).toDouble(),
      stock: (map['stock'] ?? 0).toDouble(),
      categoria: categoria,
      codigoBarras: map['codigoBarras'],
      sku: map['sku'] ?? skuGenerado,
      ventaPorPeso: map['ventaPorPeso'] ?? false,
      unidadMedida: map['unidadMedida'] ?? 'und',
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
      'sku': sku,
      'ventaPorPeso': ventaPorPeso,
      'unidadMedida': unidadMedida,
    };
  }
}

//Estados posibles del stock
enum StockStatus {
  inStock, // stock > 10
  low, // stock entre 1 y 10
  empty, // stock = 0
}

enum StockFilter {
  all,
  inStock,
  low,
  empty,
  critical,
}
