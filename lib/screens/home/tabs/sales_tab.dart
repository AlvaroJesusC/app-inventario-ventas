import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';

/// Tab de Ventas — contenido vacío por ahora
class SalesTab extends StatelessWidget {
  const SalesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.point_of_sale_rounded,
              size: 64,
              color: AppTheme.textHint.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Ventas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textHint,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Próximamente...',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textHint.withValues(alpha: 0.7),
              ),
            ),
          ],
      ),
    );
  }
}
