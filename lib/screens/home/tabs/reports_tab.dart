import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/app_theme.dart';
import '../../../models/warehouse_dashboard_model.dart';
import '../../../services/report_service.dart';
import '../../reports/reports_images_screen.dart';

/// Tab de Reportes — Dashboard de Bodega conectado al Agente IA
class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> with SingleTickerProviderStateMixin {
  final ReportService _reportService = ReportService();
  WarehouseDashboard? _dashboardData;
  PeakHoursData? _peakHoursData;
  bool _isLoading = true;
  String? _errorMessage;

  // Pestaña interna de listas: 0 = Recomendaciones de Compra, 1 = Alertas de Vencimiento
  int _activeListTab = 0;

  // Pestaña interna del gráfico de ventas: 0 = Pronóstico Semanal, 1 = Horas Pico (MLP)
  int _activeSalesChartTab = 0;

  // Índice de sección del gráfico circular seleccionada para mostrar detalles extra
  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _reportService.getWarehouseDashboard(),
        _reportService.getPeakHoursData(),
      ]);
      setState(() {
        _dashboardData = results[0] as WarehouseDashboard;
        _peakHoursData = results[1] as PeakHoursData;
        _isLoading = false;
      });
      if (!ReportService.isOfflineData) {
        _reportService.preloadReportImages();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Color _parseHexColor(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      if (cleaned.length == 6) {
        return Color(int.parse('FF$cleaned', radix: 16));
      }
      return Color(int.parse(cleaned, radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  /// Muestra un modal deslizable (Bottom Sheet) con los gráficos específicos de IA del producto
  void _showProductDetailsBottomSheet(BuildContext context, String productNombre, String productoId) {
    int activeModalTab = 0; // 0 = Demanda Proyectada, 1 = Estado de Reposición

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final String predecirUrl = 'https://web-production-77cdd.up.railway.app/predecir?producto_id=$productoId';
            final String restockUrl = 'https://web-production-77cdd.up.railway.app/restock?producto_id=$productoId';
            final String activeUrl = activeModalTab == 0 ? predecirUrl : restockUrl;

            return Container(
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra superior de arrastre / decoración
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Fila de encabezado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productNombre,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'ID: $productoId • Análisis de IA',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Selector de pestañas internas del Bottom Sheet
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                activeModalTab = 0;
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: activeModalTab == 0 ? AppTheme.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: activeModalTab == 0
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Proyección Demanda',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: activeModalTab == 0 ? AppTheme.primaryGreen : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                activeModalTab = 1;
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: activeModalTab == 1 ? AppTheme.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: activeModalTab == 1
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Políticas Restock',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: activeModalTab == 1 ? AppTheme.primaryGreen : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Contenedor de la Imagen con zoom / pantalla completa
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _showFullscreenNetworkImage(
                          context,
                          '$productNombre - ${activeModalTab == 0 ? "Proyección" : "Restock"}',
                          activeUrl,
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundGrey,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            activeUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        ReportService.isOfflineData
                                            ? Icons.wifi_off_rounded
                                            : Icons.broken_image_rounded,
                                        color: Colors.grey.shade400,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        ReportService.isOfflineData
                                            ? 'Los gráficos predictivos requieren conexión a internet'
                                            : 'Gráfico no disponible para este producto',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _showFullscreenNetworkImage(
                            context,
                            '$productNombre - ${activeModalTab == 0 ? "Proyección" : "Restock"}',
                            activeUrl,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.fullscreen_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Nota del pie
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ReportService.isOfflineData
                              ? 'Modo sin conexión. Conéctate a internet para generar predicciones en tiempo real.'
                              : 'Este gráfico es generado en tiempo real por el modelo Prophet en Railway.',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Muestra la imagen en pantalla completa con soporte para zoom (pinch-to-zoom) y arrastre
  void _showFullscreenNetworkImage(
    BuildContext context,
    String title,
    String imageUrl,
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
                  child: Image.network(imageUrl, fit: BoxFit.contain),
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
    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      color: AppTheme.primaryGreen,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGrey,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryGreen,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Consultando Inteligencia de Bodega...',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppTheme.error,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error de Carga',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchDashboardData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_dashboardData == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          if (ReportService.isOfflineData) ...[
            _buildOfflineBanner(),
            const SizedBox(height: 20),
          ],
          _buildTodaySummary(),
          const SizedBox(height: 24),
          _buildListSection(),
          const SizedBox(height: 24),
          _buildPieChartSection(),
          const SizedBox(height: 24),
          _buildBarChartSection(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBC02D).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: Color(0xFFF57F17),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Modo sin conexión',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mostrando datos de la última sincronización: ${ReportService.lastCacheTime}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard de Bodega',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Análisis predictivo e inventario inteligente',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Botón oculto por detrás para acceder a los gráficos históricos de Matplotlib
        IconButton(
          icon: Icon(
            Icons.query_stats_rounded,
            color: AppTheme.primaryGreen.withValues(alpha: 0.8),
            size: 26,
          ),
          tooltip: 'Ver gráficos de imágenes',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ReportsImagesScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTodaySummary() {
    final resumen = _dashboardData!.resumenHoy;
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Alertas Rojas',
            value: resumen.alertasRojas.toString(),
            color: const Color(0xFFE53935),
            icon: Icons.error_rounded,
            bgColor: const Color(0xFFFFEBEE),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            title: 'Alertas Amar.',
            value: resumen.alertasAmarillas.toString(),
            color: const Color(0xFFF57C00),
            icon: Icons.warning_rounded,
            bgColor: const Color(0xFFFFF3E0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            title: 'Riesgo Venc.',
            value: 'S/. ${resumen.dineroEnRiesgoVencimiento.toStringAsFixed(1)}',
            color: const Color(0xFF7B1FA2),
            icon: Icons.hourglass_bottom_rounded,
            bgColor: const Color(0xFFF3E5F5),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildListSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Selector de Pestañas
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildListTabButton(
                    label: 'Recomendaciones',
                    index: 0,
                    icon: Icons.shopping_cart_checkout_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildListTabButton(
                    label: 'Vencimientos',
                    index: 1,
                    icon: Icons.calendar_today_rounded,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F1F1)),

          // Lista de Items
          Container(
            height: 240,
            padding: const EdgeInsets.all(12),
            child: _activeListTab == 0
                ? _buildRecomendacionesList()
                : _buildVencimientosList(),
          ),
        ],
      ),
    );
  }

  Widget _buildListTabButton({
    required String label,
    required int index,
    required IconData icon,
  }) {
    final bool isActive = _activeListTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeListTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryGreenLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppTheme.primaryGreen : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? AppTheme.primaryGreen : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecomendacionesList() {
    final recomendaciones = _dashboardData!.recomendacionesCompra;
    if (recomendaciones.isEmpty) {
      return const Center(child: Text('No hay recomendaciones de compra disponibles.'));
    }
    return ListView.separated(
      itemCount: recomendaciones.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final rec = recomendaciones[index];
        final isAlta = rec.prioridad == 'ALTA' || rec.colorAlerta == 'rojo';
        
        return InkWell(
          onTap: rec.productoId == 'none' ? null : () => _showProductDetailsBottomSheet(context, rec.productoNombre, rec.productoId),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAlta ? const Color(0xFFFFF8F8) : AppTheme.backgroundGrey,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isAlta ? const Color(0xFFFFDCD8) : Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        rec.productoNombre,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAlta ? const Color(0xFFE53935) : AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rec.prioridad,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        rec.motivo,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_rounded, size: 14, color: Colors.amber.shade700),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          rec.sugerencia,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      if (rec.productoId != 'none') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryGreenDark.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVencimientosList() {
    final alertas = _dashboardData!.alertasVencimiento;
    if (alertas.isEmpty) {
      return const Center(child: Text('No hay alertas de vencimiento.'));
    }
    return ListView.separated(
      itemCount: alertas.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final alerta = alertas[index];
        final isRojo = alerta.colorAlerta == 'rojo';
        
        return InkWell(
          onTap: () => _showProductDetailsBottomSheet(context, alerta.productoNombre, alerta.productoId),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isRojo ? const Color(0xFFFFECEB) : const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isRojo ? const Color(0xFFFFCDCA) : const Color(0xFFFFEB9C),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        alerta.productoNombre,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isRojo ? const Color(0xFFE53935) : const Color(0xFFF57C00),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${alerta.diasParaVencer} DÍAS',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Cantidad en riesgo: ',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    Text(
                      '${alerta.cantidadEnRiesgo} unidades',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isRojo ? const Color(0xFFE53935) : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flash_on_rounded, size: 14, color: Colors.purple),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          alerta.accionSugerida,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.purple.shade700.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPieChartSection() {
    final categorias = _dashboardData!.categoriasMasVendidas;
    if (categorias.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categorías Más Vendidas',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            'Distribución de ventas del mes',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Gráfico Circular
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedPieIndex = -1;
                            return;
                          }
                          _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 4,
                    centerSpaceRadius: 30,
                    sections: List.generate(categorias.length, (i) {
                      final cat = categorias[i];
                      final isTouched = i == _touchedPieIndex;
                      final double radius = isTouched ? 48.0 : 40.0;
                      final double fontSize = isTouched ? 14.0 : 11.0;

                      return PieChartSectionData(
                        color: _parseHexColor(cat.colorHex),
                        value: cat.porcentajeTotal,
                        title: '${cat.porcentajeTotal}%',
                        radius: radius,
                        titleStyle: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Leyendas
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(categorias.length, (index) {
                    final cat = categorias[index];
                    final catColor = _parseHexColor(cat.colorHex);
                    final isSelected = index == _touchedPieIndex;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: catColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat.categoria,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${cat.porcentajeTotal}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: catColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Top productos de la categoría seleccionada o por defecto la primera
          _buildTopProductosWidget(categorias),
        ],
      ),
    );
  }

  Widget _buildTopProductosWidget(List<CategoriaMasVendida> categorias) {
    final int selectedIndex = _touchedPieIndex != -1 && _touchedPieIndex < categorias.length
        ? _touchedPieIndex
        : 0;

    final cat = categorias[selectedIndex];
    final color = _parseHexColor(cat.colorHex);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars_rounded, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                'Top Productos: ${cat.categoria}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (cat.topProductos.isEmpty)
            const Text(
              'No hay productos registrados en este top.',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
            )
          else
            Column(
              children: cat.topProductos.map((prod) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${prod.puesto}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          prod.nombre,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${prod.ventasEstimadasMes} vtas/mes',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBarChartSection() {
    final grafico = _dashboardData!.graficoVentasSemanal;
    if (grafico.ejeXDias.isEmpty) return const SizedBox.shrink();

    // Obtener el valor máximo para configurar el eje Y
    double maxValue = 50.0;
    for (var val in grafico.ejeYValores) {
      if (val > maxValue) {
        maxValue = val;
      }
    }
    maxValue = (maxValue * 1.15).ceilToDouble(); // margen del 15% arriba

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila de título con el selector de gráficos (Semanal vs Horas Pico)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activeSalesChartTab == 0 ? grafico.titulo : 'Demanda por Horas Pico',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _activeSalesChartTab == 0 ? 'Pronóstico de demanda semanal' : 'Curva de horas con mayor venta (IA)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              
              // Pequeño toggle selector
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _activeSalesChartTab = 0;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _activeSalesChartTab == 0 ? AppTheme.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: _activeSalesChartTab == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          'Semana',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _activeSalesChartTab == 0 ? AppTheme.primaryGreen : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _activeSalesChartTab = 1;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _activeSalesChartTab == 1 ? AppTheme.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: _activeSalesChartTab == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          'Horas Pico',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _activeSalesChartTab == 1 ? AppTheme.primaryGreen : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Mostrar Gráfico de Barras Nativo o Gráfico de Horas Pico (Matplotlib PNG)
          _activeSalesChartTab == 0
              ? SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxValue,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppTheme.primaryGreenDark,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${grafico.ejeXDias[group.x]}\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: '${rod.toY.toStringAsFixed(1)} unds',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final int index = value.toInt();
                              if (index >= 0 && index < grafico.ejeXDias.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    grafico.ejeXDias[index],
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text(
                                value.toStringAsFixed(0),
                                style: TextStyle(
                                  color: AppTheme.textHint,
                                  fontSize: 9,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.shade100,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(grafico.ejeYValores.length, (index) {
                        final double val = grafico.ejeYValores[index];
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: val,
                              color: AppTheme.primaryGreen,
                              width: 14,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                )
              : SizedBox(
                  height: 180,
                  child: _peakHoursData == null || _peakHoursData!.productos.isEmpty
                      ? const Center(child: Text('No hay datos de horas pico disponibles.'))
                      : LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: 23,
                            minY: 0,
                            maxY: 2.2,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.grey.shade100,
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 4,
                                  getTitlesWidget: (value, meta) {
                                    final int h = value.toInt();
                                    if (h >= 0 && h <= 23) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          '${h}h',
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toStringAsFixed(1),
                                      style: TextStyle(
                                        color: AppTheme.textHint,
                                        fontSize: 9,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (_) => AppTheme.primaryGreenDark,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    final prod = _peakHoursData!.productos[spot.barIndex];
                                    return LineTooltipItem(
                                      '${prod.productoNombre}\n',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '${spot.y.toStringAsFixed(2)} unds a las ${spot.x.toInt()}h',
                                          style: const TextStyle(
                                            color: Colors.amber,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                            lineBarsData: _peakHoursData!.productos.map((prod) {
                              final Color color = _parseHexColor(prod.colorHex);
                              return LineChartBarData(
                                spots: List.generate(
                                  prod.valoresPorHora.length,
                                  (h) => FlSpot(h.toDouble(), prod.valoresPorHora[h]),
                                ),
                                isCurved: true,
                                color: color,
                                barWidth: 2.5,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: color.withValues(alpha: 0.03),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                ),
          if (_activeSalesChartTab == 1 && _peakHoursData != null && _peakHoursData!.productos.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: _peakHoursData!.productos.map((prod) {
                final Color color = _parseHexColor(prod.colorHex);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${prod.productoNombre} (Pico: ${prod.horaPico}h)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          
          // Banner Inteligente
          _activeSalesChartTab == 0
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryGreen.withValues(alpha: 0.15),
                        AppTheme.primaryGreen.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.insights_rounded,
                        color: AppTheme.primaryGreen,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          grafico.notaInteligente,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : (_peakHoursData == null
                  ? const Center(child: CircularProgressIndicator())
                  : _buildInterpretationBox(_peakHoursData!.interpretacion)),
        ],
      ),
    );
  }

  Widget _buildInterpretationBox(PeakHoursInterpretation data) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color bgColor = isDark ? const Color(0xFF1B2E20) : const Color(0xFFE8F5E9);
    final Color borderColor = isDark ? const Color(0xFF2E4D34) : const Color(0xFFC8E6C9);
    final Color titleColor = isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20);
    final Color iconColor = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
    final Color textColor = isDark ? Colors.white70 : Colors.black87;
    final Color recColor = isDark ? Colors.white60 : Colors.black54;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del reporte
          Text(
            data.titulo,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 12.0),
          // Lista de picos detectados con iconos
          Column(
            children: data.picos.map((pico) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.access_time_filled_rounded,
                      color: iconColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: textColor, fontSize: 13),
                          children: [
                            TextSpan(
                              text: "${pico.horario}: ",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: pico.detalle),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          Divider(color: borderColor, height: 16),
          // Recomendación/Nota final
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  data.recomendacion,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: recColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}