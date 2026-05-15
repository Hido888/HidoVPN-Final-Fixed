import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('tr');
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme
    final themeStr = prefs.getString('theme_mode');
    if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    // Load language
    final langStr = prefs.getString('language');
    if (langStr != null && ['tr', 'en', 'ru', 'tk'].contains(langStr)) {
      _locale = Locale(langStr);
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    String modeStr = 'system';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    if (mode == ThemeMode.light) modeStr = 'light';
    await prefs.setString('theme_mode', modeStr);
  }

  Future<void> setLocale(Locale locale) async {
    if (!['tr', 'en', 'ru', 'tk'].contains(locale.languageCode)) return;
    
    _locale = locale;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale.languageCode);
  }
}
