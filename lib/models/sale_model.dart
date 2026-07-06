import 'package:cloud_firestore/cloud_firestore.dart';

class SaleItemModel {
  final String id;
  final String nombre;
  final String sku;
  final double precio;
  final int cantidad;
  final String categoria;

  SaleItemModel({
    required this.id,
    required this.nombre,
    required this.sku,
    required this.precio,
    required this.cantidad,
    this.categoria = 'General',
  });

  factory SaleItemModel.fromMap(Map<String, dynamic> map) {
    double parsedPrecio = 0.0;
    var rawPrecio = map['precio'] ?? map['price'];
    if (rawPrecio is num) {
      parsedPrecio = rawPrecio.toDouble();
    } else if (rawPrecio is String) {
      parsedPrecio = double.tryParse(rawPrecio) ?? 0.0;
    }

    int parsedCantidad = 0;
    var rawCantidad = map['cantidad'] ?? map['quantity'];
    if (rawCantidad is num) {
      parsedCantidad = rawCantidad.toInt();
    } else if (rawCantidad is String) {
      parsedCantidad = int.tryParse(rawCantidad) ?? 0;
    }

    return SaleItemModel(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? map['name'] ?? '',
      sku: map['sku'] ?? '',
      precio: parsedPrecio,
      cantidad: parsedCantidad,
      categoria: map['categoria'] ?? 'General',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'sku': sku,
      'precio': precio,
      'cantidad': cantidad,
      'categoria': categoria,
    };
  }
}

class SaleModel {
  final String id;
  final DateTime fecha;
  final double total;
  final int totalArticulos;
  final String cajero;
  final String estado;
  final String categoria;
  final List<SaleItemModel> articulos;
  final String? metodoPago;
  final String? cliente;

  SaleModel({
    required this.id,
    required this.fecha,
    required this.total,
    required this.totalArticulos,
    required this.cajero,
    this.estado = 'PAGADO',
    required this.categoria,
    required this.articulos,
    this.metodoPago,
    this.cliente,
  });

  factory SaleModel.fromMap(Map<String, dynamic> map, String documentId) {
    var rawItems = map['articulos'] ?? map['items'];
    List<dynamic> itemList = rawItems is List ? rawItems : [];
    List<SaleItemModel> saleItems = itemList
        .map((item) => SaleItemModel.fromMap(Map<String, dynamic>.from(item)))
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

    int parsedTotalArticulos = 0;
    var rawTotalArt = map['totalArticulos'] ?? map['totalItems'];
    if (rawTotalArt is num) {
      parsedTotalArticulos = rawTotalArt.toInt();
    } else if (rawTotalArt is String) {
      parsedTotalArticulos = int.tryParse(rawTotalArt) ?? 0;
    }

    return SaleModel(
      id: documentId,
      fecha: parsedDate,
      total: parsedTotal,
      totalArticulos: parsedTotalArticulos,
      cajero: map['cajero'] ?? map['cashier'] ?? 'Cajero',
      estado: map['estado'] ?? map['status'] ?? 'PAGADO',
      categoria: map['categoria'] ?? map['type'] ?? 'General',
      articulos: saleItems,
      metodoPago: map['metodoPago'],
      cliente: map['cliente'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fecha': Timestamp.fromDate(fecha),
      'total': total,
      'totalArticulos': totalArticulos,
      'cajero': cajero,
      'estado': estado,
      'categoria': categoria,
      'articulos': articulos.map((item) => item.toMap()).toList(),
      'metodoPago': metodoPago,
      'cliente': cliente,
    };
  }
}
