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
  final TextEditingController _montoRecibidoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Copy the items to manage state locally
    items = List<Map<String, dynamic>>.from(
      widget.scannedItems.map((item) => Map<String, dynamic>.from(item)),
    );
  }

  @override
  void dispose() {
    _montoRecibidoController.dispose();
    super.dispose();
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

  void _procesarCobro(String metodoPago) async {
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
          nombre: item['name'] ?? '',
          sku: item['sku'] ?? '',
          precio: (item['price'] ?? 0).toDouble(),
          cantidad: (item['quantity'] ?? 0).toInt(),
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
        totalArticulos: _totalItems,
        cajero: cashierName,
        estado: 'PAGADO',
        categoria: saleCategory,
        articulos: saleItems,
        metodoPago: metodoPago,
      );

      // 4. Guardar la venta en Firestore
      final saleId = await SaleService().addSale(newSale);

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      // 5. Mostrar diálogo de éxito personalizado
      _showSuccessDialog(saleId, newSale);
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

  void _showSuccessDialog(String saleId, SaleModel sale) {
    final String shortId = saleId.length > 5 
        ? saleId.substring(saleId.length - 5).toUpperCase() 
        : saleId.toUpperCase();
    final String transId = '#VTA-$shortId';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono Check Verde
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Título
                const Text(
                  '¡Venta completada!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Detalle ID Transacción
                const Text(
                  'ID de transacción',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transId,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 16),

                // Método de Pago
                const Text(
                  'Método de pago',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreenLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        sale.metodoPago == 'Yape/Plin' 
                            ? Icons.qr_code_2_rounded 
                            : Icons.payments_rounded,
                        color: AppTheme.primaryGreen,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sale.metodoPago ?? 'Efectivo',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Botones
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext); // Cierra el modal
                    Navigator.pop(context, <Map<String, dynamic>>[]); // Sale del checkout indicando carrito vacío
                    HomeScreen.of(context)?.setTab(1); // Lleva al inicio de ventas
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Nueva Venta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                ElevatedButton(
                  onPressed: () {
                    _showComprobanteDialog(dialogContext, transId, sale);
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
                    'Ver comprobante',
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
  }

  void _showComprobanteDialog(BuildContext successDialogContext, String transId, SaleModel sale) {
    final localFecha = sale.fecha.toLocal();
    final String dateStr =
        "${localFecha.day.toString().padLeft(2, '0')}/${localFecha.month.toString().padLeft(2, '0')}/${localFecha.year} ${localFecha.hour.toString().padLeft(2, '0')}:${localFecha.minute.toString().padLeft(2, '0')}";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Comprobante',
                        style: TextStyle(
                          fontSize: 20,
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
                  const Divider(color: AppTheme.divider),
                  const SizedBox(height: 12),
                  
                  const Center(
                    child: Text(
                      'TICKET DE VENTA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textSecondary,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTicketRow('Transacción:', transId, isBold: true),
                  _buildTicketRow('Fecha/Hora:', dateStr),
                  _buildTicketRow('Cajero:', sale.cajero),
                  _buildTicketRow('Método de pago:', sale.metodoPago ?? 'Efectivo'),
                  
                  const SizedBox(height: 12),
                  const Text(
                    '- - - - - - - - - - - - - - - - - - - - - - - - - -',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textHint, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Descripción',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                      ),
                      Text(
                        'Total',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  ...sale.articulos.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                  }),
                  
                  const SizedBox(height: 12),
                  const Text(
                    '- - - - - - - - - - - - - - - - - - - - - - - - - -',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textHint, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildTicketRow('Subtotal:', 'S/. ${(_subtotal).toStringAsFixed(2)}'),
                  _buildTicketRow('Impuestos (18%):', 'S/. ${_taxes.toStringAsFixed(2)}'),
                  _buildTicketRow('Descuento:', '-S/. 0.00'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'S/. ${sale.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Cierra comprobante
                      Navigator.pop(successDialogContext); // Cierra éxito
                      Navigator.pop(this.context, <Map<String, dynamic>>[]); // Sale del checkout indicando carrito vacío
                      HomeScreen.of(context)?.setTab(1); // Regresa a ventas
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
                      'Finalizar y Volver',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTicketRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showMetodoPagoBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return _MetodoPagoModalContent(
          total: _total,
          montoRecibidoController: _montoRecibidoController,
          onConfirmPayment: (metodoPago) {
            Navigator.pop(dialogContext); // Cierra bottom sheet
            _procesarCobro(metodoPago);
          },
        );
      },
    );
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
      toolbarHeight: 70,
      leadingWidth: 68,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 12.0, bottom: 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.primaryGreen, size: 20),
            onPressed: () {
              // Return the updated list to the scanner so it syncs
              Navigator.pop(context, items);
            },
            padding: EdgeInsets.zero,
          ),
        ),
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
        onPressed: (items.isEmpty || _isSaving) ? null : _showMetodoPagoBottomSheet,
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

class _MetodoPagoModalContent extends StatefulWidget {
  final double total;
  final TextEditingController montoRecibidoController;
  final Function(String) onConfirmPayment;

  const _MetodoPagoModalContent({
    required this.total,
    required this.montoRecibidoController,
    required this.onConfirmPayment,
  });

  @override
  State<_MetodoPagoModalContent> createState() => _MetodoPagoModalContentState();
}

class _MetodoPagoModalContentState extends State<_MetodoPagoModalContent> {
  String? selectedMethod;
  int currentStep = 0; // 0: Selección de Pago, 1: Yape/Plin QR, 2: Efectivo

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: currentStep == 0
                ? _buildPaymentSelectionStep()
                : currentStep == 1
                    ? _buildQrStep()
                    : _buildEfectivoStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSelectionStep() {
    return Column(
      key: const ValueKey('payment_selection_step'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        const Text(
          'Cobrar Venta',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        
        const Text(
          'Total a cobrar',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'S/. ${widget.total.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 24),
        
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Selecciona el método de pago',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildPaymentCard(
                label: 'Efectivo',
                icon: Icons.payments_rounded,
                isSelected: selectedMethod == 'Efectivo',
                onTap: () {
                  setState(() {
                    selectedMethod = 'Efectivo';
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPaymentCard(
                label: 'Yape/Plin',
                icon: Icons.qr_code_2_rounded,
                isSelected: selectedMethod == 'Yape/Plin',
                onTap: () {
                  setState(() {
                    selectedMethod = 'Yape/Plin';
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        
        ElevatedButton(
          onPressed: selectedMethod == null
              ? null
              : () {
                  if (selectedMethod == 'Yape/Plin') {
                    setState(() {
                      currentStep = 1;
                    });
                  } else if (selectedMethod == 'Efectivo') {
                    setState(() {
                      widget.montoRecibidoController.text = widget.total.toStringAsFixed(2);
                      currentStep = 2;
                    });
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            disabledBackgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.5),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Confirmar método de pago',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreenLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.divider,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrStep() {
    return Column(
      key: const ValueKey('qr_step'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  currentStep = 0;
                });
              },
              child: const Icon(
                Icons.close_rounded,
                color: AppTheme.textPrimary,
                size: 24,
              ),
            ),
            const Expanded(
              child: Text(
                'Yape/Plin',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 24),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Escanea y paga',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryGreen,
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Transform.scale(
              scale: 1.25,
              child: Image.asset(
                'assets/images/qr_yape.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Transform.scale(
                    scale: 0.8,
                    child: Container(
                      width: 200,
                      height: 200,
                      color: const Color(0xFFF9F9F9),
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_2_rounded,
                            size: 64,
                            color: AppTheme.textHint,
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'QR Yape/Plin\n(Coloca tu imagen en assets/images/qr_yape.png)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        Text(
          'S/. ${widget.total.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Muestra este QR al cliente',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 32),
        
        ElevatedButton(
          onPressed: () => widget.onConfirmPayment('Yape/Plin'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Confirmar pago recibido',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEfectivoStep() {
    final double receivedAmount = double.tryParse(widget.montoRecibidoController.text) ?? 0.0;
    final double change = receivedAmount >= widget.total ? receivedAmount - widget.total : 0.0;
    final bool canConfirm = receivedAmount >= widget.total;

    return Column(
      key: const ValueKey('efectivo_step'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  currentStep = 0;
                });
              },
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
            const Expanded(
              child: Text(
                'Cobrar Venta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 24),
          ],
        ),
        const SizedBox(height: 12),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.payments_rounded,
              color: AppTheme.primaryGreen,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Efectivo',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        const Center(
          child: Text(
            'Total a cobrar',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'S/. ${widget.total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryGreen,
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        const Text(
          'Monto recibido',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        TextField(
          controller: widget.montoRecibidoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          onChanged: (val) {
            setState(() {});
          },
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreenLight,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: const Text(
                'S/.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: canConfirm ? AppTheme.primaryGreen : AppTheme.divider,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: canConfirm ? AppTheme.primaryGreen : AppTheme.divider,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryGreen,
                width: 2.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreenLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.autorenew_rounded,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Vuelto:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'S/. ${change.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        ElevatedButton(
          onPressed: canConfirm ? () => widget.onConfirmPayment('Efectivo') : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            disabledBackgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.5),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Confirmar pago',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
