import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/product_model.dart';
import '../../models/purchase_model.dart';
import '../../models/supplier_model.dart';
import '../../services/product_service.dart';
import '../../services/purchase_service.dart';
import '../../services/supplier_service.dart';
import '../home/home_screen.dart';

class NewPurchaseScreen extends StatefulWidget {
  const NewPurchaseScreen({super.key});

  @override
  State<NewPurchaseScreen> createState() => _NewPurchaseScreenState();
}

class _NewPurchaseScreenState extends State<NewPurchaseScreen> {
  final ProductService _productService = ProductService();
  final PurchaseService _purchaseService = PurchaseService();
  final SupplierService _supplierService = SupplierService();

  // Proveedores
  List<SupplierModel> _suppliers = [];
  SupplierModel? _selectedSupplier;

  // Productos disponibles
  List<ProductModel> _availableProducts = [];
  ProductModel? _selectedProduct;

  // Form de agregar producto a la compra
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitCostController = TextEditingController();

  // Lista de items en la compra actual
  final List<PurchaseItemModel> _purchaseItems = [];

  bool _isSaving = false;
  bool _isLoading = true;

  // Subscriptions para cancelar en dispose
  StreamSubscription? _suppliersSubscription;
  StreamSubscription? _productsSubscription;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
    _loadProducts();
  }

  @override
  void dispose() {
    _suppliersSubscription?.cancel();
    _productsSubscription?.cancel();
    _quantityController.dispose();
    _unitCostController.dispose();
    super.dispose();
  }

  void _loadSuppliers() {
    _suppliersSubscription = _supplierService.getSuppliersStream().listen(
      (suppliers) {
        if (mounted) {
          setState(() {
            if (suppliers.isEmpty) {
              _suppliers = SupplierService.defaultSuppliers;
            } else {
              _suppliers = suppliers;
            }
            if (_selectedSupplier == null && _suppliers.isNotEmpty) {
              _selectedSupplier = _suppliers.first;
            }
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        debugPrint('Error cargando proveedores: $error');
        if (mounted) {
          setState(() {
            _suppliers = SupplierService.defaultSuppliers;
            if (_selectedSupplier == null && _suppliers.isNotEmpty) {
              _selectedSupplier = _suppliers.first;
            }
            _isLoading = false;
          });
        }
      },
    );
  }

  void _loadProducts() {
    _productsSubscription = _productService.getProductsStream().listen(
      (products) {
        if (mounted) {
          setState(() {
            _availableProducts = products;
          });
        }
      },
      onError: (error) {
        debugPrint('Error cargando productos: $error');
        if (mounted) {
          setState(() {
            _availableProducts = [];
          });
        }
      },
    );
  }

  // Nombre/unidad del producto seleccionado
  String get _currentUnit {
    if (_selectedProduct == null) return 'und';
    if (_selectedProduct!.ventaPorPeso) return 'kg';
    return _selectedProduct!.unidadMedida.isNotEmpty
        ? _selectedProduct!.unidadMedida
        : 'und';
  }

  void _addItemToPurchase() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor elige un producto')),
      );
      return;
    }

    final cantText = _quantityController.text.trim();
    final costText = _unitCostController.text.trim();

    final cant = double.tryParse(cantText) ?? 0.0;
    final unitCost = double.tryParse(costText) ?? 0.0;

    if (cant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una cantidad válida')),
      );
      return;
    }

    if (unitCost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un costo unitario válido')),
      );
      return;
    }

    final newItem = PurchaseItemModel(
      productId: _selectedProduct!.id,
      nombre: _selectedProduct!.nombre,
      sku: _selectedProduct!.sku,
      cantidad: cant,
      unidad: _currentUnit,
      costoUnitario: unitCost,
      costoTotal: cant * unitCost,
    );

    setState(() {
      _purchaseItems.add(newItem);
      _quantityController.clear();
      _unitCostController.clear();
      _selectedProduct = null;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _purchaseItems.removeAt(index);
    });
  }

  double get _totalAmount {
    return _purchaseItems.fold(0.0, (sum, item) => sum + item.costoTotal);
  }

  double get _totalUnits {
    return _purchaseItems.fold(0.0, (sum, item) => sum + item.cantidad);
  }

  void _handleBack() {
    final homeState = HomeScreen.of(context);
    if (homeState != null) {
      homeState.hideNewPurchase();
    } else {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _confirmPurchase() async {
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un proveedor')),
      );
      return;
    }

    if (_purchaseItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto a la compra')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final purchase = PurchaseModel(
        id: '',
        proveedor: _selectedSupplier!.nombre,
        supplierId: _selectedSupplier!.id,
        fecha: DateTime.now(),
        articulos: _purchaseItems,
        total: _totalAmount,
        totalProductos: _purchaseItems.length,
        totalUnidades: _totalUnits,
      );

      await _purchaseService.addPurchase(purchase);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compra confirmada y stock actualizado correctamente'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        _handleBack();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar compra: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showAddSupplierDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final rucCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nuevo Proveedor',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del proveedor *',
                  hintText: 'Ej. Distribuidora Central SAC',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rucCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'RUC (opcional)',
                  hintText: 'Ej. 20123456789',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  hintText: 'Ej. 987654321',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;

                  final newSup = SupplierModel(
                    id: '',
                    nombre: name,
                    ruc: rucCtrl.text.trim().isEmpty ? null : rucCtrl.text.trim(),
                    telefono: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  );

                  final id = await _supplierService.addSupplier(newSup);
                  final savedSup = SupplierModel(
                    id: id,
                    nombre: name,
                    ruc: newSup.ruc,
                    telefono: newSup.telefono,
                  );

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }

                  setState(() {
                    if (!_suppliers.any((s) => s.id == id)) {
                      _suppliers.add(savedSup);
                    }
                    _selectedSupplier = savedSup;
                  });
                },
                child: const Text('Guardar Proveedor'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSupplierPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Seleccionar Proveedor',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ..._suppliers.map((sup) {
                          final isSelected = _selectedSupplier?.id == sup.id;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            leading: const Icon(Icons.storefront_outlined, color: AppTheme.textSecondary),
                            title: Text(
                              sup.nombre,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppTheme.primaryGreen : AppTheme.textPrimary,
                              ),
                            ),
                            trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryGreen) : null,
                            onTap: () {
                              setState(() {
                                _selectedSupplier = sup;
                              });
                              Navigator.pop(ctx);
                            },
                          );
                        }),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            _showAddSupplierDialog();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryGreen, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  '+ Crear nuevo proveedor',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  void _showProductPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Elegir Producto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_availableProducts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No hay productos registrados en el inventario',
                        style: TextStyle(color: AppTheme.textHint),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _availableProducts.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1),
                      itemBuilder: (ctx, index) {
                        final p = _availableProducts[index];
                        final isSelected = _selectedProduct?.id == p.id;
                        return ListTile(
                          title: Text(
                            p.nombre,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppTheme.primaryGreen : AppTheme.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Stock: ${p.stockLabel} · Precio: S/. ${p.precio.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppTheme.primaryGreen)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedProduct = p;
                            });
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: _handleBack,
        ),
        title: const Text(
          'Nueva Compra',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.white,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
              )
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. PROVEEDOR ──
              const Text(
                'Proveedor',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showSupplierPickerSheet,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_outlined, color: AppTheme.textSecondary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedSupplier?.nombre ?? 'Seleccionar proveedor',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _selectedSupplier != null ? FontWeight.w600 : FontWeight.normal,
                            color: _selectedSupplier != null ? AppTheme.textPrimary : AppTheme.textHint,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '¿No lo encuentras? Créalo al abrir la lista',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textHint,
                ),
              ),

              const SizedBox(height: 24),

              // ── 2. AGREGAR PRODUCTO ──
              const Text(
                'Agregar producto',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Selector elegir producto (InkWell Modal)
                  Expanded(
                    flex: 4,
                    child: InkWell(
                      onTap: _showProductPickerSheet,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedProduct?.nombre ?? 'Elegir producto',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _selectedProduct != null ? FontWeight.w600 : FontWeight.normal,
                                  color: _selectedProduct != null ? AppTheme.textPrimary : AppTheme.textHint,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Campo Cantidad
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: _selectedProduct?.ventaPorPeso ?? false,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: _selectedProduct != null ? 'Cant. ($_currentUnit)' : 'Cant.',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                        hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                        fillColor: const Color(0xFFF9F9F9),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryGreen),
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Campo Costo Unit. S/.
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: _unitCostController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Costo unit. S/.',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                        hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                        fillColor: const Color(0xFFF9F9F9),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryGreen),
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Botón verde "Agregar"
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _addItemToPurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Agregar',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── 3. PRODUCTOS EN ESTA COMPRA (N) ──
              Text(
                'Productos en esta compra (${_purchaseItems.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              if (_purchaseItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: const Center(
                    child: Text(
                      'Aún no has agregado productos a esta compra',
                      style: TextStyle(color: AppTheme.textHint, fontSize: 13),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _purchaseItems.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final item = _purchaseItems[index];
                    return _buildPurchaseItemCard(item, () => _removeItem(index));
                  },
                ),

              const SizedBox(height: 24),

              // ── 4. RESUMEN ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F3), // Verde muy claro
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total productos',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '${_purchaseItems.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: Color(0xFFC8E6C9), height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total a pagar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'S/. ${_totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── 5. BOTÓN CONFIRMAR COMPRA ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _confirmPurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Confirmar Compra',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseItemCard(PurchaseItemModel item, VoidCallback onDelete) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Barra lateral verde
              Container(
                width: 5,
                color: AppTheme.primaryGreen,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.nombre,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'S/. ${item.costoTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: onDelete,
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppTheme.textSecondary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.cantidadLabel} x S/. ${item.costoUnitario.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
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
}
