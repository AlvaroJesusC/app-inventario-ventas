import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_theme.dart';

/// Pantalla secundaria que visualiza los Gráficos de Agente IA en Railway
class ReportsImagesScreen extends StatefulWidget {
  const ReportsImagesScreen({super.key});

  @override
  State<ReportsImagesScreen> createState() => _ReportsImagesScreenState();
}

class _ReportsImagesScreenState extends State<ReportsImagesScreen> {
  final Map<String, Uint8List> _imageBytesMap = {};
  final Map<String, bool> _loadingMap = {};
  final Map<String, String?> _errorMap = {};
  final Map<String, bool> _isCachedMap = {};

  final List<String> _endpoints = const [
    'https://web-production-77cdd.up.railway.app/anomalias',
    'https://web-production-77cdd.up.railway.app/clasificar',
    'https://web-production-77cdd.up.railway.app/horas-pico',
    'https://web-production-77cdd.up.railway.app/eventos-especiales',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllImages();
  }

  Future<void> _loadAllImages() async {
    for (final url in _endpoints) {
      await _fetchSingleImage(url);
      // Pequeño delay de 150ms para evitar peticiones simultáneas a Matplotlib en Railway
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  Future<void> _fetchSingleImage(String url) async {
    if (!mounted) return;
    setState(() {
      _loadingMap[url] = true;
      _errorMap[url] = null;
    });

    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        // Guardar la imagen en caché como base64
        final String base64Image = base64Encode(response.bodyBytes);
        await prefs.setString('cached_image_$url', base64Image);

        if (mounted) {
          setState(() {
            _imageBytesMap[url] = response.bodyBytes;
            _isCachedMap[url] = false;
            _loadingMap[url] = false;
          });
        }
      } else {
        throw Exception('HTTP Error ${response.statusCode}');
      }
    } catch (e) {
      // Intentar cargar la imagen desde el caché local offline
      final String? cachedBase64 = prefs.getString('cached_image_$url');
      if (cachedBase64 != null && cachedBase64.isNotEmpty) {
        final Uint8List cachedBytes = base64Decode(cachedBase64);
        if (mounted) {
          setState(() {
            _imageBytesMap[url] = cachedBytes;
            _isCachedMap[url] = true;
            _loadingMap[url] = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMap[url] = 'Error de conexión y sin caché local';
            _loadingMap[url] = false;
          });
        }
      }
    }
  }

  bool get _isAnyLoading =>
      _loadingMap.values.any((loading) => loading == true);

  void _showFullscreenImage(
    BuildContext context,
    String title,
    Uint8List imageBytes,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                boundaryMargin: const EdgeInsets.all(240),
                child: Center(
                  child: Image.memory(imageBytes, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Gráficos del Agente IA',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppTheme.primaryGreen),
            onPressed: _isAnyLoading ? null : _loadAllImages,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadAllImages();
        },
        color: AppTheme.primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildAgentStatusCard(),
              const SizedBox(height: 24),

              // 🔴 1. Dashboard de Alertas (PRIMERO)
              _buildSectionHeader('Alertas e Inventario Crítico'),
              const SizedBox(height: 12),
              _buildReportCard(
                title: 'Panel de Alertas Críticas y Anomalías',
                subtitle: 'endpoint /anomalias',
                baseUrl: 'https://web-production-77cdd.up.railway.app/anomalias',
                icon: Icons.warning_amber_rounded,
                iconBgColor: const Color(0xFFFFF3E0),
                iconColor: const Color(0xFFE65100),
              ),
              const SizedBox(height: 24),

              // 📊 2, 3 y 4: Análisis de Demanda y Tendencias
              _buildSectionHeader('Análisis de Demanda y Ventas'),
              const SizedBox(height: 12),
              _buildReportCard(
                title: 'Productos Más Vendidos por Categoría',
                subtitle: 'endpoint /clasificar',
                baseUrl: 'https://web-production-77cdd.up.railway.app/clasificar',
                icon: Icons.pie_chart_rounded,
                iconBgColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                iconColor: AppTheme.primaryGreen,
              ),
              const SizedBox(height: 16),
              _buildReportCard(
                title: 'Demanda Proyectada por Hora (Horarios Pico)',
                subtitle: 'endpoint /horas-pico',
                baseUrl: 'https://web-production-77cdd.up.railway.app/horas-pico',
                icon: Icons.access_time_filled_rounded,
                iconBgColor: const Color(0xFFE3F2FD),
                iconColor: const Color(0xFF1565C0),
              ),
              const SizedBox(height: 16),
              _buildReportCard(
                title: 'Impacto de Feriados y Fechas Especiales',
                subtitle: 'endpoint /eventos-especiales',
                baseUrl:
                    'https://web-production-77cdd.up.railway.app/eventos-especiales',
                icon: Icons.event_available_rounded,
                iconBgColor: const Color(0xFFF3E5F5),
                iconColor: const Color(0xFF7B1FA2),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.smart_toy_rounded,
            color: AppTheme.primaryGreen,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agente IA Histórico',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Visualización de gráficos generados por IA',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textHint.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAgentStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Estado: Conectado a Railway',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _isAnyLoading ? null : _loadAllImages,
            icon: _isAnyLoading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryGreen,
                    ),
                  )
                : Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: AppTheme.primaryGreen,
                  ),
            label: Text(
              _isAnyLoading ? 'Actualizando...' : 'Verificar',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required String baseUrl,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    final bytes = _imageBytesMap[baseUrl];
    final isLoading = _loadingMap[baseUrl] ?? false;
    final errorMessage = _errorMap[baseUrl];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textHint.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.fullscreen_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  tooltip: 'Ver pantalla completa',
                  onPressed: bytes != null
                      ? () => _showFullscreenImage(context, title, bytes)
                      : null,
                ),
              ],
            ),
          ),

          // Imagen del Gráfico o Estado de Carga
          GestureDetector(
            onTap: bytes != null
                ? () => _showFullscreenImage(context, title, bytes)
                : null,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              constraints: const BoxConstraints(minHeight: 180, maxHeight: 320),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGrey,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Builder(
                  builder: (context) {
                    if (isLoading && bytes == null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: AppTheme.primaryGreen,
                                strokeWidth: 3,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Obteniendo gráfico de Railway...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (errorMessage != null && bytes == null) {
                      return Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported_outlined,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No se pudo cargar el gráfico ($title)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              baseUrl,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textHint.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => _fetchSingleImage(baseUrl),
                              icon: const Icon(Icons.refresh_rounded, size: 14),
                              label: const Text(
                                'Reintentar',
                                style: TextStyle(fontSize: 11),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryGreen,
                                side: BorderSide(
                                  color: AppTheme.primaryGreen,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (bytes != null) {
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: Image.memory(bytes, fit: BoxFit.contain),
                          ),
                          if (_isCachedMap[baseUrl] == true)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.cloud_off_rounded,
                                      color: Colors.white,
                                      size: 11,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Offline (Caché)',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
