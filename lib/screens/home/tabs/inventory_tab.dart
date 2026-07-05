import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/product_model.dart';
import '../../../models/purchase_model.dart';
import '../../../services/product_service.dart';
import '../../../services/purchase_service.dart';
import '../../../widgets/product_card.dart';
import '../../../widgets/inventory_filter_bottom_sheet.dart';
import '../../inventory/add_product_screen.dart';
import '../../inventory/category_management_screen.dart';
import '../../inventory/new_purchase_screen.dart';
import '../home_screen.dart';

/// Tab de Inventario — vista con sub-navegación entre [Productos] y [Compras]
/// Conectada a Cloud Firestore en tiempo real
class InventoryTab extends StatefulWidget {
  const InventoryTab({super.key});

  @override
  State<InventoryTab> createState() => InventoryTabState();
}

class InventoryTabState extends State<InventoryTab>
    with SingleTickerProviderStateMixin {
  // 0: Productos, 1: Compras
  int _selectedSubTab = 0;

  final _searchController = TextEditingController();
  final _productService = ProductService();
  final _purchaseService = PurchaseService();
  String _searchQuery = '';

  // Filter & Sort State
  String? _selectedCategoryFilter;
  StockFilter _selectedStockFilter = StockFilter.all;
  String _priceSortOrder = 'none'; // 'none', 'asc', 'desc'

  void applyStockFilter(StockFilter filter) {
    setState(() {
      _selectedSubTab = 0; // Cambiar a la pestaña productos si entra por filtro
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

    _animationController.addListener(() {
      setState(() {});
    });

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() {});
      }
    });

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

  void _navigateToNewPurchase() {
    final homeState = HomeScreen.of(context);
    if (homeState != null) {
      homeState.showNewPurchase();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NewPurchaseScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isMenuOpen,
      onPopInvokedWithResult: (didPop, result) {
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
              Expanded(
                child: _selectedSubTab == 0
                    ? _buildProductsView()
                    : _buildPurchasesView(),
              ),
            ],
          ),

          // Speed dial solo visible en la pestaña Productos cuando está abierto o en animación
          if (_selectedSubTab == 0 && (_isMenuOpen || _animationController.value > 0))
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleMenu,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: Colors.black.withValues(
                    alpha: 0.4 * _animationController.value,
                  ),
                ),
              ),
            ),

          if (_selectedSubTab == 0 && (_isMenuOpen || _animationController.value > 0))
            Positioned(
              right: 20,
              bottom: 92,
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

          if (_selectedSubTab == 0)
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
                      angle: _animationController.value *
                          (3 * 3.141592653589793 / 4),
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

  // ── PESTAÑA 1: PRODUCTOS ───────────────────────────────
  Widget _buildProductsView() {
    return StreamBuilder<List<ProductModel>>(
      stream: _productService.getProductsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Column(
            children: [
              _buildMainHeader(productCount: 0),
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

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final allProducts = snapshot.data ?? [];
        final filteredProducts = _filterProducts(allProducts);

        return Column(
          children: [
            _buildMainHeader(
              productCount: allProducts.length,
              showingCount: filteredProducts.length,
              allProducts: allProducts,
            ),
            _buildSearchBar(),
            Expanded(
              child: filteredProducts.isEmpty
                  ? _buildEmptyState(hasProducts: allProducts.isNotEmpty)
                  : _buildProductList(filteredProducts),
            ),
          ],
        );
      },
    );
  }

  // ── PESTAÑA 2: COMPRAS (IMAGE 2) ───────────────────────
  Widget _buildPurchasesView() {
    return StreamBuilder<List<PurchaseModel>>(
      stream: _purchaseService.getPurchasesStream(),
      builder: (context, snapshot) {
        final purchases = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainHeader(
              productCount: purchases.length,
              isPurchasesTab: true,
            ),

            // Botón "+ Nueva Compra" a la derecha (según Imagen 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _navigateToNewPurchase,
                    icon: const Icon(Icons.add_rounded, color: AppTheme.primaryGreen, size: 20),
                    label: const Text(
                      'Nueva Compra',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lista de Compras
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                    )
                  : purchases.isEmpty
                      ? _buildEmptyPurchasesState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                          itemCount: purchases.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                          itemBuilder: (ctx, index) {
                            final purchase = purchases[index];
                            return _buildPurchaseCard(purchase);
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  // ── ENCABEZADO PRINCIPAL CON TAB SELECTOR [Productos | Compras] ──
  Widget _buildMainHeader({
    required int productCount,
    int? showingCount,
    List<ProductModel>? allProducts,
    bool isPurchasesTab = false,
  }) {
    final bool hasActiveFilters =
        _selectedCategoryFilter != null ||
        _selectedStockFilter != StockFilter.all ||
        _priceSortOrder != 'none';

    final countText = isPurchasesTab
        ? '$productCount compras'
        : (_searchQuery.isNotEmpty || hasActiveFilters)
            ? '${showingCount ?? 0} de $productCount productos'
            : '$productCount productos';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fila de Título + Conteo + Botón Filtrar (arriba en el espacio vacío) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
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
                  const SizedBox(height: 2),
                  Text(
                    countText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (!isPurchasesTab && allProducts != null)
                GestureDetector(
                  onTap: () => _showFilterBottomSheet(context, allProducts),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: hasActiveFilters
                          ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                          : AppTheme.primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasActiveFilters
                            ? AppTheme.primaryGreen.withValues(alpha: 0.5)
                            : AppTheme.primaryGreen.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Filtrar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: hasActiveFilters
                                ? AppTheme.primaryGreen
                                : AppTheme.primaryGreen.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: hasActiveFilters
                              ? AppTheme.primaryGreen
                              : AppTheme.primaryGreen.withValues(alpha: 0.8),
                        ),
                        if (hasActiveFilters) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
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

          const SizedBox(height: 14),

          // ── SEGMENTED TOGGLE (Sub-tabs [Productos] | [Compras]) a Ancho Completo ──
          Container(
            height: 48,
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // Sub-tab 1: Productos
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSubTab = 0;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _selectedSubTab == 0
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedSubTab == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Productos',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _selectedSubTab == 0
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _selectedSubTab == 0
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),

                // Sub-tab 2: Compras
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSubTab = 1;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _selectedSubTab == 1
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedSubTab == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Compras',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _selectedSubTab == 1
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _selectedSubTab == 1
                              ? AppTheme.primaryGreen
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TARJETA DE COMPRA (RECREADA SEGÚN LA IMAGEN 2) ──
  Widget _buildPurchaseCard(PurchaseModel purchase) {
    // Formato de fecha corto (ej: 28 Jun 2026)
    final dateStr = '${purchase.fecha.day} ${_getMonthAbbr(purchase.fecha.month)} ${purchase.fecha.year}';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Barra acentuada verde en el borde izquierdo (Image 2)
              Container(
                width: 5,
                color: AppTheme.primaryGreen,
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fila Superior: Nombre Proveedor, Fecha, Menú
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              purchase.proveedor,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppTheme.textSecondary),
                            onSelected: (val) {
                              if (val == 'delete') {
                                _purchaseService.deletePurchase(purchase.id);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Eliminar registro'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Fila Central: Subtítulo (ej. 3 productos · 120 unidades)
                      Text(
                        '${purchase.totalProductos} productos · ${purchase.unidadesLabel}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Fila Inferior: Total en Soles (ej: S/. 340.00)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'S/. ${purchase.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Set', 'Oct', 'Nov', 'Dic'];
    return months[(month - 1) % 12];
  }

  Widget _buildEmptyPurchasesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreenLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 44,
              color: AppTheme.primaryGreen.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay compras registradas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Registra compras para abastecer tu inventario automáticamente',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── OTROS WIDGETS AUXILIARES ──
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
            const Icon(Icons.search_rounded, size: 22, color: AppTheme.textHint),
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
            const SizedBox(width: 8),
          ],
        ),
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

  Widget _buildProductList(List<ProductModel> products) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () {},
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
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                try {
                  await _productService.deleteProduct(product.id);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Producto eliminado correctamente'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar el producto: $e'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
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

  Widget _buildEmptyState({required bool hasProducts}) {
    final bool isSearching = hasProducts && _searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
              'Error al cargar datos',
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
                    color: Colors.black.withValues(alpha: 0.12),
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
                    color: color.withValues(alpha: 0.3),
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
