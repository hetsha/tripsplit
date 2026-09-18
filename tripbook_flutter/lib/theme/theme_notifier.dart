import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeNotifier() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final pref = prefs.getString('theme_mode') ?? 'system';
    
    if (pref == 'light') {
      _themeMode = ThemeMode.light;
    } else if (pref == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      String prefValue = 'system';
      if (mode == ThemeMode.light) {
        prefValue = 'light';
      } else if (mode == ThemeMode.dark) {
        prefValue = 'dark';
      }
      await prefs.setString('theme_mode', prefValue);
    }
  }
}
