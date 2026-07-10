import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/warehouse_dashboard_model.dart';

class ReportService {
  static const String _baseUrl = 'https://web-production-77cdd.up.railway.app/api/v1';
  static const String _dashboardCacheKey = 'cached_warehouse_dashboard';
  static const String _dashboardTimeKey = 'cached_warehouse_dashboard_time';
  static const String _peakHoursCacheKey = 'cached_peak_hours_data';

  // Rastrear si la información actual proviene del caché local (offline)
  static bool isOfflineData = false;
  static String lastCacheTime = '';

  /// Obtiene los datos del Dashboard de Bodega desde la API de Railway o desde el caché local si falla la red.
  Future<WarehouseDashboard> getWarehouseDashboard() async {
    final url = Uri.parse('$_baseUrl/dashboard/bodega');
    final prefs = await SharedPreferences.getInstance();
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final String rawJson = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(rawJson);

        // Guardar exitosamente en caché local
        final now = DateTime.now();
        final formattedTime = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        
        await prefs.setString(_dashboardCacheKey, rawJson);
        await prefs.setString(_dashboardTimeKey, formattedTime);

        // Resetear bandera de offline ya que la llamada fue exitosa
        isOfflineData = false;
        lastCacheTime = formattedTime;

        return WarehouseDashboard.fromJson(data);
      } else {
        throw Exception('Código de error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      // Intentar cargar desde el caché local si hay un error de red
      final String? cachedJson = prefs.getString(_dashboardCacheKey);
      if (cachedJson != null) {
        isOfflineData = true;
        lastCacheTime = prefs.getString(_dashboardTimeKey) ?? 'Desconocida';
        final Map<String, dynamic> data = json.decode(cachedJson);
        return WarehouseDashboard.fromJson(data);
      }
      throw Exception('Sin conexión y sin datos locales guardados.');
    }
  }

  /// Obtiene los datos del gráfico de horas pico de demanda (JSON) o desde el caché local si falla la red.
  Future<PeakHoursData> getPeakHoursData() async {
    final url = Uri.parse('$_baseUrl/dashboard/horas-pico');
    final prefs = await SharedPreferences.getInstance();
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final String rawJson = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(rawJson);

        // Guardar exitosamente en caché local
        await prefs.setString(_peakHoursCacheKey, rawJson);
        return PeakHoursData.fromJson(data);
      } else {
        throw Exception('Código de error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      // Intentar cargar desde el caché local si hay un error de red
      final String? cachedJson = prefs.getString(_peakHoursCacheKey);
      if (cachedJson != null) {
        final Map<String, dynamic> data = json.decode(cachedJson);
        return PeakHoursData.fromJson(data);
      }
      throw Exception('Sin conexión y sin datos locales guardados para horas pico.');
    }
  }

  /// Pre-descarga y guarda en caché las imágenes históricas de Railway
  Future<void> preloadReportImages() async {
    final List<String> endpoints = [
      'https://web-production-77cdd.up.railway.app/anomalias',
      'https://web-production-77cdd.up.railway.app/clasificar',
      'https://web-production-77cdd.up.railway.app/horas-pico',
      'https://web-production-77cdd.up.railway.app/eventos-especiales',
    ];

    final prefs = await SharedPreferences.getInstance();
    print('>>> ReportService: Iniciando pre-carga de imágenes en segundo plano...');

    for (final url in endpoints) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          final String base64Image = base64Encode(response.bodyBytes);
          await prefs.setString('cached_image_$url', base64Image);
          print('>>> ReportService: Precargada exitosamente: $url');
        } else {
          print('>>> ReportService: Error ${response.statusCode} al precargar: $url');
        }
      } catch (e) {
        print('>>> ReportService: Excepción al precargar $url: $e');
      }
    }
    print('>>> ReportService: Finalizó la pre-carga de imágenes.');
  }
}
