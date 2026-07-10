import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/warehouse_dashboard_model.dart';

class ReportService {
  static const String _baseUrl = 'https://web-production-77cdd.up.railway.app/api/v1';

  /// Obtiene los datos del Dashboard de Bodega desde la API de Railway.
  /// Maneja decodificación UTF-8 para caracteres especiales y establece un timeout de 15 segundos.
  Future<WarehouseDashboard> getWarehouseDashboard() async {
    final url = Uri.parse('$_baseUrl/dashboard/bodega');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return WarehouseDashboard.fromJson(data);
      } else {
        throw Exception('Error del servidor: Código ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de red al conectar con el servidor del Dashboard de Bodega.');
    }
  }

  /// Obtiene los datos del gráfico de horas pico de demanda (JSON)
  Future<PeakHoursData> getPeakHoursData() async {
    final url = Uri.parse('$_baseUrl/dashboard/horas-pico');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return PeakHoursData.fromJson(data);
      } else {
        throw Exception('Error del servidor: Código ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de red al conectar con el servidor para obtener horas pico.');
    }
  }
}
