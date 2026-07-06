import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import 'add_category_screen.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAddCategory([CategoryModel? category]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCategoryScreen(category: category),
      ),
    );
  }

  void _deleteCategory(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar categoría?'),
        content: Text('La categoría "${category.nombre}" se ocultará del sistema.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(context);
              await _categoryService.deleteCategory(category.id);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Generar icono y color según el nombre de la categoría (similar al mockup)
  Widget _buildCategoryIcon(String name) {
    Color bgColor;
    Color iconColor;
    IconData iconData;

    final lowerName = name.toLowerCase();

    if (lowerName.contains('bebida')) {
      bgColor = Colors.blue.shade50;
      iconColor = Colors.blue.shade600;
      iconData = Icons.local_drink_rounded;
    } else if (lowerName.contains('snack')) {
      bgColor = Colors.orange.shade50;
      iconColor = Colors.orange.shade600;
      iconData = Icons.fastfood_rounded;
    } else if (lowerName.contains('lácteo') || lowerName.contains('lacteo')) {
      bgColor = Colors.purple.shade50;
      iconColor = Colors.purple.shade500;
      iconData = Icons.water_drop_rounded; // Alternativa a botella
    } else if (lowerName.contains('abarrote')) {
      bgColor = Colors.green.shade50;
      iconColor = Colors.green.shade600;
      iconData = Icons.shopping_basket_rounded;
    } else if (lowerName.contains('limpieza')) {
      bgColor = Colors.pink.shade50;
      iconColor = Colors.pink.shade400;
      iconData = Icons.cleaning_services_rounded;
    } else {
      bgColor = Colors.grey.shade200;
      iconColor = Colors.grey.shade700;
      iconData = Icons.more_horiz_rounded;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  void _showCategoryOptions(CategoryModel cat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: AppTheme.primaryGreen),
                  title: const Text('Editar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToAddCategory(cat);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart_rounded, color: AppTheme.primaryGreen),
                  title: const Text('Ver productos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  trailing: Text('Varios', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)), // Placeholder
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navegar a vista de productos filtrada
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppTheme.error),
                  title: const Text('Eliminar', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600, fontSize: 16)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteCategory(cat);
                  },
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: AppTheme.primaryGreen,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Un fondo gris muy claro estilo app moderna
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gestión de Categorías', 
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Administra las categorías de tus productos', 
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barra de Búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Buscar categorías...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<CategoryModel>>(
              stream: _categoryService.getCategoriesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
                }

                var categories = snapshot.data ?? [];
                
                // Filtrado local
                if (_searchQuery.isNotEmpty) {
                  categories = categories.where((c) => c.nombre.toLowerCase().contains(_searchQuery)).toList();
                }

                return Column(
                  children: [
                    // Cabecera de la lista
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${categories.length} categorías', 
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                          Row(
                            children: const [
                              Text('Ordenar', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
                              SizedBox(width: 4),
                              Icon(Icons.sort, size: 16, color: AppTheme.primaryGreen),
                            ],
                          )
                        ],
                      ),
                    ),
                    
                    // Lista de Categorías
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _showCategoryOptions(cat),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      _buildCategoryIcon(cat.nombre),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(cat.nombre, 
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            const SizedBox(height: 4),
                                            Text('Varios productos', // Placeholder por ahora
                                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, color: Colors.grey),
                                      IconButton(
                                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                                        onPressed: () => _showCategoryOptions(cat),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      // Botón Inferior Ancho
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: () => _navigateToAddCategory(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add, color: Colors.white),
                SizedBox(width: 8),
                Text('Nueva Categoría', 
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

