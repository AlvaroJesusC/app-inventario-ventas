import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';

/// Tab de Reportes — contenido vacío por ahora
class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  bool _isLoading = false;
  bool _showReport = false;

  void _generateReport() async {
    setState(() {
      _isLoading = true;
      _showReport = false;
    });

    // Simulamos carga para la demo
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _showReport = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildGenerateButton(),
          const SizedBox(height: 24),
          if (_showReport) _buildReportContent(),
        ],
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
          child: const Icon(Icons.view_in_ar_rounded, color: AppTheme.primaryGreen, size: 36),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informe Inteligente IA',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Análisis automático de tu inventario y ventas',
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

  Widget _buildGenerateButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _generateReport,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryGreen,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Generar Análisis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
    );
  }

  Widget _buildReportContent() {
    return Column(
      children: [
        _buildSalesPredictionCard(),
        const SizedBox(height: 16),
        _buildStockAlertsCard(),
        const SizedBox(height: 16),
        _buildTopProductsCard(),
        const SizedBox(height: 16),
        _buildRecommendationsCard(),
        const SizedBox(height: 80), // Espacio extra para que no lo tape la navegación inferior
      ],
    );
  }

  Widget _buildCard({required Widget header, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          header,
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSalesPredictionCard() {
    return _buildCard(
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.trending_up_rounded, color: AppTheme.primaryGreen, size: 16),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Predicción de Ventas', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  Text('Próximos 7 días', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: const Row(
              children: [
                Text('+12.5%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
                SizedBox(width: 2),
                Icon(Icons.arrow_upward_rounded, size: 12, color: AppTheme.primaryGreen),
              ],
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: _ChartPainter(),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hoy', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
              Text('Mañana', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
              Text('Mié', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
              Text('Jue', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
              Text('Vie', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
              Text('Sáb', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
              Text('Dom', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockAlertsCard() {
    return _buildCard(
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.inventory_2_outlined, color: Colors.red, size: 16),
              ),
              const SizedBox(width: 8),
              const Text('Alertas de Stock', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ],
          ),
          const Row(
            children: [
              Text('Ver todas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen)),
              Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.primaryGreen),
            ],
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAlertItem(Icons.water_drop_rounded, 'Agua de mesa sin gas Cielo', 'ID: NRkv9 • Bebidas', 'Crítico', '35 en stock', true),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppTheme.divider, height: 1)),
          _buildAlertItem(Icons.water_drop_rounded, 'Agua loa', 'ID: QqwDH • Bebidas', 'Bajo', '24 en stock', false),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppTheme.divider, height: 1)),
          _buildAlertItem(Icons.fastfood_rounded, 'Al punto de sal Lays', 'ID: ljSFG • Snacks', 'Bajo', '26 en stock', false),
        ],
      ),
    );
  }

  Widget _buildAlertItem(IconData icon, String name, String sub, String badgeText, String stockText, bool isCritical) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: AppTheme.backgroundGrey, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppTheme.textHint, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCritical ? Colors.red.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isCritical ? Colors.red : Colors.orange.shade700),
              ),
            ),
            const SizedBox(height: 4),
            Text(stockText, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _buildTopProductsCard() {
    return _buildCard(
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
              ),
              const SizedBox(width: 8),
              const Text('Productos más vendidos', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ],
          ),
          const Row(
            children: [
              Text('Ver reporte', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen)),
              Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.primaryGreen),
            ],
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTopItem(1, Icons.water_drop_rounded, 'Agua de mesa sin gas Cielo', 1234, 1.0),
          const SizedBox(height: 16),
          _buildTopItem(2, Icons.water_drop_rounded, 'Agua loa', 987, 0.8),
          const SizedBox(height: 16),
          _buildTopItem(3, Icons.fastfood_rounded, 'Al punto de sal Lays', 765, 0.6),
        ],
      ),
    );
  }

  Widget _buildTopItem(int rank, IconData icon, String name, int count, double fraction) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text('$rank', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: AppTheme.textHint, size: 20),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          flex: 3,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                height: 6,
                alignment: Alignment.centerLeft,
                child: Container(
                  width: constraints.maxWidth * fraction,
                  height: 6,
                  decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(3)),
                ),
              );
            }
          ),
        ),
        const SizedBox(width: 12),
        Text('$count', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildRecommendationsCard() {
    return _buildCard(
      header: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 16),
          ),
          const SizedBox(width: 8),
          const Text('Recomendaciones IA', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ],
      ),
      child: Column(
        children: [
          _buildTipItem(Icons.trending_up_rounded, 'Aumenta el stock de', 'Agua de mesa sin gas Cielo', 'La demanda aumentará un 18% la próxima semana.'),
          const SizedBox(height: 12),
          _buildTipItem(Icons.local_offer_outlined, 'Considera ofrecer descuentos en', 'Agua loa', 'La rotación de este producto ha disminuido.'),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String prefix, String highlight, String sub) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                    children: [
                      TextSpan(text: '$prefix '),
                      TextSpan(text: highlight, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint, size: 16),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryGreen
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
      
    final path = Path();
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.166, size.height * 0.5),
      Offset(size.width * 0.333, size.height * 0.65),
      Offset(size.width * 0.5, size.height * 0.35),
      Offset(size.width * 0.666, size.height * 0.25),
      Offset(size.width * 0.833, size.height * 0.15),
      Offset(size.width, size.height * 0.05),
    ];
    
    path.moveTo(points[0].dx, points[0].dy);
    for(int i=1; i<points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
    
    // Fill Gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primaryGreen.withValues(alpha: 0.3),
          AppTheme.primaryGreen.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
      
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    
    // Grid Lines (líneas de fondo tenues)
    final gridPaint = Paint()
      ..color = AppTheme.divider
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(Offset(0, size.height * 0.25), Offset(size.width, size.height * 0.25), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.75), Offset(size.width, size.height * 0.75), gridPaint);
    
    // Dots
    final dotPaint = Paint()..color = AppTheme.primaryGreen..style = PaintingStyle.fill;
    final dotBgPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    
    final labels = ['980', '1.250', '1.100', '1.450', '1.700', '1.950', '2.100'];
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    for (int i=0; i<points.length; i++) {
      canvas.drawCircle(points[i], 5, dotBgPaint);
      canvas.drawCircle(points[i], 3, dotPaint);
      
      // Draw values text above dots
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w600),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(points[i].dx - textPainter.width / 2, points[i].dy - 16));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
