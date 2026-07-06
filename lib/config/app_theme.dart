import 'package:flutter/material.dart';
import '../services/theme_service.dart';

/// es el tema principal de la ap
class AppTheme {
  // colores principales dinámicos según el modo
  static Color get primaryGreen => ThemeService.instance.isDarkMode ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
  static Color get primaryGreenLight => ThemeService.instance.isDarkMode ? const Color(0xFF1E2B22) : const Color(0xFFE8F5E9);
  static Color get primaryGreenDark => ThemeService.instance.isDarkMode ? const Color(0xFF1B5E20) : const Color(0xFF1B5E20);
  static Color get white => ThemeService.instance.isDarkMode ? const Color(0xFF1E2B22) : const Color(0xFFFFFFFF);
  static Color get backgroundGrey => ThemeService.instance.isDarkMode ? const Color(0xFF121B16) : const Color(0xFFF5F5F5);
  static Color get textPrimary => ThemeService.instance.isDarkMode ? const Color(0xFFE8F5E9) : const Color(0xFF212121);
  static Color get textSecondary => ThemeService.instance.isDarkMode ? const Color(0xFFA5D6A7) : const Color(0xFF757575);
  static Color get textHint => ThemeService.instance.isDarkMode ? const Color(0xFF4F6B58) : const Color(0xFFBDBDBD);
  static Color get divider => ThemeService.instance.isDarkMode ? const Color(0xFF2E3D32) : const Color(0xFFE0E0E0);
  static Color get error => const Color(0xFFD32F2F);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D32),
        primary: const Color(0xFF2E7D32),
        surface: const Color(0xFFFFFFFF),
        surfaceContainerHighest: const Color(0xFFF5F5F5),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF212121),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
        hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: const Color(0xFFFFFFFF),
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryGreen,
        surface: white,
        onSurface: textPrimary,
        surfaceContainerHighest: backgroundGrey,
      ),
      scaffoldBackgroundColor: backgroundGrey,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundGrey,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen, width: 2),
        ),
        hintStyle: TextStyle(color: textHint, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: const Color(0xFF121B16), // Contraste oscuro para el texto del botón
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
    );
  }
}

