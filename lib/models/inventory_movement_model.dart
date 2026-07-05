import 'package:cloud_firestore/cloud_firestore.dart';

class MovementModel {
  final String id;
  final String productoId;
  final String tipo; // "compra" | "inventario_inicial"
  final double cantidad;
  final String unidad; // "und" | "kg" | "L"
  final DateTime fecha;
  final String? referenciaId;

  MovementModel({
    required this.id,
    required this.productoId,
    required this.tipo,
    required this.cantidad,
    required this.unidad,
    required this.fecha,
    this.referenciaId,
  });

  factory MovementModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parsedDate;
    if (map['fecha'] is Timestamp) {
      parsedDate = (map['fecha'] as Timestamp).toDate().toLocal();
    } else if (map['fecha'] is String) {
      parsedDate = DateTime.tryParse(map['fecha']) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return MovementModel(
      id: documentId,
      productoId: map['productoId'] ?? '',
      tipo: map['tipo'] ?? 'inventario_inicial',
      cantidad: (map['cantidad'] ?? 0).toDouble(),
      unidad: map['unidad'] ?? 'und',
      fecha: parsedDate,
      referenciaId: map['referenciaId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productoId': productoId,
      'tipo': tipo,
      'cantidad': cantidad,
      'unidad': unidad,
      'fecha': Timestamp.fromDate(fecha),
      'referenciaId': referenciaId,
    };
  }
}
