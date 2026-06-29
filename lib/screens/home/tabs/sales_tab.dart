import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../home_screen.dart';
import '../../sales/new_sale_screen.dart';
import '../../../services/sale_service.dart';
import '../../../models/sale_model.dart';

class SalesTab extends StatefulWidget {
  const SalesTab({super.key});

  @override
  State<SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends State<SalesTab> {
  String _selectedFilter = 'Esta semana';

  final List<String> _filters = ['Esta semana', 'Mes', 'Hoy'];
  DateTime? _selectedCustomDate;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SaleModel>>(
      stream: SaleService().getSalesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint("Error loading sales: ${snapshot.error}");
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                'Error cargando ventas: ${snapshot.error}',
                style: const TextStyle(color: AppTheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final allSales = snapshot.data ?? [];

        // Lógica de filtrado
        final now = DateTime.now();
        List<SaleModel> filteredSales = allSales.where((sale) {
          final saleLocal = sale.fecha.toLocal();
          if (_selectedFilter == 'Hoy') {
            return saleLocal.year == now.year &&
                saleLocal.month == now.month &&
                saleLocal.day == now.day;
          } else if (_selectedFilter == 'Esta semana') {
            final difference = now.difference(saleLocal).inDays;
            return difference >= 0 && difference < 7;
          } else if (_selectedFilter == 'Mes') {
            return saleLocal.year == now.year && saleLocal.month == now.month;
          } else if (_selectedFilter == 'custom' &&
              _selectedCustomDate != null) {
            return saleLocal.year == _selectedCustomDate!.year &&
                saleLocal.month == _selectedCustomDate!.month &&
                saleLocal.day == _selectedCustomDate!.day;
          }
          return true;
        }).toList();

        final double totalSalesAmount = filteredSales.fold(
          0.0,
          (sum, s) => sum + s.total,
        );
        final int totalTransactions = filteredSales.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 80,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Título y Subtítulo ──
              const Text(
                'Ventas',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Resumen de transacciones y operaciones.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),

              // ── Botón Nueva Venta ──
              _buildNewSaleButton(),
              const SizedBox(height: 24),

              // ── Tarjeta de Resumen ──
              _buildSummaryCard(totalSalesAmount, totalTransactions),
              const SizedBox(height: 24),

              // ── Filtros de Fecha ──
              _buildFiltersRow(),
              const SizedBox(height: 24),

              // ── Historial de Ventas Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Historial de Ventas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Row(
                      children: [
                        Text(
                          'Ver reporte completo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: Colors.blue.shade600,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Lista de Transacciones ──
              filteredSales.isEmpty
                  ? _buildEmptyState()
                  : Container(
                      decoration: BoxDecoration(
                        color: AppTheme.white,
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
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredSales.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: AppTheme.divider),
                        itemBuilder: (context, index) {
                          return _buildTransactionItem(filteredSales[index]);
                        },
                      ),
                    ),
              const SizedBox(height: 16),

              // ── Botón Ver todas ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: AppTheme.white,
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ver todas las transacciones',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Colors.blue.shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewSaleButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final homeState = HomeScreen.of(context);
            if (homeState != null) {
              homeState.showNewSale();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NewSaleScreen()),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: AppTheme.primaryGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nueva Venta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Registrar transacción rápida',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppTheme.primaryGreen,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double totalAmount, int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Ventas Columna
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL VENTAS (FILTRADO)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'S/. ${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundGrey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.remove_rounded,
                            size: 10,
                            color: AppTheme.textHint,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '0.0%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'vs ayer',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divisor vertical
          Container(
            height: 70,
            width: 1,
            color: AppTheme.divider,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),

          // Stats Adicionales
          Expanded(
            flex: 4,
            child: Row(
              children: [
                // Transacciones
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          size: 16,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Transacciones',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Empleados
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: 16,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '1',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Empleados activos',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Row(
      children: [
        const Text(
          'Fecha:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._filters.map((filter) => _buildFilterChip(filter)),
                if (_selectedCustomDate != null) _buildFilterChip('custom'),
                _buildCalendarButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarButton() {
    final bool isCustomSelected = _selectedFilter == 'custom';
    return GestureDetector(
      onTap: _selectCustomDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isCustomSelected ? Colors.blue.shade50 : AppTheme.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCustomSelected ? Colors.blue.shade300 : AppTheme.divider,
            width: isCustomSelected ? 1.5 : 1,
          ),
        ),
        child: Icon(
          Icons.calendar_today_rounded,
          size: 16,
          color: isCustomSelected
              ? Colors.blue.shade700
              : AppTheme.textSecondary,
        ),
      ),
    );
  }

  Future<void> _selectCustomDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedCustomDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade600,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedCustomDate = picked;
        _selectedFilter = 'custom';
      });
    }
  }

  Widget _buildFilterChip(String label) {
    final String displayLabel = label == 'custom' && _selectedCustomDate != null
        ? "${_selectedCustomDate!.day.toString().padLeft(2, '0')}/${_selectedCustomDate!.month.toString().padLeft(2, '0')}/${_selectedCustomDate!.year}"
        : label;

    final bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : AppTheme.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue.shade300 : AppTheme.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.blue.shade700 : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  String _formatSaleDate(DateTime date) {
    final localDate = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final saleDay = DateTime(localDate.year, localDate.month, localDate.day);

    String dateStr;
    if (saleDay == today) {
      dateStr = "Hoy";
    } else if (saleDay == yesterday) {
      dateStr = "Ayer";
    } else {
      dateStr =
          "${localDate.day.toString().padLeft(2, '0')}/${localDate.month.toString().padLeft(2, '0')}/${localDate.year}";
    }

    final hours = localDate.hour.toString().padLeft(2, '0');
    final minutes = localDate.minute.toString().padLeft(2, '0');
    return "$dateStr, $hours:$minutes";
  }

  Widget _buildTransactionItem(SaleModel sale) {
    // 1. Determinar título con nombre de producto
    String titleText = "Sin productos";
    if (sale.articulos.isNotEmpty) {
      if (sale.articulos.length == 1) {
        titleText = "${sale.articulos.first.nombre} (x${sale.articulos.first.cantidad})";
      } else {
        titleText = "${sale.articulos.first.nombre} y ${sale.articulos.length - 1} prod.";
      }
    }

    // 2. Determinar subtítulo con fecha formateada y cajero
    final String subtitleText =
        "${_formatSaleDate(sale.fecha)} • ${sale.cajero}";

    return InkWell(
      onTap: () {
        _showSaleDetailDialog(sale);
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icono Izquierdo
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                color: AppTheme.primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),

            // Textos Centrales
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Monto y Cantidad
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'S/. ${sale.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${sale.totalArticulos} und.',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Flecha
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showSaleDetailDialog(SaleModel sale) {
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
                    const Text(
                      'Detalle de Venta',
                      style: TextStyle(
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
                                    '${item.cantidad} x S/. ${item.precio.toStringAsFixed(2)}',
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
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total General',
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGrey,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: AppTheme.textHint,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin transacciones aún',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Registra tu primera venta para ver el historial.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
