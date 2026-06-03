import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../config/app_theme.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
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

  // Modo demo
  final bool _isDemoMode = true;

  // Lista de productos escaneados
  final List<Map<String, dynamic>> _scannedItems = [];

  // Buscador
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<ProductModel> _allProducts = [];
  StreamSubscription<List<ProductModel>>? _productsSubscription;

  @override
  void initState() {
    super.initState();
    _productsSubscription = _productService.getProductsStream().listen((products) {
      if (mounted) {
        setState(() {
          _allProducts = products;
        });
      }
    });
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    _searchController.dispose();
    _scannerController.dispose();
    super.dispose();
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
      // 1. Revisar si ya está en el carrito
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
        // 2. Buscar en Firestore
        final product = await _productService.getProductByBarcode(barcode);

        if (product != null) {
          _addProductToCart(product);
        } else {
          // 3. Mostrar advertencia si no está en BD
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            final snackBarController = ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white),
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
      // Pequeña pausa para no escanear el mismo código múltiples veces seguidas muy rápido
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
            content: Text('Cantidad de ${_scannedItems[index]['name']} aumentada'),
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
          'sku': product.codigoBarras ?? '',
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
      return p.nombre.toLowerCase().contains(query);
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
              itemCount: matchedProducts.length > 5 ? 5 : matchedProducts.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: AppTheme.divider,
              ),
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
      backgroundColor: AppTheme.backgroundGrey,
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
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.primaryGreen,
              size: 28,
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
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
                    left: BorderSide(
                      color: AppTheme.divider,
                      width: 1,
                    ),
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
    path.quadraticBezierTo(size.width, size.height, size.width - borderRadius, size.height);
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
