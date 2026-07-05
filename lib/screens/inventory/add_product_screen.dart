import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../config/app_constants.dart';
import '../../config/app_theme.dart';
import '../../models/product_model.dart';
import '../../models/sku.dart';
import '../../services/product_service.dart';
import '../profile/profile_screen.dart';
import '../home/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();
  final MobileScannerController _scannerController = MobileScannerController();

  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();

  String? _selectedCategory;
  String? _scannedBarcode;
  bool _isLoading = false;
  bool _ventaPorPeso = false;
  String _unidadMedida = 'und';

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nombreController.text = widget.product!.nombre;
      _precioController.text = widget.product!.precio.toString();
      _stockController.text = widget.product!.stock % 1 == 0
          ? widget.product!.stock.toInt().toString()
          : widget.product!.stock.toString();
      _selectedCategory = widget.product!.categoria;
      _scannedBarcode = widget.product!.codigoBarras;
      _ventaPorPeso = widget.product!.ventaPorPeso;
      _unidadMedida = widget.product!.unidadMedida;
    } else {
      _ventaPorPeso = false;
      _unidadMedida = 'und';
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _nombreController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  /// Log - es principal para buscar el producto online
  Future<void> _fetchProductFromBarcode(String barcode) async {
    setState(() {
      _isLoading = true;
    });

    try {
      //openFoodFacts (Comida)
      bool found = await _tryOpenFoodFacts(barcode, isBeauty: false);

      //openBeautyFacts (Shampoos, desodorantes)
      if (!found) {
        found = await _tryOpenFoodFacts(barcode, isBeauty: true);
      }

      if (!found) {
        found = await _tryMercadoLibre(barcode);
      }

      if (found) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Producto encontrado online automáticamente!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código escaneado, pero no se encontró online.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión buscando el código.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // openFoodFacts u openBeautyFacts
  Future<bool> _tryOpenFoodFacts(
    String barcode, {
    required bool isBeauty,
  }) async {
    final domain = isBeauty
        ? 'world.openbeautyfacts.org'
        : 'world.openfoodfacts.org';
    try {
      final url = Uri.parse('https://$domain/api/v0/product/$barcode.json');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          final producto = data['product'];
          setState(() {
            if (producto['product_name'] != null &&
                producto['product_name'].toString().isNotEmpty) {
              _nombreController.text = producto['product_name'];
            } else if (producto['product_name_es'] != null) {
              _nombreController.text = producto['product_name_es'];
            }

            if (isBeauty) {
              _selectedCategory = 'Cuidado Personal';
            } else if (producto['categories'] != null) {
              String cat = producto['categories'].toString().toLowerCase();
              if (cat.contains('beverage') || cat.contains('bebida')) {
                _selectedCategory = 'Bebidas';
              } else if (cat.contains('dairy') || cat.contains('lácteo')) {
                _selectedCategory = 'Lácteos';
              } else if (cat.contains('snack')) {
                _selectedCategory = 'Snacks';
              } else {
                _selectedCategory = 'Abarrotes';
              }
            }
          });
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  /// Busca en MercadoLibre (super útil para cosas generales)
  Future<bool> _tryMercadoLibre(String barcode) async {
    try {
      // MPE es el sitio de Perú en MercadoLibre
      final url = Uri.parse(
        'https://api.mercadolibre.com/sites/MPE/search?q=$barcode',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          final firstResult = data['results'][0];
          setState(() {
            _nombreController.text = firstResult['title'] ?? '';

            // Como MercadoLibre tiene de todo, asignamos "Otros" por defecto
            _selectedCategory = 'Otros';

            // Opcional: Extraer precio sugerido
            if (firstResult['price'] != null) {
              _precioController.text = firstResult['price'].toString();
            }
          });
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una categoría'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final product = ProductModel(
        id: widget.product?.id ?? '', // Se conserva el ID si es edición
        nombre: _nombreController.text.trim(),
        precio: double.parse(_precioController.text.trim()),
        stock: double.parse(_stockController.text.trim()),
        categoria: _selectedCategory,
        codigoBarras: _scannedBarcode,
        sku: widget.product?.sku ?? Sku.generar(
          nombre: _nombreController.text.trim(),
          categoria: _selectedCategory ?? 'General',
        ).valor,
        ventaPorPeso: _ventaPorPeso,
        unidadMedida: _unidadMedida,
      );

      if (widget.product != null) {
        await _productService.updateProduct(product);
      } else {
        await _productService.addProduct(product);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.product != null
                ? 'Producto actualizado correctamente'
                : 'Producto guardado correctamente',
          ),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      final homeState = HomeScreen.of(context);
      if (homeState != null && widget.product == null) {
        homeState.hideAddProduct();
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product != null
                            ? 'Editar Producto'
                            : 'Nuevo Producto',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Caja de escaneo
                      _buildScanBox(),
                      const SizedBox(height: 32),

                      // Formulario
                      _buildInputLabel('Nombre del Producto'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          hintText: 'Ej. Lámpara de Escritorio LED',
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 20),

                      _buildInputLabel('Categoría'),
                      const SizedBox(height: 8),
                      // initialValue en lugar de value por deprecación
                      StreamBuilder<List<CategoryModel>>(
                        stream: CategoryService().getCategoriesStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              height: 56,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }

                          final allCategories = snapshot.data ?? [];

                          // 1. Filtrar duplicados: El Dropdown se rompe si hay dos items con el mismo 'value'
                          final uniqueNames = <String>{};
                          final categorias = allCategories
                              .where((c) => uniqueNames.add(c.nombre))
                              .toList();

                          // 2. Evitar error si la categoría auto-seleccionada no está en la BD
                          // Usamos una variable local para el value en vez de mutar el estado durante el build
                          final String? currentValue =
                              categorias.any(
                                (c) => c.nombre == _selectedCategory,
                              )
                              ? _selectedCategory
                              : null;

                          return DropdownButtonFormField<String>(
                            initialValue: currentValue,
                            decoration: const InputDecoration(
                              hintText: 'Seleccionar categoría...',
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            items: categorias.map((cat) {
                              return DropdownMenuItem(
                                value: cat.nombre,
                                child: Text(cat.nombre),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCategory = val;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel(_ventaPorPeso
                                    ? 'Precio (S/. por $_unidadMedida)'
                                    : 'Precio (S/.)'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _precioController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    hintText: 'S/. 0.00',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Requerido';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Inválido';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('Unidad de Medida'),
                                const SizedBox(height: 8),
                                _buildMeasureToggle(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Stock Inicial',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _stockController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          hintText: _ventaPorPeso ? '0.0' : '0',
                          suffixIcon: Container(
                            width: 100,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F1F1),
                              border: Border(
                                left: BorderSide(color: AppTheme.divider),
                              ),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(11),
                                bottomRight: Radius.circular(11),
                              ),
                            ),
                            child: Center(
                              child: _ventaPorPeso
                                  ? DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _unidadMedida == 'und' ? 'kg' : _unidadMedida,
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        icon: const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: AppTheme.textSecondary,
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'kg',
                                            child: Text('kg'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'l',
                                            child: Text('l'),
                                          ),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              _unidadMedida = val;
                                            });
                                          }
                                        },
                                      ),
                                    )
                                  : const Text(
                                      'und',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 100,
                            minHeight: 56,
                            maxHeight: 56,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Inválido';
                          }
                          if (!_ventaPorPeso && int.tryParse(value) == null) {
                            return 'Inválido para unidad';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 48),

                      // Botones de acción
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                final homeState = HomeScreen.of(context);
                                if (homeState != null) {
                                  homeState.hideAddProduct();
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textPrimary,
                                side: const BorderSide(
                                  color: AppTheme.divider,
                                  width: 1.5,
                                ),
                                minimumSize: const Size(0, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveProduct,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 56),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Guardar',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildScanBox() {
    return Container(
      width: double.infinity,
      height: 240, // Altura fija para la previsualización de la cámara
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider, style: BorderStyle.solid),
      ),
      clipBehavior:
          Clip.hardEdge, // Para que la cámara respete el borde redondeado
      child: Stack(
        children: [
          // 1. La Cámara
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) async {
              if (_isLoading || _scannedBarcode != null) return;

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String code = barcodes.first.rawValue ?? '';
                if (code.isNotEmpty) {
                  setState(() {
                    _scannedBarcode = code;
                  });
                  // Detenemos la cámara temporalmente
                  _scannerController.stop();
                  await _fetchProductFromBarcode(code);
                }
              }
            },
          ),

          // 2. Overlay decorativo (Borde y mira)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _scannedBarcode != null
                      ? AppTheme.primaryGreen
                      : Colors.blue.withValues(alpha: 0.5),
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          if (_scannedBarcode == null)
            Center(
              child: Icon(
                Icons.center_focus_weak_rounded,
                size: 80,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),

          // 3. Panel de estado en la parte inferior
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _scannedBarcode != null
                        ? 'Código: $_scannedBarcode'
                        : 'Apunte al código de barras',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: _scannedBarcode != null
                          ? AppTheme.primaryGreenLight
                          : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_scannedBarcode != null) ...[
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _scannedBarcode = null;
                        });
                        _scannerController.start();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Escanear de nuevo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasureToggle() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_ventaPorPeso) {
                  setState(() {
                    _ventaPorPeso = false;
                    _unidadMedida = 'und';
                    if (_stockController.text.isNotEmpty) {
                      final doubleVal = double.tryParse(_stockController.text);
                      if (doubleVal != null) {
                        _stockController.text = doubleVal.toInt().toString();
                      }
                    }
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: !_ventaPorPeso ? AppTheme.primaryGreenDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Por Unidad',
                  style: TextStyle(
                    color: !_ventaPorPeso ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_ventaPorPeso) {
                  setState(() {
                    _ventaPorPeso = true;
                    _unidadMedida = 'kg';
                    if (_stockController.text.isNotEmpty) {
                      final doubleVal = double.tryParse(_stockController.text);
                      if (doubleVal != null) {
                        _stockController.text = doubleVal.toString();
                      }
                    }
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _ventaPorPeso ? AppTheme.primaryGreenDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Por Peso',
                  style: TextStyle(
                    color: _ventaPorPeso ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              final homeState = HomeScreen.of(context);
              if (homeState != null) {
                homeState.hideAddProduct();
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.divider),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              AppConstants.appName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              final homeState = HomeScreen.of(context);
              if (homeState != null) {
                homeState.showProfile();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              }
            },
            child: StreamBuilder<UserModel?>(
              stream: UserService().getUserProfileStream(
                FirebaseAuth.instance.currentUser!.uid,
                FirebaseAuth.instance.currentUser?.email ?? '',
              ),
              builder: (context, snapshot) {
                final initials = snapshot.data?.initials ?? '';
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreenLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: initials.isEmpty
                        ? const Icon(
                            Icons.person_rounded,
                            size: 22,
                            color: AppTheme.primaryGreen,
                          )
                        : Text(
                            initials,
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
