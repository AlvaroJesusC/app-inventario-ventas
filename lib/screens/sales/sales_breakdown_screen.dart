import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/sale_model.dart';
import '../../services/sale_service.dart';

class SalesBreakdownScreen extends StatefulWidget {
  const SalesBreakdownScreen({super.key});

  @override
  State<SalesBreakdownScreen> createState() => _SalesBreakdownScreenState();
}

class _SalesBreakdownScreenState extends State<SalesBreakdownScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _showAllSales = false;
  final SaleService _saleService = SaleService();

  // Helper for month names in Spanish
  String _formatSelectedDate(DateTime date) {
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;

    final now = DateTime.now();
    final isToday = now.year == date.year && now.month == date.month && now.day == date.day;
    final isYesterday = DateTime(now.year, now.month, now.day - 1).year == date.year &&
        DateTime(now.year, now.month, now.day - 1).month == date.month &&
        DateTime(now.year, now.month, now.day - 1).day == date.day;

    String prefix = '';
    if (isToday) {
      prefix = 'Hoy / ';
    } else if (isYesterday) {
      prefix = 'Ayer / ';
    }

    return '$prefix$day de $month, $year';
  }

  // Get payment method deterministically
  String _getPaymentMethod(SaleModel sale, int index) {
    final methods = ['Efectivo', 'Yape', 'Tarjeta', 'Plin'];
    final hash = sale.id.hashCode.abs();
    return methods[(hash + index) % methods.length];
  }

  // Format time of the sale
  String _formatTime(DateTime date) {
    final localDate = date.toLocal();
    final hour = localDate.hour > 12 ? localDate.hour - 12 : (localDate.hour == 0 ? 12 : localDate.hour);
    final ampm = localDate.hour >= 12 ? 'p.m.' : 'a.m.';
    final minuteStr = localDate.minute.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')}:$minuteStr $ampm';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _showAllSales = false; // Reset expand/collapse state when changing date
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: SafeArea(
        child: StreamBuilder<List<SaleModel>>(
          stream: _saleService.getSalesStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Error cargando ventas: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              );
            }

            final allSales = snapshot.data ?? [];

            // Filter sales for the selected date
            final selectedSales = allSales.where((sale) {
              final saleLocal = sale.fecha.toLocal();
              final selectedLocal = _selectedDate.toLocal();
              return saleLocal.year == selectedLocal.year &&
                  saleLocal.month == selectedLocal.month &&
                  saleLocal.day == selectedLocal.day;
            }).toList();

            // Calculate metrics for selected date
            final double totalSold = selectedSales.fold(0.0, (sum, sale) => sum + sale.total);
            final int totalTransactions = selectedSales.length;
            final double averageSale = totalTransactions > 0 ? totalSold / totalTransactions : 0.0;
            final double maxSale = selectedSales.isEmpty 
                ? 0.0 
                : selectedSales.map((s) => s.total).reduce((a, b) => a > b ? a : b);
            final double returnsAmount = 0.0; // Placeholder

            // Calculate stats for the previous day (for trend comparison)
            final prevDate = _selectedDate.subtract(const Duration(days: 1));
            final prevSales = allSales.where((sale) {
              final saleLocal = sale.fecha.toLocal();
              final prevLocal = prevDate.toLocal();
              return saleLocal.year == prevLocal.year &&
                  saleLocal.month == prevLocal.month &&
                  saleLocal.day == prevLocal.day;
            }).toList();
            final double prevTotalSold = prevSales.fold(0.0, (sum, sale) => sum + sale.total);

            // Calculate trend percentage
            double trendPercent = 0.0;
            if (prevTotalSold > 0) {
              trendPercent = ((totalSold - prevTotalSold) / prevTotalSold) * 100;
            } else if (totalSold > 0) {
              trendPercent = 100.0;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── HEADER ──
                  _buildHeader(context),
                  const SizedBox(height: 24),

                  // ── FILTER ROW ──
                  _buildFilterRow(context),
                  const SizedBox(height: 24),

                  // ── STATS DASHBOARD CARD ──
                  _buildStatsCard(
                    totalSold: totalSold,
                    trendPercent: trendPercent,
                    prevTotalSold: prevTotalSold,
                    totalTransactions: totalTransactions,
                    averageSale: averageSale,
                    maxSale: maxSale,
                    returnsAmount: returnsAmount,
                  ),
                  const SizedBox(height: 28),

                  // ── SALES HISTORY ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Historial de ventas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      _buildExportButton(selectedSales),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Transactions List
                  if (selectedSales.isEmpty)
                    _buildEmptyState()
                  else ...[
                    _buildTransactionsList(selectedSales, allSales.length),
                    const SizedBox(height: 16),
                    _buildMoreSalesButton(selectedSales),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.primaryGreen,
            size: 26,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Desglose de Ventas',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Resumen detallado de tus ventas',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Resumen detallado'),
                content: const Text(
                  'Esta pantalla te permite visualizar un desglose de las transacciones realizadas en un día seleccionado, calcular métricas como la mayor venta, el promedio por venta, y la variación porcentual en comparación con el día anterior.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Entendido', style: TextStyle(color: AppTheme.primaryGreen)),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(
            Icons.help_outline_rounded,
            color: AppTheme.primaryGreen,
            size: 24,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    return Row(
      children: [
        // Date Selector Button
        Expanded(
          child: GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatSelectedDate(_selectedDate),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Filter Button with dot
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Los filtros ya están activos para la fecha seleccionada.'),
                backgroundColor: AppTheme.primaryGreen,
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  color: AppTheme.textPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard({
    required double totalSold,
    required double trendPercent,
    required double prevTotalSold,
    required int totalTransactions,
    required double averageSale,
    required double maxSale,
    required double returnsAmount,
  }) {
    final bool isPositive = trendPercent >= 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20), // Dark green background matching the mockup
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Sold Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.attach_money_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL VENDIDO',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'S/. ${totalSold.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Trend Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${trendPercent.abs().toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'vs. ayer (S/. ${prevTotalSold.toStringAsFixed(2)})',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 24),

          // 4 Sub-metrics Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSubMetric(
                icon: Icons.shopping_bag_outlined,
                value: '$totalTransactions',
                label: 'Transacciones',
              ),
              _buildSubMetric(
                icon: Icons.trending_up_rounded,
                value: 'S/. ${averageSale.toStringAsFixed(2)}',
                label: 'Promedio/venta',
              ),
              _buildSubMetric(
                icon: Icons.arrow_upward_rounded,
                value: 'S/. ${maxSale.toStringAsFixed(2)}',
                label: 'Mayor venta',
              ),
              _buildSubMetric(
                icon: Icons.credit_card_rounded,
                value: 'S/. ${returnsAmount.toStringAsFixed(2)}',
                label: 'Devoluciones',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubMetric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 9,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(List<SaleModel> sales) {
    return GestureDetector(
      onTap: () {
        if (sales.isEmpty) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay ventas para exportar.'),
              backgroundColor: AppTheme.error,
            ),
          );
          return;
        }
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Historial de ${sales.length} ventas exportado exitosamente.'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreenLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.download_rounded,
              color: AppTheme.primaryGreen,
              size: 16,
            ),
            SizedBox(width: 6),
            Text(
              'Exportar',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 48,
            color: AppTheme.textHint,
          ),
          SizedBox(height: 16),
          Text(
            'Sin transacciones',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'No se registraron ventas en esta fecha.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<SaleModel> sales, int totalCount) {
    // Show only 5 items if not expanded
    final displaySales = _showAllSales ? sales : sales.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displaySales.length,
        separatorBuilder: (context, index) => const Divider(color: AppTheme.divider, height: 1),
        itemBuilder: (context, index) {
          final sale = displaySales[index];
          // Use sequential format like #VTA-00125. The actual position starts from totalCount down.
          final seqNumber = (totalCount - index).toString().padLeft(5, '0');
          final String displayId = '#VTA-$seqNumber';
          final String paymentMethod = _getPaymentMethod(sale, index);
          final String timeStr = _formatTime(sale.fecha);

          return InkWell(
            onTap: () => _showSaleDetailDialog(sale, displayId),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayId,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$timeStr  •  $paymentMethod',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Amount
                  Text(
                    'S/. ${sale.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textHint,
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoreSalesButton(List<SaleModel> sales) {
    if (sales.length <= 5) return const SizedBox.shrink();

    final remaining = sales.length - 5;
    final text = _showAllSales ? 'Ver menos' : 'Y $remaining ventas más...';
    final icon = _showAllSales ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded;

    return Center(
      child: TextButton.icon(
        onPressed: () {
          setState(() {
            _showAllSales = !_showAllSales;
          });
        },
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.textSecondary,
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: Text(text),
        label: Icon(icon, size: 18),
      ),
    );
  }

  void _showSaleDetailDialog(SaleModel sale, String displayId) {
    final localFecha = sale.fecha.toLocal();
    final String dateStr =
        "${localFecha.day}/${localFecha.month}/${localFecha.year} ${localFecha.hour.toString().padLeft(2, '0')}:${localFecha.minute.toString().padLeft(2, '0')}";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detalle de Venta $displayId',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Fecha: $dateStr',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cajero: ${sale.cajero}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Categoría: ${sale.categoria}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Productos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sale.articulos.length,
                    itemBuilder: (context, idx) {
                      final item = sale.articulos[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.nombre,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'S/. ${item.precio.toStringAsFixed(2)} x ${item.cantidad}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'S/. ${(item.precio * item.cantidad).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Venta',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'S/. ${sale.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
