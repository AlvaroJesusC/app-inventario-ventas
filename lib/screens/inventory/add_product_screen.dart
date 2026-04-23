import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import '../../config/app_constants.dart';
import '../../config/app_theme.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../profile/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();

  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();

  String? _selectedCategory;
  String? _scannedBarcode;
  bool _isLoading = false;

  final List<String> _categorias = [
    'Abarrotes',
    'Bebidas',
    'Lácteos',
    'Limpieza',
    'Snacks',
    'Hogar',
    'Cuidado Personal',
    'Otros',
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  /// Lógica principal para buscar el producto online
  Future<void> _fetchProductFromBarcode(String barcode) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Intentar en OpenFoodFacts (Comida)
      bool found = await _tryOpenFoodFacts(barcode, isBeauty: false);
      
      // 2. Si no, intentar en OpenBeautyFacts (Shampoos, desodorantes)
      if (!found) {
        found = await _tryOpenFoodFacts(barcode, isBeauty: true);
      }
      
      // 3. Si no, intentar en MercadoLibre Perú (Cosas de casa, electrónica, etc)
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

  /// Busca en OpenFoodFacts u OpenBeautyFacts
  Future<bool> _tryOpenFoodFacts(String barcode, {required bool isBeauty}) async {
    final domain = isBeauty ? 'world.openbeautyfacts.org' : 'world.openfoodfacts.org';
    try {
      final url = Uri.parse('https://$domain/api/v0/product/$barcode.json');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          final producto = data['product'];
          setState(() {
            if (producto['product_name'] != null && producto['product_name'].toString().isNotEmpty) {
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
      final url = Uri.parse('https://api.mercadolibre.com/sites/MPE/search?q=$barcode');
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
        id: '', // Se generará en Firestore
        nombre: _nombreController.text.trim(),
        precio: double.parse(_precioController.text.trim()),
        stock: int.parse(_stockController.text.trim()),
        categoria: _selectedCategory,
        codigoBarras: _scannedBarcode,
      );

      await _productService.addProduct(product);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto guardado correctamente'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      Navigator.pop(context);
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
                      const Text(
                        'Nuevo Producto',
                        style: TextStyle(
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
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          hintText: 'Seleccionar categoría...',
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: _categorias.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('Precio (S/)'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _precioController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    hintText: 'S/ 0.00',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return 'Requerido';
                                    if (double.tryParse(value) == null)
                                      return 'Inválido';
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
                                _buildInputLabel('Stock Inicial'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _stockController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return 'Requerido';
                                    if (int.tryParse(value) == null)
                                      return 'Inválido';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),

                      // Botones de acción
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
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
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () async {
              // Abrir escáner
              var res = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SimpleBarcodeScannerPage(),
                ),
              );
              if (res is String && res != '-1') {
                setState(() {
                  _scannedBarcode = res;
                });
                // Buscar datos online con el código
                await _fetchProductFromBarcode(res);
              }
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.barcode_reader,
                size: 32,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Escanear Código',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _scannedBarcode != null
                ? 'Código: $_scannedBarcode'
                : 'Use la cámara para rellenar\nautomáticamente.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _scannedBarcode != null
                  ? AppTheme.primaryGreen
                  : AppTheme.textHint,
              fontWeight: _scannedBarcode != null
                  ? FontWeight.w600
                  : FontWeight.normal,
              height: 1.4,
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
            onTap: () => Navigator.pop(context),
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
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
                        ? const Icon(Icons.person_rounded, size: 22, color: AppTheme.primaryGreen)
                        : Text(initials, style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}
