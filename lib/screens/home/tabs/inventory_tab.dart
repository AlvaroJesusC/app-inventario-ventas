import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_constants.dart';
import '../../../models/product_model.dart';
import '../../../services/product_service.dart';
import '../../../widgets/product_card.dart';
import '../../inventory/add_product_screen.dart';
import '../../inventory/category_management_screen.dart';
import '../home_screen.dart';

/// Tab de Inventario — vista completa con búsqueda, filtros y lista de productos
/// Conectada a Cloud Firestore en tiempo real
class InventoryTab extends StatefulWidget {
  const InventoryTab({super.key});

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab> {
  final _searchController = TextEditingController();
  final _productService = ProductService();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    if (_searchQuery.isEmpty) return products;
    final query = _searchQuery.toLowerCase();
    return products.where((p) {
      final nameMatches = p.nombre.toLowerCase().contains(query);
      final skuMatches = p.codigoBarras?.toLowerCase().contains(query) ?? false;
      final categoryMatches =
          p.categoria?.toLowerCase().contains(query) ?? false;
      final idMatches = p.id.toLowerCase().contains(query);

      return nameMatches || skuMatches || categoryMatches || idMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Contenido principal: lee de Firestore en tiempo real ──
        Expanded(
          child: StreamBuilder<List<ProductModel>>(
            stream: _productService.getProductsStream(),
            builder: (context, snapshot) {
              // Estado de carga SOLO en la carga inicial (sin datos previos)
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return Column(
                  children: [
                    _buildSectionHeader(total: 0, showing: 0),
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
                  ),

                  // ── Barra de búsqueda ──
                  _buildSearchBar(),

                  // ── Lista o estado vacío ──
                  Expanded(
                    child: filteredProducts.isEmpty
                        ? _buildEmptyState(hasProducts: allProducts.isNotEmpty)
                        : _buildProductList(filteredProducts),
                  ),
                ],
              );
            },
          ),
        ),
      ],
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
  Widget _buildSectionHeader({required int total, required int showing}) {
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
                _searchQuery.isNotEmpty
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
                onTap: () {
                  // TODO: Implementar filtros (categoría, stock, precio)
                },
                child: Row(
                  children: [
                    Text(
                      'Filtrar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: Colors.blue.shade600,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Lista de productos con scroll
  Widget _buildProductList(List<ProductModel> products) {
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(
              product: products[index],
              onTap: () {
                // TODO: Navegar a detalle de producto
              },
            );
          },
        ),
        // FAB para agregar producto
        _buildAddButton(),
      ],
    );
  }

  /// Estado vacío según contexto (sin productos o sin resultados de búsqueda)
  Widget _buildEmptyState({required bool hasProducts}) {
    // Si tiene productos pero la búsqueda no encontró nada
    final bool isSearching = hasProducts && _searchQuery.isNotEmpty;

    return Stack(
      children: [
        Center(
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
        ),
        // FAB siempre visible
        _buildAddButton(),
      ],
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

  /// Botones flotantes (Añadir Producto y Categoría)
  Widget _buildAddButton() {
    return Positioned(
      right: 20,
      bottom: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Botón Añadir Categoría
          FloatingActionButton.extended(
            heroTag: "btn_add_category",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoryManagementScreen()),
              );
            },
            backgroundColor: AppTheme.white,
            foregroundColor: AppTheme.primaryGreen,
            icon: const Icon(Icons.category_outlined, size: 20),
            label: const Text('Añadir Categoría', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          // Botón Añadir Producto
          FloatingActionButton.extended(
            heroTag: "btn_add_product",
            onPressed: () {
              final homeState = HomeScreen.of(context);
              if (homeState != null) {
                homeState.showAddProduct();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddProductScreen()),
                );
              }
            },
            backgroundColor: AppTheme.primaryGreen,
            icon: const Icon(Icons.add_rounded, size: 24, color: AppTheme.white),
            label: const Text('Añadir Producto', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
