import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  static const String _themeKey = 'theme_mode';
  
  ThemeNotifier() : super(AppThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    state = AppThemeMode.values[themeIndex];
  }

  Future<void> setTheme(AppThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, themeMode.index);
    state = themeMode;
  }

  String getThemeDisplayName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'Système';
      case AppThemeMode.light:
        return 'Clair';
      case AppThemeMode.dark:
        return 'Sombre';
    }
  }

  /// Convert our custom AppThemeMode to Flutter's ThemeMode
  ThemeMode get materialThemeMode {
    switch (state) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});