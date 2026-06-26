import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/product_model.dart';

class InventoryFilterBottomSheet extends StatefulWidget {
  final List<ProductModel> allProducts;
  final String? initialCategoryFilter;
  final StockFilter initialStockFilter;
  final String initialPriceSortOrder;
  final Function(String?, StockFilter, String) onApplyFilters;

  const InventoryFilterBottomSheet({
    super.key,
    required this.allProducts,
    this.initialCategoryFilter,
    required this.initialStockFilter,
    required this.initialPriceSortOrder,
    required this.onApplyFilters,
  });

  @override
  State<InventoryFilterBottomSheet> createState() => _InventoryFilterBottomSheetState();
}

class _InventoryFilterBottomSheetState extends State<InventoryFilterBottomSheet> {
  String? _selectedCategoryFilter;
  StockFilter _selectedStockFilter = StockFilter.all;
  String _priceSortOrder = 'none';
  late final List<String> _categories;

  @override
  void initState() {
    super.initState();
    _selectedCategoryFilter = widget.initialCategoryFilter;
    _selectedStockFilter = widget.initialStockFilter;
    _priceSortOrder = widget.initialPriceSortOrder;

    // Extraer categorías únicas de los productos actuales una sola vez al inicializar
    _categories = widget.allProducts
        .map((p) => p.categoria)
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
        ..sort();
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategoryFilter = null;
                      _selectedStockFilter = StockFilter.all;
                      _priceSortOrder = 'none';
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepOrange.shade600,
                    backgroundColor: Colors.deepOrange.shade50,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: const Size(60, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.deepOrange.shade200, width: 1),
                    ),
                  ),
                  child: const Text(
                    'Limpiar',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppTheme.divider),
          
          // Contenido scrollable
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Ordenar por Precio
                const Text(
                  'Ordenar por Precio',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildChoiceChip(
                      label: 'Sin orden',
                      isSelected: _priceSortOrder == 'none',
                      onSelected: (val) => setState(() => _priceSortOrder = 'none'),
                    ),
                    _buildChoiceChip(
                      label: 'Mayor a menor',
                      isSelected: _priceSortOrder == 'desc',
                      onSelected: (val) => setState(() => _priceSortOrder = 'desc'),
                      icon: Icons.arrow_downward_rounded,
                    ),
                    _buildChoiceChip(
                      label: 'Menor a mayor',
                      isSelected: _priceSortOrder == 'asc',
                      onSelected: (val) => setState(() => _priceSortOrder = 'asc'),
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Filtrar por Stock
                const Text(
                  'Estado de Stock',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildChoiceChip(
                      label: 'Todos',
                      isSelected: _selectedStockFilter == StockFilter.all,
                      onSelected: (val) => setState(() => _selectedStockFilter = StockFilter.all),
                    ),
                    _buildChoiceChip(
                      label: 'En Stock',
                      isSelected: _selectedStockFilter == StockFilter.inStock,
                      onSelected: (val) => setState(() => _selectedStockFilter = StockFilter.inStock),
                    ),
                    _buildChoiceChip(
                      label: 'Stock Bajo',
                      isSelected: _selectedStockFilter == StockFilter.low,
                      onSelected: (val) => setState(() => _selectedStockFilter = StockFilter.low),
                    ),
                    _buildChoiceChip(
                      label: 'Agotado',
                      isSelected: _selectedStockFilter == StockFilter.empty,
                      onSelected: (val) => setState(() => _selectedStockFilter = StockFilter.empty),
                    ),
                    _buildChoiceChip(
                      label: 'Crítico',
                      isSelected: _selectedStockFilter == StockFilter.critical,
                      onSelected: (val) => setState(() => _selectedStockFilter = StockFilter.critical),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Filtrar por Categoría
                const Text(
                  'Categoría',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildChoiceChip(
                      label: 'Todas',
                      isSelected: _selectedCategoryFilter == null,
                      onSelected: (val) => setState(() => _selectedCategoryFilter = null),
                    ),
                    ..._categories.map((cat) => _buildChoiceChip(
                      label: cat,
                      isSelected: _selectedCategoryFilter == cat,
                      onSelected: (val) => setState(() => _selectedCategoryFilter = cat),
                    )),
                  ],
                ),
                const SizedBox(height: 40), // Espacio extra al final
              ],
            ),
          ),
          
          // Botón Aplicar
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: () {
                widget.onApplyFilters(
                  _selectedCategoryFilter,
                  _selectedStockFilter,
                  _priceSortOrder,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Ver Resultados',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
    IconData? icon,
  }) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.blue.shade700 : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: Colors.blue.shade50,
      backgroundColor: AppTheme.backgroundGrey,
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? Colors.blue.shade700 : AppTheme.textPrimary,
      ),
      side: BorderSide(
        color: isSelected ? Colors.blue.shade200 : AppTheme.divider,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      showCheckmark: false,
    );
  }
}
