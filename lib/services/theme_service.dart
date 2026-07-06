import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  ThemeService._privateConstructor();
  static final ThemeService instance = ThemeService._privateConstructor();

  static const String _themeKey = 'is_dark_mode';
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_themeKey) ?? false;
      themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      debugPrint('Error al inicializar ThemeService: $e');
      themeModeNotifier.value = ThemeMode.light;
    }
  }

  bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  Future<void> toggleTheme(bool isDark) async {
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDark);
    } catch (e) {
      debugPrint('Error al guardar el tema: $e');
    }
  }
}
