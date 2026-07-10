class WarehouseDashboard {
  final ResumenHoy resumenHoy;
  final List<RecomendacionCompra> recomendacionesCompra;
  final List<AlertaVencimiento> alertasVencimiento;
  final List<CategoriaMasVendida> categoriasMasVendidas;
  final GraficoVentasSemanal graficoVentasSemanal;

  WarehouseDashboard({
    required this.resumenHoy,
    required this.recomendacionesCompra,
    required this.alertasVencimiento,
    required this.categoriasMasVendidas,
    required this.graficoVentasSemanal,
  });

  factory WarehouseDashboard.fromJson(Map<String, dynamic> json) {
    return WarehouseDashboard(
      resumenHoy: ResumenHoy.fromJson(json['resumen_hoy'] ?? {}),
      recomendacionesCompra: (json['recomendaciones_compra'] as List? ?? [])
          .map((item) => RecomendacionCompra.fromJson(item))
          .toList(),
      alertasVencimiento: (json['alertas_vencimiento'] as List? ?? [])
          .map((item) => AlertaVencimiento.fromJson(item))
          .toList(),
      categoriasMasVendidas: (json['categorias_mas_vendidas'] as List? ?? [])
          .map((item) => CategoriaMasVendida.fromJson(item))
          .toList(),
      graficoVentasSemanal: GraficoVentasSemanal.fromJson(json['grafico_ventas_semanal'] ?? {}),
    );
  }
}

class ResumenHoy {
  final int alertasRojas;
  final int alertasAmarillas;
  final double dineroEnRiesgoVencimiento;

  ResumenHoy({
    required this.alertasRojas,
    required this.alertasAmarillas,
    required this.dineroEnRiesgoVencimiento,
  });

