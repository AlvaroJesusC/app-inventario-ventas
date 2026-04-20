import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';

/// Tab de Reportes — contenido vacío por ahora
class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 64,
              color: AppTheme.textHint.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Reportes',
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
      ),
    );
  }
}
