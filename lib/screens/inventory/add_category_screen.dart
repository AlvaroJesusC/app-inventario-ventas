import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';

class AddCategoryScreen extends StatefulWidget {
  final CategoryModel? category; // Si es null, estamos creando. Si tiene datos, estamos editando.

  const AddCategoryScreen({super.key, this.category});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryService = CategoryService();
  
  late TextEditingController _nameController;
  late TextEditingController _descController;
  
  bool _isLoading = false;

  // Lista de colores para elegir (coinciden con la captura)
  final List<String> _colorOptions = [
    '#4CAF50', // Verde
    '#64B5F6', // Azul claro
    '#FDD835', // Amarillo
    '#BA68C8', // Morado
    '#F06292', // Rosa
    '#FF8A65', // Naranja
  ];

  late String _selectedColorHex;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.nombre ?? '');
    _descController = TextEditingController(text: widget.category?.descripcion ?? '');
    
    // Si estamos editando y tiene un color válido, lo seleccionamos. Si no, verde por defecto.
    _selectedColorHex = widget.category?.colorHex ?? _colorOptions[0];
    if (!_colorOptions.contains(_selectedColorHex)) {
      _selectedColorHex = _colorOptions[0];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.category == null) {
        // Nueva categoría
        final newCat = CategoryModel(
          id: '',
          nombre: _nameController.text.trim(),
          descripcion: _descController.text.trim(),
          colorHex: _selectedColorHex,
        );
        await _categoryService.addCategory(newCat);
      } else {
        // Actualizar existente
        final updatedCat = CategoryModel(
          id: widget.category!.id,
          nombre: _nameController.text.trim(),
          descripcion: _descController.text.trim(),
          colorHex: _selectedColorHex,
          activo: widget.category!.activo,
        );
        await _categoryService.updateCategory(updatedCat);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Categoría guardada correctamente'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        centerTitle: true,
        title: Text(
          isEditing ? 'Editar Categoría' : 'Nueva Categoría',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Área del ícono (Decorativo según tu diseño)
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_offer_rounded,
                            size: 48,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            color: AppTheme.white,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Agregar ícono',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Selecciona un ícono para tu categoría',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Campo: Nombre
              RichText(
                text: const TextSpan(
                  text: 'Nombre de la categoría ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  children: [TextSpan(text: '*', style: TextStyle(color: AppTheme.error))],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                maxLength: 50,
                decoration: InputDecoration(
                  hintText: 'Ej. Bebidas',
                  filled: true,
                  fillColor: AppTheme.white,
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
                    borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              // Campo: Descripción
              const Text(
                'Descripción (opcional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLength: 120,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ej. Bebidas frías, calientes, gaseosas, etc.',
                  filled: true,
                  fillColor: AppTheme.white,
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
                    borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Selección de Color
              const Text(
                'Color',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _colorOptions.map((hex) {
                  final isSelected = _selectedColorHex == hex;
                  // Convertimos hex '#4CAF50' a Color(0xFF4CAF50)
                  final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorHex = hex),
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected 
                            ? Border.all(color: Colors.black.withValues(alpha: 0.5), width: 2)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Caja de Consejo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreenLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGreenLight),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.primaryGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Consejo',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Elige un nombre claro y un color que te ayude a identificar fácilmente esta categoría.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveCategory,
            icon: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_outlined, size: 20),
            label: Text(
              _isLoading ? 'Guardando...' : 'Guardar Categoría',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}
