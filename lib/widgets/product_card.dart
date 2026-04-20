import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/product_model.dart';

/// Tarjeta de producto para la lista de inventario
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.divider.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ícono del producto
            _buildProductIcon(),
            const SizedBox(width: 14),

            // Nombre del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nombre,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.categoria != null 
                        ? '${product.categoria} • ID: ${product.id.length > 5 ? product.id.substring(0, 5) : product.id}'
                        : 'ID: ${product.id.length > 5 ? product.id.substring(0, 5) : product.id}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.blue.shade400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Precio + Estado del stock
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'S/ ${product.precio.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                _buildStockBadge(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Ícono placeholder del producto
  Widget _buildProductIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.backgroundGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 26,
          color: AppTheme.textHint.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  /// Badge del estado de stock
  Widget _buildStockBadge() {
    Color bgColor;
    Color textColor;

    switch (product.stockStatus) {
      case StockStatus.inStock:
        bgColor = AppTheme.primaryGreen.withValues(alpha: 0.08);
        textColor = AppTheme.primaryGreen;
        break;
      case StockStatus.low:
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        break;
      case StockStatus.empty:
        bgColor = const Color(0xFFFFEBEE);
        textColor = AppTheme.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        product.stockLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
