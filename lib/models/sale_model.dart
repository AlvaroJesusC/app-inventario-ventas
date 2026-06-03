import 'package:cloud_firestore/cloud_firestore.dart';

class SaleItemModel {
  final String id;
  final String name;
  final String sku;
  final double price;
  final int quantity;

  SaleItemModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.quantity,
  });

  factory SaleItemModel.fromMap(Map<String, dynamic> map) {
    return SaleItemModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      sku: map['sku'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'price': price,
      'quantity': quantity,
    };
  }
}

class SaleModel {
  final String id;
  final DateTime fecha;
  final double total;
  final int totalItems;
  final String cashier;
  final String status;
  final String type;
  final List<SaleItemModel> items;

  SaleModel({
    required this.id,
    required this.fecha,
    required this.total,
    required this.totalItems,
    required this.cashier,
    this.status = 'PAGADO',
    this.type = 'MENUDEO',
    required this.items,
  });

  factory SaleModel.fromMap(Map<String, dynamic> map, String documentId) {
    var rawItems = map['items'] as List<dynamic>? ?? [];
    List<SaleItemModel> saleItems = rawItems
        .map((item) => SaleItemModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    DateTime parsedDate;
    if (map['fecha'] is Timestamp) {
      parsedDate = (map['fecha'] as Timestamp).toDate();
    } else if (map['fecha'] is String) {
      parsedDate = DateTime.tryParse(map['fecha']) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return SaleModel(
      id: documentId,
      fecha: parsedDate,
      total: (map['total'] ?? 0).toDouble(),
      totalItems: (map['totalItems'] ?? 0).toInt(),
      cashier: map['cashier'] ?? 'Cajero',
      status: map['status'] ?? 'PAGADO',
      type: map['type'] ?? 'MENUDEO',
      items: saleItems,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fecha': Timestamp.fromDate(fecha),
      'total': total,
      'totalItems': totalItems,
      'cashier': cashier,
      'status': status,
      'type': type,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }
}
