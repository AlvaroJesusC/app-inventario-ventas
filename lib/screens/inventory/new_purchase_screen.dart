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
  final PurchaseModel? purchaseToEdit;
  const NewPurchaseScreen({super.key, this.purchaseToEdit});

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
    if (widget.purchaseToEdit != null) {
      _purchaseItems.addAll(widget.purchaseToEdit!.articulos);
      _selectedSupplier = SupplierModel(
        id: widget.purchaseToEdit!.supplierId ?? '',
        nombre: widget.purchaseToEdit!.proveedor,
        ruc: '',
        telefono: '',
      );
    }
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
            _suppliers = suppliers;
            if (_selectedSupplier != null) {
              final index = suppliers.indexWhere((s) => s.id == _selectedSupplier!.id);
              if (index != -1) {
                _selectedSupplier = suppliers[index];
              } else {
                _selectedSupplier = suppliers.isNotEmpty ? suppliers.first : null;
              }
            } else if (_suppliers.isNotEmpty) {
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
            _suppliers = [];
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
          final sorted = List<ProductModel>.from(products);
          sorted.sort((a, b) {
            // Productos con stock 0 van primero
            if (a.stock == 0 && b.stock > 0) return -1;
            if (a.stock > 0 && b.stock == 0) return 1;
            // Si ambos tienen stock 0 o ambos stock > 0, ordenar alfabéticamente (sin distinguir mayúsculas/minúsculas)
            return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
          });
          setState(() {
            _availableProducts = sorted;
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
        id: widget.purchaseToEdit?.id ?? '',
        proveedor: _selectedSupplier!.nombre,
        supplierId: _selectedSupplier!.id,
        fecha: widget.purchaseToEdit?.fecha ?? DateTime.now(),
        articulos: _purchaseItems,
        total: _totalAmount,
        totalProductos: _purchaseItems.length,
        totalUnidades: _totalUnits,
      );

      if (widget.purchaseToEdit != null) {
        await _purchaseService.updatePurchase(widget.purchaseToEdit!, purchase);
      } else {
        await _purchaseService.addPurchase(purchase);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.purchaseToEdit != null
                ? 'Compra actualizada y stock ajustado correctamente'
                : 'Compra confirmada y stock actualizado correctamente'),
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
                            'Stock: ${p.stockLabel} · Costo Ref: S/. ${p.costo.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppTheme.primaryGreen)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedProduct = p;
                              if (p.costo > 0) {
                                _unitCostController.text = p.costo.toStringAsFixed(2);
                              } else {
                                _unitCostController.clear();
                              }
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
        toolbarHeight: 70,
        leadingWidth: 68,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 12.0, bottom: 12.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary, size: 20),
              onPressed: _handleBack,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.purchaseToEdit != null ? 'Editar Compra' : 'Nueva Compra',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Registra los productos que estás comprando',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppTheme.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.help_outline_outlined, color: AppTheme.primaryGreen, size: 24),
                onPressed: () {
                  // Ayuda o info
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ],
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
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _showSupplierPickerSheet,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 64,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: AppTheme.primaryGreen,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedSupplier?.nombre ?? 'Seleccionar proveedor',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
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
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8F3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppTheme.primaryGreen,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '¿No lo encuentras? Créalo al abrir la lista',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── 2. AGREGAR PRODUCTO ──
                    const Text(
                      'Agregar producto',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Selector elegir producto (InkWell Modal)
                    InkWell(
                      onTap: _showProductPickerSheet,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 54,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedProduct?.nombre ?? 'Buscar o elegir producto',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _selectedProduct != null ? FontWeight.bold : FontWeight.normal,
                                  color: _selectedProduct != null ? AppTheme.textPrimary : AppTheme.textHint,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        // Campo Cantidad
                        Expanded(
                          child: _buildCustomInputField(
                            label: 'Cantidad',
                            icon: Icons.inventory_2_outlined,
                            child: TextField(
                              controller: _quantityController,
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: _selectedProduct?.ventaPorPeso ?? false,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                hintText: '0',
                                hintStyle: TextStyle(color: AppTheme.textHint),
                                fillColor: Colors.transparent,
                                filled: false,
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Campo Costo Unit. S/.
                        Expanded(
                          child: _buildCustomInputField(
                            label: 'Costo unitario',
                            icon: Icons.local_offer_outlined,
                            child: TextField(
                              controller: _unitCostController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                prefixText: 'S/. ',
                                prefixStyle: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                                hintText: '0.00',
                                hintStyle: TextStyle(color: AppTheme.textHint),
                                fillColor: Colors.transparent,
                                filled: false,
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Botón agregar producto
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _addItemToPurchase,
                        icon: const Icon(Icons.add_circle, color: AppTheme.primaryGreen, size: 20),
                        label: const Text(
                          'Agregar producto',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.white,
                          elevation: 0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── 3. PRODUCTOS EN ESTA COMPRA (N) ──
                    Text(
                      'Productos en esta compra (${_purchaseItems.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_purchaseItems.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F5E9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: AppTheme.primaryGreen,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Aún no has agregado productos',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Agrega productos para verlos aquí.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
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
                        color: const Color(0xFFF6F8F6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE8F0E9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resumen',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8F5E9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  color: AppTheme.primaryGreen,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Total productos',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_purchaseItems.length}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: DashedDivider(color: Color(0xFFC8E6C9), height: 1),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8F5E9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: AppTheme.primaryGreen,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Total a pagar',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
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
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _confirmPurchase,
                        icon: _isSaving
                            ? const SizedBox.shrink()
                            : const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                        label: _isSaving
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.primaryGreen,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Tu compra se registrará de forma segura',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCustomInputField({
    required String label,
    required Widget child,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: AppTheme.textHint, size: 20),
        ],
      ),
    );
  }

  Widget _buildPurchaseItemCard(PurchaseItemModel item, VoidCallback onDelete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppTheme.primaryGreen,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.cantidadLabel} x S/. ${item.costoUnitario.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'S/. ${item.costoTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: onDelete,
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DashedDivider extends StatelessWidget {
  final Color color;
  final double height;
  const DashedDivider({super.key, this.color = const Color(0xFFE0E0E0), this.height = 1});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashSpace = 3.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (index) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}