  factory ResumenHoy.fromJson(Map<String, dynamic> json) {
    return ResumenHoy(
      alertasRojas: json['alertas_rojas'] ?? 0,
      alertasAmarillas: json['alertas_amarillas'] ?? 0,
      dineroEnRiesgoVencimiento: (json['dinero_en_riesgo_vencimiento'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RecomendacionCompra {
  final String productoId;
  final String productoNombre;
  final String prioridad;
  final String colorAlerta;
  final String motivo;
  final String sugerencia;

  RecomendacionCompra({
    required this.productoId,
    required this.productoNombre,
    required this.prioridad,
    required this.colorAlerta,
    required this.motivo,
    required this.sugerencia,
  });

  factory RecomendacionCompra.fromJson(Map<String, dynamic> json) {
    return RecomendacionCompra(
      productoId: json['producto_id'] ?? '',
      productoNombre: json['producto_nombre'] ?? '',
      prioridad: json['prioridad'] ?? '',
      colorAlerta: json['color_alerta'] ?? '',
      motivo: json['motivo'] ?? '',
      sugerencia: json['sugerencia'] ?? '',
    );
  }
}

class AlertaVencimiento {
  final String productoId;
  final String productoNombre;
  final String colorAlerta;
  final int diasParaVencer;
  final int cantidadEnRiesgo;
  final String accionSugerida;

  AlertaVencimiento({
    required this.productoId,
    required this.productoNombre,
    required this.colorAlerta,
    required this.diasParaVencer,
    required this.cantidadEnRiesgo,
    required this.accionSugerida,
  });

  factory AlertaVencimiento.fromJson(Map<String, dynamic> json) {
    return AlertaVencimiento(
      productoId: json['producto_id'] ?? '',
      productoNombre: json['producto_nombre'] ?? '',
      colorAlerta: json['color_alerta'] ?? '',
      diasParaVencer: json['dias_para_vencer'] ?? 0,
      cantidadEnRiesgo: json['cantidad_en_riesgo'] ?? 0,
      accionSugerida: json['accion_sugerida'] ?? '',
    );
  }
}

class CategoriaMasVendida {
  final String categoria;
  final double porcentajeTotal;
  final String colorHex;
  final List<TopProducto> topProductos;

  CategoriaMasVendida({
    required this.categoria,
    required this.porcentajeTotal,
    required this.colorHex,
    required this.topProductos,
  });

  factory CategoriaMasVendida.fromJson(Map<String, dynamic> json) {
    return CategoriaMasVendida(
      categoria: json['categoria'] ?? '',
      porcentajeTotal: (json['porcentaje_total'] as num?)?.toDouble() ?? 0.0,
      colorHex: json['color_hex'] ?? '#9E9E9E',
      topProductos: (json['top_productos'] as List? ?? [])
          .map((item) => TopProducto.fromJson(item))
          .toList(),
    );
  }
}

class TopProducto {
  final int puesto;
  final String nombre;
  final int ventasEstimadasMes;

  TopProducto({
    required this.puesto,
    required this.nombre,
    required this.ventasEstimadasMes,
  });

  factory TopProducto.fromJson(Map<String, dynamic> json) {
    return TopProducto(
      puesto: json['puesto'] ?? 0,
      nombre: json['nombre'] ?? '',
      ventasEstimadasMes: json['ventas_estimadas_mes'] ?? 0,
    );
  }
}

class GraficoVentasSemanal {
  final String titulo;
  final List<String> ejeXDias;
  final List<double> ejeYValores;
  final String notaInteligente;

  GraficoVentasSemanal({
    required this.titulo,
    required this.ejeXDias,
    required this.ejeYValores,
    required this.notaInteligente,
  });

  factory GraficoVentasSemanal.fromJson(Map<String, dynamic> json) {
    return GraficoVentasSemanal(
      titulo: json['titulo'] ?? '',
      ejeXDias: List<String>.from(json['eje_x_dias'] ?? []),
      ejeYValores: (json['eje_y_valores'] as List? ?? [])
          .map((item) => (item as num).toDouble())
          .toList(),
      notaInteligente: json['nota_inteligente'] ?? '',
    );
  }
}

class PeakHoursData {
  final List<PeakHoursProduct> productos;
  final List<int> picosGlobales;
  final PeakHoursInterpretation interpretacion;

  PeakHoursData({
    required this.productos,
    required this.picosGlobales,
    required this.interpretacion,
  });

  factory PeakHoursData.fromJson(Map<String, dynamic> json) {
    return PeakHoursData(
      productos: (json['productos'] as List? ?? [])
          .map((item) => PeakHoursProduct.fromJson(item))
          .toList(),
      picosGlobales: List<int>.from(json['picos_globales'] ?? []),
      interpretacion: PeakHoursInterpretation.fromJson(json['interpretacion'] ?? {}),
    );
  }
}

class PeakHoursProduct {
  final String productoId;
  final String productoNombre;
  final String colorHex;
  final List<double> valoresPorHora;
  final int horaPico;
  final double valorPico;

  PeakHoursProduct({
    required this.productoId,
    required this.productoNombre,
    required this.colorHex,
    required this.valoresPorHora,
    required this.horaPico,
    required this.valorPico,
  });

  factory PeakHoursProduct.fromJson(Map<String, dynamic> json) {
    return PeakHoursProduct(
      productoId: json['producto_id'] ?? '',
      productoNombre: json['producto_nombre'] ?? '',
      colorHex: json['color_hex'] ?? '#9E9E9E',
      valoresPorHora: (json['valores_por_hora'] as List? ?? [])
          .map((item) => (item as num).toDouble())
          .toList(),
      horaPico: json['hora_pico'] ?? 0,
      valorPico: (json['valor_pico'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PeakHoursInterpretation {
  final String titulo;
  final List<PeakDetail> picos;
  final String recomendacion;

  PeakHoursInterpretation({
    required this.titulo,
    required this.picos,
    required this.recomendacion,
  });

  factory PeakHoursInterpretation.fromJson(Map<String, dynamic> json) {
    var list = json['picos'] as List? ?? [];
    List<PeakDetail> picosList = list.map((i) => PeakDetail.fromJson(i)).toList();
    return PeakHoursInterpretation(
      titulo: json['titulo'] ?? '',
      picos: picosList,
      recomendacion: json['recomendacion'] ?? '',
    );
  }
}

class PeakDetail {
  final String horario;
  final String detalle;

  PeakDetail({required this.horario, required this.detalle});

  factory PeakDetail.fromJson(Map<String, dynamic> json) {
    return PeakDetail(
      horario: json['horario'] ?? '',
      detalle: json['detalle'] ?? '',
    );
  }
}
