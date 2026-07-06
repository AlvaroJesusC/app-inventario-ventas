import 'sku.dart';

/// el modelo de producto para el inventario
class ProductModel {
  final String id;
  final String nombre;
  final double precio;
  final double costo;
  final double stock;
  final double stockMinimo;
  final String? categoria;
  final String? codigoBarras;
  final String sku;
  final bool ventaPorPeso;
  final String unidadMedida;

  ProductModel({
    required this.id,
    required this.nombre,
    required this.precio,
    this.costo = 0.0,
    required this.stock,
    this.stockMinimo = 10.0,
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
    if (stock <= stockMinimo) return '$cleanStock $suffix: Bajo Stock';
    return '$cleanStock $suffix: En Stock';
  }

  //tipo de estado para colores en la ui
  StockStatus get stockStatus {
    if (stock <= 0) return StockStatus.empty;
    if (stock <= stockMinimo) return StockStatus.low;
    return StockStatus.inStock;
  }

  //convierte desde un documento de firestore → productmodel
  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    final String nombre = map['nombre'] ?? '';
    final String categoria = map['categoria'] ?? 'General';
    final String skuGenerado = Sku.generar(nombre: nombre, categoria: categoria).valor;
    final bool isPeso = map['ventaPorPeso'] ?? false;

    return ProductModel(
      id: documentId,
      nombre: nombre,
      precio: (map['precio'] ?? 0).toDouble(),
      costo: (map['costo'] ?? 0).toDouble(),
      stock: (map['stock'] ?? 0).toDouble(),
      stockMinimo: (map['stockMinimo'] ?? (isPeso ? 15.0 : 10.0)).toDouble(),
      categoria: categoria,
      codigoBarras: map['codigoBarras'],
      sku: map['sku'] ?? skuGenerado,
      ventaPorPeso: isPeso,
      unidadMedida: map['unidadMedida'] ?? 'und',
    );
  }

  //convierte de productmodel → map para guardar en firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'precio': precio,
      'costo': costo,
      'stock': stock,
      'stockMinimo': stockMinimo,
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
  inStock, // stock > stockMinimo
  low, // stock entre 1 y stockMinimo
  empty, // stock = 0
}

enum StockFilter {
  all,
  inStock,
  low,
  empty,
  critical,
}
