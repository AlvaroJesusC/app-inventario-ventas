import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/product_model.dart';
import '../../../services/product_service.dart';
import '../../../widgets/product_card.dart';
import '../../../widgets/inventory_filter_bottom_sheet.dart';
import '../../inventory/add_product_screen.dart';
import '../../inventory/category_management_screen.dart';
import '../home_screen.dart';

/// Tab de Inventario — vista completa con búsqueda, filtros y lista de productos
/// Conectada a Cloud Firestore en tiempo real
class InventoryTab extends StatefulWidget {
  const InventoryTab({super.key});

  @override
  State<InventoryTab> createState() => InventoryTabState();
}

class InventoryTabState extends State<InventoryTab>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _productService = ProductService();
  String _searchQuery = '';

  // Filter & Sort State
  String? _selectedCategoryFilter;
  StockFilter _selectedStockFilter = StockFilter.all;
  String _priceSortOrder = 'none'; // 'none', 'asc', 'desc'

  void applyStockFilter(StockFilter filter) {
    setState(() {
      _selectedStockFilter = filter;
    });
  }

  late AnimationController _animationController;
  late Animation<double> _item1Animation;
  late Animation<double> _item2Animation;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // Reconstruye el árbol al terminar la animación para retirar el overlay invisible de la pantalla
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() {});
      }
    });

    // Animaciones escalonadas para las opciones del Speed Dial
    _item1Animation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
    );
    _item2Animation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    var filtered = products;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        final nameMatches = p.nombre.toLowerCase().contains(query);
        final skuMatches =
            p.sku.toLowerCase().contains(query) ||
            (p.codigoBarras?.toLowerCase().contains(query) ?? false);
        final categoryMatches =
            p.categoria?.toLowerCase().contains(query) ?? false;
        final idMatches = p.id.toLowerCase().contains(query);

        return nameMatches || skuMatches || categoryMatches || idMatches;
      }).toList();
    }

    if (_selectedCategoryFilter != null) {
      filtered = filtered
          .where((p) => p.categoria == _selectedCategoryFilter)
          .toList();
    }

    switch (_selectedStockFilter) {
      case StockFilter.all:
        break;
      case StockFilter.inStock:
        filtered = filtered.where((p) => p.stockStatus == StockStatus.inStock).toList();
        break;
      case StockFilter.low:
        filtered = filtered.where((p) => p.stockStatus == StockStatus.low).toList();
        break;
      case StockFilter.empty:
        filtered = filtered.where((p) => p.stockStatus == StockStatus.empty).toList();
        break;
      case StockFilter.critical:
        filtered = filtered.where((p) => p.stockStatus == StockStatus.low || p.stockStatus == StockStatus.empty).toList();
        break;
    }

    if (_selectedStockFilter == StockFilter.critical) {
      filtered.sort((a, b) {
        final aVal = a.stockStatus == StockStatus.empty ? 0 : 1;
        final bVal = b.stockStatus == StockStatus.empty ? 0 : 1;
        if (aVal != bVal) {
          return aVal.compareTo(bVal);
        }
        if (_priceSortOrder == 'asc') {
          return a.precio.compareTo(b.precio);
        } else if (_priceSortOrder == 'desc') {
          return b.precio.compareTo(a.precio);
        }
        return a.stock.compareTo(b.stock);
      });
    } else if (_priceSortOrder != 'none') {
      filtered.sort((a, b) {
        if (_priceSortOrder == 'asc') {
          return a.precio.compareTo(b.precio);
        } else {
          return b.precio.compareTo(a.precio);
        }
      });
    }

    return filtered;
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isMenuOpen,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_isMenuOpen) {
          _toggleMenu();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              // ── Contenido principal: lee de Firestore en tiempo real ──
              Expanded(
                child: StreamBuilder<List<ProductModel>>(
                  stream: _productService.getProductsStream(),
                  builder: (context, snapshot) {
                    // Estado de carga SOLO en la carga inicial (sin datos previos)
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return Column(
                        children: [
                          _buildSectionHeader(
                            total: 0,
                            showing: 0,
                            allProducts: [],
                          ),
                          _buildSearchBar(),
                          const Expanded(
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryGreen,
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    // Error
                    if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    }

                    // Obtener productos y filtrar
                    final allProducts = snapshot.data ?? [];
                    final filteredProducts = _filterProducts(allProducts);

                    return Column(
                      children: [
                        // ── Título de sección + conteo + filtro ──
                        _buildSectionHeader(
                          total: allProducts.length,
                          showing: filteredProducts.length,
                          allProducts: allProducts,
                        ),

                        // ── Barra de búsqueda ──
                        _buildSearchBar(),

                        // ── Lista o estado vacío ──
                        Expanded(
                          child: filteredProducts.isEmpty
                              ? _buildEmptyState(
                                  hasProducts: allProducts.isNotEmpty,
                                )
                              : _buildProductList(filteredProducts),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          // 1. Overlay de fondo oscuro semitransparente (solo interactivo si se muestra)
          if (!_animationController.isDismissed)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleMenu,
                behavior: HitTestBehavior.opaque,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Container(
                      color: Colors.black.withOpacity(
                        0.4 * _animationController.value,
                      ),
                    );
                  },
                ),
              ),
            ),

          // 2. Menú flotante con las opciones
          if (!_animationController.isDismissed)
            Positioned(
              right: 20,
              bottom: 92, // Posición por encima del FAB principal
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildSpeedDialItem(
                    label: 'Añadir Categoría',
                    icon: Icons.category_outlined,
                    color: Colors.blue.shade600,
                    onTap: () {
                      _toggleMenu();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const CategoryManagementScreen(),
                        ),
                      );
                    },
                    animation: _item1Animation,
                  ),
                  const SizedBox(height: 16),
                  _buildSpeedDialItem(
                    label: 'Añadir Producto',
                    icon: Icons.inventory_2_outlined,
                    color: AppTheme.primaryGreen,
                    onTap: () {
                      _toggleMenu();
                      final homeState = HomeScreen.of(context);
                      if (homeState != null) {
                        homeState.showAddProduct();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddProductScreen(),
                          ),
                        );
                      }
                    },
                    animation: _item2Animation,
                  ),
                ],
              ),
            ),

          // 3. Botón Flotante Principal (FAB)
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              heroTag: "speed_dial_main",
              onPressed: _toggleMenu,
              backgroundColor: AppTheme.primaryGreen,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle:
                        _animationController.value *
                        (3 *
                            3.141592653589793 /
                            4), // Rota 135 grados para formar la 'X'
                    child: Icon(
                      _animationController.value > 0.5
                          ? Icons.close_rounded
                          : Icons.add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Barra de búsqueda con ícono de filtro/escanear
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(Icons.search_rounded, size: 22, color: AppTheme.textHint),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Buscar productos...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  hintStyle: TextStyle(fontSize: 14, color: AppTheme.textHint),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8), // Pequeño margen derecho para equilibrar
          ],
        ),
      ),
    );
  }

  /// Encabezado de sección: título "Inventario", conteo de items y botón de filtro
  Widget _buildSectionHeader({
    required int total,
    required int showing,
    required List<ProductModel> allProducts,
  }) {
    // Verificar si hay filtros activos
    final bool hasActiveFilters =
        _selectedCategoryFilter != null ||
        _selectedStockFilter != StockFilter.all ||
        _priceSortOrder != 'none';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inventario',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                _searchQuery.isNotEmpty || hasActiveFilters
                    ? '$showing de $total productos'
                    : '$total productos',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              // Botón de filtro
              GestureDetector(
                onTap: () => _showFilterBottomSheet(context, allProducts),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: hasActiveFilters
                        ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                        : AppTheme.primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasActiveFilters
                          ? AppTheme.primaryGreen.withValues(alpha: 0.5)
                          : AppTheme.primaryGreen.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Filtrar',
                        style: TextStyle(
                          fontSize: 14, // Más grande
                          fontWeight: FontWeight.w700, // Más grueso
                          color: hasActiveFilters
                              ? AppTheme.primaryGreen
                              : AppTheme.primaryGreen.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.tune_rounded,
                        size: 20, // Más grande
                        color: hasActiveFilters
                              ? AppTheme.primaryGreen
                              : AppTheme.primaryGreen.withValues(alpha: 0.8),
                      ),
                      if (hasActiveFilters) ...[
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(
    BuildContext context,
    List<ProductModel> allProducts,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return InventoryFilterBottomSheet(
          allProducts: allProducts,
          initialCategoryFilter: _selectedCategoryFilter,
          initialStockFilter: _selectedStockFilter,
          initialPriceSortOrder: _priceSortOrder,
          onApplyFilters: (category, stock, priceSort) {
            setState(() {
              _selectedCategoryFilter = category;
              _selectedStockFilter = stock;
              _priceSortOrder = priceSort;
            });
          },
        );
      },
    );
  }

  /// Lista de productos con scroll
  Widget _buildProductList(List<ProductModel> products) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () {
            // TODO: Navegar a detalle de producto
          },
          onEdit: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddProductScreen(product: product),
              ),
            );
          },
          onDelete: () => _confirmDeleteProduct(context, product),
        );
      },
    );
  }

  /// Diálogo para confirmar la eliminación de un producto
  void _confirmDeleteProduct(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Eliminar Producto',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            '¿Está seguro de que desea eliminar el producto "${product.nombre}"? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Cierra el diálogo
                try {
                  await _productService.deleteProduct(product.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Producto eliminado correctamente'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar el producto: $e'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(
                  color: AppTheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Estado vacío según contexto (sin productos o sin resultados de búsqueda)
  Widget _buildEmptyState({required bool hasProducts}) {
    // Si tiene productos pero la búsqueda no encontró nada
    final bool isSearching = hasProducts && _searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícono decorativo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreenLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : Icons.inventory_2_outlined,
                size: 48,
                color: AppTheme.primaryGreen.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isSearching ? 'Sin resultados' : 'Tu inventario está vacío',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'No se encontraron productos con "$_searchQuery"'
                  : 'Agrega tu primer producto para\nempezar a gestionar tu inventario',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            if (!isSearching) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final homeState = HomeScreen.of(context);
                    if (homeState != null) {
                      homeState.showAddProduct();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddProductScreen(),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Agregar producto'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 48),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Estado de error
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppTheme.error.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar productos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper widget para las opciones del Speed Dial
  Widget _buildSpeedDialItem({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required Animation<double> animation,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1.0 - animation.value) * 15.0),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
