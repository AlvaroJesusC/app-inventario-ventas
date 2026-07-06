import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../config/app_theme.dart';
import '../../models/product_model.dart';
import '../../models/sale_model.dart';
import '../../services/product_service.dart';
import '../../services/sale_service.dart';
import '../home/home_screen.dart';
import 'checkout_screen.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final ProductService _productService = ProductService();
  bool _isProcessing = false;

  // modo demo
  final bool _isDemoMode = true;

  // lista de productos escaneados
  final List<Map<String, dynamic>> _scannedItems = [];

  // buscador
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<ProductModel> _allProducts = [];
  List<SaleModel> _allSales = [];
  List<ProductModel> _topSoldProducts = [];
  StreamSubscription<List<ProductModel>>? _productsSubscription;
  StreamSubscription<List<SaleModel>>? _salesSubscription;

  @override
  void initState() {
    super.initState();
    _productsSubscription = _productService.getProductsStream().listen((
      products,
    ) {
      if (mounted) {
        setState(() {
          _allProducts = products;
          _updateTopSoldProducts();
        });
      }
    });

    _salesSubscription = SaleService().getSalesStream().listen((sales) {
      if (mounted) {
        setState(() {
          _allSales = sales;
          _updateTopSoldProducts();
        });
      }
    });
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    _salesSubscription?.cancel();
    _searchController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _updateTopSoldProducts() {
    if (_allProducts.isEmpty) return;

    if (_allSales.isEmpty) {
      setState(() {
        _topSoldProducts = _allProducts.take(3).toList();
      });
      return;
    }

    final Map<String, int> productSalesCounts = {};
    for (var sale in _allSales) {
      for (var item in sale.articulos) {
        productSalesCounts[item.id] =
            (productSalesCounts[item.id] ?? 0) + item.cantidad;
      }
    }

    final sortedProducts = List<ProductModel>.from(_allProducts);
    sortedProducts.sort((a, b) {
      final countA = productSalesCounts[a.id] ?? 0;
      final countB = productSalesCounts[b.id] ?? 0;
      return countB.compareTo(countA);
    });

    setState(() {
      _topSoldProducts = sortedProducts.take(3).toList();
    });
  }

  void _handleBack() {
    final homeState = HomeScreen.of(context);
    if (homeState != null) {
      homeState.hideNewSale();
    } else {
      Navigator.pop(context);
    }
  }

  void _onDetectBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? barcode = barcodes.first.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      // revisar si ya está en el carrito
      int index = _scannedItems.indexWhere((item) => item['sku'] == barcode);
      if (index >= 0) {
        setState(() {
          _scannedItems[index]['quantity']++;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cantidad de ${_scannedItems[index]['name']} aumentada',
              ),
              backgroundColor: AppTheme.primaryGreen,
              duration: const Duration(milliseconds: 800),
            ),
          );
        }
      } else {
        // buscar en Firestore
        final product = await _productService.getProductByBarcode(barcode);

        if (product != null) {
          _addProductToCart(product);
        } else {
          // mostrar advertencia si no está en laa BD
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            final snackBarController = ScaffoldMessenger.of(context)
                .showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Producto no encontrado en inventario ($barcode)',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.redAccent.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'CERRAR',
                      textColor: Colors.white,
                      onPressed: () {
                        ScaffoldMessenger.of(context).clearSnackBars();
                      },
                    ),
                  ),
                );
            await snackBarController.closed;
          }
        }
      }
    } finally {
      // pequeña pausa para no escanear el mismo código múltiples veces seguidas muy rápido
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _addProductToCart(ProductModel product) {
    int index = _scannedItems.indexWhere((item) => item['id'] == product.id);
    if (index >= 0) {
      setState(() {
        _scannedItems[index]['quantity']++;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cantidad de ${_scannedItems[index]['name']} aumentada',
            ),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
    } else {
      setState(() {
        _scannedItems.add({
          'id': product.id,
          'name': product.nombre,
          'sku': product.sku,
          'price': product.precio,
          'quantity': 1,
          'image': Icons.inventory_2_rounded,
          'category': product.categoria ?? 'General',
        });
      });
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.nombre} agregado al ticket'),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
    }
  }

  Widget _buildSearchBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppTheme.textHint,
                ),
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
                      hintText: 'Buscar por nombre...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textHint,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.clear_rounded,
                        size: 18,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 24, right: 24, bottom: 8),
          child: Text(
            'Alternativo al escáner. Se usa solo cuando el código de barras no puede escanearse.',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) return const SizedBox.shrink();

    final query = _searchQuery.toLowerCase();
    final matchedProducts = _allProducts.where((p) {
      final nameMatches = p.nombre.toLowerCase().contains(query);
      final skuMatches = p.sku.toLowerCase().contains(query);
      final barcodeMatches =
          p.codigoBarras?.toLowerCase().contains(query) ?? false;
      return nameMatches || skuMatches || barcodeMatches;
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: matchedProducts.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No se encontraron productos por ese nombre',
                  style: TextStyle(color: AppTheme.textHint, fontSize: 13),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: matchedProducts.length > 5
                  ? 5
                  : matchedProducts.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: AppTheme.divider),
              itemBuilder: (context, index) {
                final product = matchedProducts[index];
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: AppTheme.textHint,
                      size: 16,
                    ),
                  ),
                  title: Text(
                    product.nombre,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    product.categoria ?? 'Sin categoría',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  trailing: Text(
                    'S/. ${product.precio.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  onTap: () {
                    _addProductToCart(product);
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                );
              },
            ),
    );
  }

  double get _totalPrice {
    return _scannedItems.fold(
      0.0,
      (sum, item) => sum + (item['price'] * item['quantity']),
    );
  }

  int get _totalItems {
    return _scannedItems.fold(
      0,
      (sum, item) => sum + (item['quantity'] as int),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildScannerBox(),
                    _buildSearchBar(),
                    if (_searchQuery.isEmpty) _buildMostSoldProducts(),
                    _buildSearchResults(),
                    _buildScannedList(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _handleBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
            ),
          ),
          const Text(
            'Escanear Productos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.question_mark_rounded,
              color: AppTheme.primaryGreen,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      height: 115,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onDetectBarcode,
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: ScannerCornersPainter(
                color: AppTheme.primaryGreen,
                strokeWidth: 3.0,
                cornerLength: 16.0,
                borderRadius: 16.0,
              ),
            ),
          ),
          // Línea láser verde horizontal
          Container(
            height: 2,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.8),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Productos escaneados (${_scannedItems.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _scannedItems.clear();
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Vaciar todo',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_scannedItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Escanea productos para agregarlos al ticket',
                  style: TextStyle(color: AppTheme.textHint, fontSize: 14),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _scannedItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _scannedItems[index];
                return _buildProductItem(item);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Borde verde izquierdo
            Container(width: 4, color: AppTheme.primaryGreen),
            // Imagen
            Container(
              width: 72,
              height: 72,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item['image'], color: AppTheme.textHint, size: 32),
            ),
            // Detalles
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12, right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['name'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SKU: ${item['sku']}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'S/. ${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        // Selector de cantidad
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundGrey,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (item['quantity'] > 1) {
                                    setState(() => item['quantity']--);
                                  }
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  child: Icon(
                                    Icons.remove_rounded,
                                    size: 16,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                '${item['quantity']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() => item['quantity']++);
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    size: 16,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Botón de eliminar (ícono de basurero en rojo) al extremo derecho
            GestureDetector(
              onTap: () {
                setState(() {
                  _scannedItems.remove(item);
                });
              },
              child: Container(
                width: 52,
                decoration: BoxDecoration(
                  color: Colors.red.shade50.withValues(alpha: 0.8),
                  border: const Border(
                    left: BorderSide(color: AppTheme.divider, width: 1),
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: AppTheme.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_totalItems productos',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Total estimado',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'S/. ${_totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: (_scannedItems.isEmpty && !_isDemoMode)
                    ? null
                    : () async {
                        final updatedItems =
                            await Navigator.push<List<Map<String, dynamic>>>(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CheckoutScreen(scannedItems: _scannedItems),
                              ),
                            );

                        if (updatedItems != null) {
                          setState(() {
                            _scannedItems.clear();
                            _scannedItems.addAll(updatedItems);
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryGreen,
                  elevation: 0,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  children: [
                    Text(
                      'Continuar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMostSoldProducts() {
    if (_topSoldProducts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: AppTheme.textPrimary,
                size: 18,
              ),
              const SizedBox(width: 6),
              const Text(
                'Más vendidos',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._topSoldProducts.map((product) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getProductIcon(product),
                          color: AppTheme.primaryGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.nombre,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'S/. ${product.precio.toStringAsFixed(2)} · ${product.unidadMedida.isNotEmpty ? product.unidadMedida : 'und'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _addProductToCart(product),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  IconData _getProductIcon(ProductModel product) {
    final name = product.nombre.toLowerCase();
    final cat = (product.categoria ?? '').toLowerCase();

    if (name.contains('coca') ||
        name.contains('fanta') ||
        name.contains('sprite') ||
        name.contains('bebida') ||
        name.contains('gaseosa') ||
        name.contains('agua') ||
        cat.contains('bebida')) {
      return Icons.local_drink_rounded;
    }
    if (name.contains('lays') ||
        name.contains('papitas') ||
        name.contains('doritos') ||
        name.contains('piqueo') ||
        name.contains('snack') ||
        cat.contains('snack')) {
      return Icons.fastfood_rounded;
    }
    if (name.contains('arroz') ||
        name.contains('fideo') ||
        name.contains('aceite') ||
        name.contains('harina') ||
        name.contains('comida') ||
        cat.contains('abarrote')) {
      return Icons.shopping_basket_rounded;
    }
    return Icons.shopping_bag_outlined;
  }
}

class ScannerCornersPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double borderRadius;

  ScannerCornersPainter({
    required this.color,
    this.strokeWidth = 3.0,
    this.cornerLength = 16.0,
    this.borderRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Top Left Corner
    path.moveTo(0, cornerLength);
    path.lineTo(0, borderRadius);
    path.quadraticBezierTo(0, 0, borderRadius, 0);
    path.lineTo(cornerLength, 0);

    // Top Right Corner
    path.moveTo(size.width - cornerLength, 0);
    path.lineTo(size.width - borderRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, borderRadius);
    path.lineTo(size.width, cornerLength);

    // Bottom Right Corner
    path.moveTo(size.width, size.height - cornerLength);
    path.lineTo(size.width, size.height - borderRadius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - borderRadius,
      size.height,
    );
    path.lineTo(size.width - cornerLength, size.height);

    // Bottom Left Corner
    path.moveTo(cornerLength, size.height);
    path.lineTo(borderRadius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - borderRadius);
    path.lineTo(0, size.height - cornerLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
