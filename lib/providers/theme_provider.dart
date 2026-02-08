import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Provider para o ThemeMode
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  static const String _boxName = 'settings';
  static const String _key = 'isDarkMode';

  // Carrega o tema salvo
  Future<void> _loadTheme() async {
    final box = await Hive.openBox(_boxName);
    final isDark = box.get(_key);
    
    if (isDark != null) {
      state = isDark ? ThemeMode.dark : ThemeMode.light;
    }
  }

  // Alterna e salva o tema
  Future<void> toggleTheme(bool isDark) async {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    final box = await Hive.openBox(_boxName);
    await box.put(_key, isDark);
  }
}
