import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/app_theme.dart';
import '../home/home_screen.dart';
import '../../services/user_service.dart';
import '../../services/sale_service.dart';
import '../../models/sale_model.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> scannedItems;

  const CheckoutScreen({
    super.key,
    required this.scannedItems,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late List<Map<String, dynamic>> items;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Copy the items to manage state locally
    items = List<Map<String, dynamic>>.from(
      widget.scannedItems.map((item) => Map<String, dynamic>.from(item)),
    );
  }

  double get _subtotal {
    return items.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  int get _totalItems {
    return items.fold(0, (sum, item) => sum + (item['quantity'] as int));
  }

  double get _taxes {
    return _subtotal * 0.18; // 18% IGV (Impuesto)
  }

  double get _total {
    return _subtotal + _taxes;
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final current = items[index]['quantity'] as int;
      if (current + delta > 0) {
        items[index]['quantity'] = current + delta;
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  void _procesarCobro() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // 1. Obtener el usuario actual
      final user = FirebaseAuth.instance.currentUser;
      String cashierName = 'Cajero';
      if (user != null) {
        final userProfile = await UserService().getUserProfile(user.uid);
        if (userProfile != null) {
          cashierName = userProfile.nombre;
        } else {
          cashierName = user.email ?? 'Cajero';
        }
      }

      // 2. Preparar los productos vendidos
      final saleItems = items.map((item) {
        return SaleItemModel(
          id: item['id'] ?? '',
          name: item['name'] ?? '',
          sku: item['sku'] ?? '',
          price: (item['price'] ?? 0).toDouble(),
          quantity: (item['quantity'] ?? 0).toInt(),
          categoria: item['category'] ?? 'General',
        );
      }).toList();

      // Obtener categorías únicas de los productos vendidos
      final uniqueCategories = saleItems.map((e) => e.categoria).toSet();
      final String saleCategory = uniqueCategories.isEmpty 
          ? 'General' 
          : uniqueCategories.join(', ');

      // 3. Crear el modelo de venta
      final newSale = SaleModel(
        id: '', // Firestore generará el ID automáticamente
        fecha: DateTime.now(),
        total: _total,
        totalItems: _totalItems,
        cashier: cashierName,
        status: 'PAGADO',
        categoria: saleCategory,
        items: saleItems,
      );

      // 4. Guardar la venta en Firestore
      await SaleService().addSale(newSale);

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      // 5. Mostrar diálogo de éxito
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.primaryGreen,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '¡Venta Realizada!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'La transacción se ha registrado exitosamente.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundGrey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Productos',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '$_totalItems und.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Cobrado',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'S/. ${_total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext); // Cierra el modal
                      Navigator.popUntil(context, (route) => route.isFirst); // Sale del checkout
                      HomeScreen.of(context)?.setTab(1); // Lleva al inicio de ventas (SalesTab)
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
                      'Volver a Ventas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al realizar la venta: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 24),
                    _buildItemsList(),
                    const SizedBox(height: 16),
                    _buildAddProductButton(),
                    const SizedBox(height: 24),
                    _buildSummaryCard(),
                  ],
                ),
              ),
            ),
            // Eliminar _buildBottomButton de aquí ya que lo integramos mejor arriba del bottom nav
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBottomButton(),
          _buildBottomNavBar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.backgroundGrey,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
        onPressed: () {
          // Return the updated list to the scanner so it syncs
          Navigator.pop(context, items);
        },
      ),
      title: const Text(
        'Nueva Venta',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context, items); // Cerramos el checkout
              HomeScreen.of(context)?.showProfile(); // Abrimos el perfil
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
              child: const Icon(Icons.person, color: AppTheme.primaryGreen, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar producto, SKU o código de barras...',
          hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
          suffixIcon: IconButton(
            icon: const Icon(Icons.document_scanner_outlined, color: AppTheme.primaryGreen),
            onPressed: () {
              Navigator.pop(context, items); // Go back to scanner
            },
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          fillColor: Colors.transparent,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.shopping_cart_outlined, size: 48, color: AppTheme.textHint.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'No hay productos en el carrito',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final accentColor = AppTheme.primaryGreen;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Borde lateral de color
                Container(
                  width: 4,
                  color: accentColor,
                ),
                // Imagen / Icono
                Container(
                  width: 64,
                  height: 64,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA), // Gris azulado claro
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item['image'] ?? Icons.inventory_2_rounded, color: AppTheme.textHint, size: 28),
                ),
                // Detalles del producto
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        Text(
                          'SKU: ${item['sku']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textHint,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'S/. ${item['price'].toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: accentColor, // Usar el color de acento para el precio
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Controles (Eliminar y Cantidad)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => _removeItem(index),
                        child: const Icon(Icons.delete_outline_rounded, color: AppTheme.textHint, size: 20),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA), // Fondo del selector
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _updateQuantity(index, -1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Icon(Icons.remove_rounded, size: 16, color: accentColor),
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
                              onTap: () => _updateQuantity(index, 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Icon(Icons.add_rounded, size: 16, color: accentColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddProductButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context, items); // Vuelve al escáner
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryGreen.withValues(alpha: 0.8), size: 20),
            const SizedBox(width: 8),
            Text(
              'Agregar producto',
              style: TextStyle(
                color: AppTheme.primaryGreen.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            Icons.shopping_bag_outlined,
            AppTheme.primaryGreenLight,
            AppTheme.primaryGreen,
            'Subtotal ($_totalItems artículos)',
            'S/. ${_subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            Icons.percent_rounded,
            AppTheme.primaryGreenLight,
            AppTheme.primaryGreen,
            'Impuestos (18%)',
            'S/. ${_taxes.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            Icons.local_offer_outlined,
            const Color(0xFFFBE9E7),
            const Color(0xFFD84315),
            'Descuento',
            '-S/. 0.00',
            isDiscount: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppTheme.divider, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreenLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.attach_money_rounded, color: AppTheme.primaryGreen, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                'S/. ${_total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, Color bgColor, Color iconColor, String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 14),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isDiscount ? FontWeight.w600 : FontWeight.w500,
            color: isDiscount ? const Color(0xFFD84315) : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (items.isEmpty || _isSaving) ? null : _procesarCobro,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          disabledBackgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.point_of_sale_rounded, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Cobrar Venta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Inicio',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.point_of_sale_rounded,
                  label: 'Ventas',
                  index: 1, // Ventas está activo
                  isActive: true,
                ),
                _buildNavItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Inventario',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Reportes',
                  index: 3,
                ),
                _buildNavItem(
                  icon: Icons.more_horiz_rounded,
                  label: 'Más',
                  index: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: () {
        // Pop del checkout
        Navigator.popUntil(context, (route) => route.isFirst);
        HomeScreen.of(context)?.setTab(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryGreen.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? AppTheme.primaryGreen : AppTheme.textHint,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppTheme.primaryGreen : AppTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
