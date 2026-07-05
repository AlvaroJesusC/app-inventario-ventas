import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseItemModel {
  final String productId;
  final String nombre;
  final String sku;
  final double cantidad;
  final String unidad;
  final double costoUnitario;
  final double costoTotal;

  PurchaseItemModel({
    required this.productId,
    required this.nombre,
    required this.sku,
    required this.cantidad,
    this.unidad = 'und',
    required this.costoUnitario,
    required this.costoTotal,
  });

  factory PurchaseItemModel.fromMap(Map<String, dynamic> map) {
    double parsedCantidad = 0.0;
    var rawCant = map['cantidad'];
    if (rawCant is num) {
      parsedCantidad = rawCant.toDouble();
    } else if (rawCant is String) {
      parsedCantidad = double.tryParse(rawCant) ?? 0.0;
    }

    double parsedCostoUnit = 0.0;
    var rawUnitCost = map['costoUnitario'] ?? map['unitCost'];
    if (rawUnitCost is num) {
      parsedCostoUnit = rawUnitCost.toDouble();
    } else if (rawUnitCost is String) {
      parsedCostoUnit = double.tryParse(rawUnitCost) ?? 0.0;
    }

    double parsedCostoTotal = 0.0;
    var rawTotalCost = map['costoTotal'] ?? map['totalCost'];
    if (rawTotalCost is num) {
      parsedCostoTotal = rawTotalCost.toDouble();
    } else if (rawTotalCost is String) {
      parsedCostoTotal = double.tryParse(rawTotalCost) ?? 0.0;
    }

    return PurchaseItemModel(
      productId: map['productId'] ?? map['id'] ?? '',
      nombre: map['nombre'] ?? map['nombreProducto'] ?? '',
      sku: map['sku'] ?? '',
      cantidad: parsedCantidad,
      unidad: map['unidad'] ?? 'und',
      costoUnitario: parsedCostoUnit,
      costoTotal: parsedCostoTotal > 0 ? parsedCostoTotal : (parsedCantidad * parsedCostoUnit),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'nombre': nombre,
      'sku': sku,
      'cantidad': cantidad,
      'unidad': unidad,
      'costoUnitario': costoUnitario,
      'costoTotal': costoTotal,
    };
  }

  String get cantidadLabel {
    final cleanQty = cantidad % 1 == 0 ? cantidad.toInt().toString() : cantidad.toStringAsFixed(2);
    return '$cleanQty $unidad';
  }
}

class PurchaseModel {
  final String id;
  final String proveedor;
  final String? supplierId;
  final DateTime fecha;
  final List<PurchaseItemModel> articulos;
  final double total;
  final int totalProductos;
  final double totalUnidades;

  PurchaseModel({
    required this.id,
    required this.proveedor,
    this.supplierId,
    required this.fecha,
    required this.articulos,
    required this.total,
    required this.totalProductos,
    required this.totalUnidades,
  });

  factory PurchaseModel.fromMap(Map<String, dynamic> map, String documentId) {
    var rawItems = map['articulos'] ?? map['items'];
    List<dynamic> itemList = rawItems is List ? rawItems : [];
    List<PurchaseItemModel> items = itemList
        .map((item) => PurchaseItemModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    DateTime parsedDate;
    if (map['fecha'] is Timestamp) {
      parsedDate = (map['fecha'] as Timestamp).toDate().toLocal();
    } else if (map['fecha'] is String) {
      parsedDate = (DateTime.tryParse(map['fecha']) ?? DateTime.now()).toLocal();
    } else {
      parsedDate = DateTime.now();
    }

    double parsedTotal = 0.0;
    var rawTotal = map['total'];
    if (rawTotal is num) {
      parsedTotal = rawTotal.toDouble();
    } else if (rawTotal is String) {
      parsedTotal = double.tryParse(rawTotal) ?? 0.0;
    }

    int parsedTotalProd = items.length;
    var rawTotalProd = map['totalProductos'];
    if (rawTotalProd is num) {
      parsedTotalProd = rawTotalProd.toInt();
    }

    double parsedTotalUnits = 0.0;
    var rawTotalUnits = map['totalUnidades'];
    if (rawTotalUnits is num) {
      parsedTotalUnits = rawTotalUnits.toDouble();
    } else {
      parsedTotalUnits = items.fold(0.0, (totalSum, i) => totalSum + i.cantidad);
    }

    return PurchaseModel(
      id: documentId,
      proveedor: map['proveedor'] ?? 'Proveedor',
      supplierId: map['supplierId'],
      fecha: parsedDate,
      articulos: items,
      total: parsedTotal,
      totalProductos: parsedTotalProd,
      totalUnidades: parsedTotalUnits,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'proveedor': proveedor,
      if (supplierId != null) 'supplierId': supplierId,
      'fecha': Timestamp.fromDate(fecha),
      'articulos': articulos.map((item) => item.toMap()).toList(),
      'total': total,
      'totalProductos': totalProductos,
      'totalUnidades': totalUnidades,
    };
  }

  String get unidadesLabel {
    final cleanUnits = totalUnidades % 1 == 0 ? totalUnidades.toInt().toString() : totalUnidades.toStringAsFixed(2);
    return '$cleanUnits unidades';
  }
}
