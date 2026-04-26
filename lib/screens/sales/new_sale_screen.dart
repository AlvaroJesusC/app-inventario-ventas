import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../config/app_theme.dart';
import '../../models/product_model.dart';
import '../home/home_screen.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isFlashOn = false;

  // Lista de productos escaneados
  final List<Map<String, dynamic>> _scannedItems = [];

  @override
  void dispose() {
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

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
      _scannerController.toggleTorch();
    });
  }

  double get _totalPrice {
    return _scannedItems.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  int get _totalItems {
    return _scannedItems.fold(0, (sum, item) => sum + (item['quantity'] as int));
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
          )
        ],
      ),
    );
  }

  Widget _buildScannerBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      height: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF1E242B), // Color oscuro premium
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.barcode_reader, color: Colors.white.withValues(alpha: 0.7), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Apunta al código de barras',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _toggleFlash,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Scanner Camera
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: (capture) {
                      // TODO: Manejar detección para agregar a la lista
                    },
                  ),
                  // Línea láser animada (estática por ahora para diseño)
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
            ),
          ),
          const SizedBox(height: 16),
          
          // Bottom Info Text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.white.withValues(alpha: 0.6), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Escanea el código de barras del producto para añadirlo al ticket',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
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
                    Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red.shade400),
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
                  style: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 14,
                  ),
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
            Container(
              width: 4,
              color: AppTheme.primaryGreen,
            ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item['name'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _scannedItems.remove(item);
                            });
                          },
                          child: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textHint),
                        ),
                      ],
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
                          'S/ ${item['price'].toStringAsFixed(2)}',
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
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  child: Icon(Icons.remove_rounded, size: 16, color: AppTheme.textPrimary),
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
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  child: Icon(Icons.add_rounded, size: 16, color: AppTheme.textPrimary),
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
                'S/ ${_totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: () {
                  // TODO: Continuar proceso de pago
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
