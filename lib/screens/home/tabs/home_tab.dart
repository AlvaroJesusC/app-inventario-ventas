import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';

/// Tab de Inicio — contenido vacío por ahora
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_rounded,
              size: 64,
              color: AppTheme.textHint.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Inicio',
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
