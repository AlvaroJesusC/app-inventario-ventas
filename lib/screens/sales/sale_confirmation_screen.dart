import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/app_theme.dart';
import '../../models/sale_model.dart';
import '../../services/sale_service.dart';
import '../../services/user_service.dart';
import '../../utils/share_utils.dart';

class SaleConfirmationScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String metodoPago;
  final String? clienteInicial;

  const SaleConfirmationScreen({
    super.key,
    required this.items,
    required this.metodoPago,
    this.clienteInicial,
  });

  @override
  State<SaleConfirmationScreen> createState() => _SaleConfirmationScreenState();
}

class _SaleConfirmationScreenState extends State<SaleConfirmationScreen> {
  late final TextEditingController _clienteController;
  final TextEditingController _phoneController = TextEditingController();
  bool _isSaving = false;
  String _cashierName = 'Cajero';

  @override
  void initState() {
    super.initState();
    _clienteController = TextEditingController(text: widget.clienteInicial);
    _loadCashierName();
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return widget.items.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  int get _totalItems {
    return widget.items.fold(0, (sum, item) => sum + (item['quantity'] as int));
  }

  double get _taxes {
    return _subtotal * 0.18; // 18% IGV
  }

  double get _total {
    return _subtotal + _taxes;
  }

  Future<void> _loadCashierName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userProfile = await UserService().getUserProfile(user.uid);
        if (userProfile != null) {
          setState(() {
            _cashierName = userProfile.nombre;
          });
        } else {
          setState(() {
            _cashierName = user.email ?? 'Cajero';
          });
        }
      }
    } catch (e) {
      // Ignorar errores silenciosamente
    }
  }

  SaleModel _buildTempSale() {
    final saleItems = widget.items.map((item) {
      return SaleItemModel(
        id: item['id'] ?? '',
        nombre: item['name'] ?? '',
        sku: item['sku'] ?? '',
        precio: (item['price'] ?? 0).toDouble(),
        cantidad: (item['quantity'] ?? 0).toInt(),
        categoria: item['category'] ?? 'General',
      );
    }).toList();

    final uniqueCategories = saleItems.map((e) => e.categoria).toSet();
    final String saleCategory = uniqueCategories.isEmpty 
        ? 'General' 
        : uniqueCategories.join(', ');

    return SaleModel(
      id: 'TEMP',
      fecha: DateTime.now(),
      total: _total,
      totalArticulos: _totalItems,
      cajero: _cashierName,
      estado: 'PAGADO',
      categoria: saleCategory,
      articulos: saleItems,
      metodoPago: widget.metodoPago,
      cliente: _clienteController.text.trim().isNotEmpty ? _clienteController.text.trim() : null,
    );
  }

  void _finalizarVenta() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final tempSale = _buildTempSale();
      
      // Creamos el modelo final para Firestore (ID se autogenera)
      final finalSale = SaleModel(
        id: '',
        fecha: DateTime.now(),
        total: tempSale.total,
        totalArticulos: tempSale.totalArticulos,
        cajero: tempSale.cajero,
        estado: 'PAGADO',
        categoria: tempSale.categoria,
        articulos: tempSale.articulos,
        metodoPago: tempSale.metodoPago,
        cliente: tempSale.cliente,
      );

      await SaleService().addSale(finalSale);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venta registrada con éxito.'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );

      Navigator.pop(context, true); // Devuelve true para indicar éxito y limpiar carrito
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la venta: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String dateStr =
        "${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}";

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundGrey,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.primaryGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Confirmar Venta',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🧾 TICKET CARD
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: AppTheme.divider),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: Text(
                        'TICKET DE VENTA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textSecondary,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTicketRow('Fecha/Hora:', dateStr),
                    _buildTicketRow('Cajero:', _cashierName),
                    _buildTicketRow('Método de pago:', widget.metodoPago),
                    
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
                    
                    ...widget.items.map((item) {
                      final name = item['name'] ?? '';
                      final price = (item['price'] ?? 0).toDouble();
                      final qty = (item['quantity'] ?? 0).toInt();
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
                                    name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'S/. ${price.toStringAsFixed(2)} x $qty',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'S/. ${(price * qty).toStringAsFixed(2)}',
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
                          'S/. ${_total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 👤 DATOS DEL CLIENTE CARD
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: AppTheme.divider),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Datos del Cliente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Cliente Nombre
                    TextField(
                      controller: _clienteController,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Nombre del cliente (Opcional)',
                        labelStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        hintText: 'Ej. Juan Pérez',
                        hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 13),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.primaryGreen, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Celular
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Celular del cliente (WhatsApp)',
                        labelStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        hintText: 'Ej. 987654321',
                        hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 13),
                        prefixIcon: const Icon(Icons.phone_rounded, color: AppTheme.primaryGreen, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 🚀 COMPARTIR Y WHATSAPP BUTTONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ShareUtils.shareViaSystem(_buildTempSale()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.divider, width: 1.5),
                        minimumSize: const Size(0, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text(
                        'Compartir',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ShareUtils.shareViaWhatsApp(
                          _buildTempSale(),
                          phoneNumber: _phoneController.text.trim(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      label: const Text(
                        'WhatsApp',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 💾 GUARDAR VENTA BUTTON
              ElevatedButton(
                onPressed: _isSaving ? null : _finalizarVenta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Guardar y Finalizar Venta',
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
  }

  Widget _buildTicketRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
