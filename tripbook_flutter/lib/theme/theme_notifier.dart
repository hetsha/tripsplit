import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  ThemeNotifier({ThemeMode initialMode = ThemeMode.dark}) : _themeMode = initialMode {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final pref = prefs.getString('theme_mode');
    
    ThemeMode mode;
    if (pref == 'light') {
      mode = ThemeMode.light;
    } else if (pref == 'dark') {
      mode = ThemeMode.dark;
    } else if (pref == 'system') {
      mode = ThemeMode.system;
    } else {
      // Default to dark theme if no preference is explicitly saved
      mode = ThemeMode.dark;
    }

    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      String prefValue = 'dark';
      if (mode == ThemeMode.light) {
        prefValue = 'light';
      } else if (mode == ThemeMode.dark) {
        prefValue = 'dark';
      } else if (mode == ThemeMode.system) {
        prefValue = 'system';
      }
      await prefs.setString('theme_mode', prefValue);
    }
  }

  Future<void> toggleTheme({bool? isCurrentlyDark}) async {
    final isDark = isCurrentlyDark ?? (_themeMode == ThemeMode.dark);
    if (isDark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}
