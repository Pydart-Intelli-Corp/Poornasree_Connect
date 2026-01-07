import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme provider for managing dark/light mode
class ThemeProvider extends ChangeNotifier {
  static final ThemeProvider _instance = ThemeProvider._internal();
  
  factory ThemeProvider() => _instance;
  ThemeProvider._internal();

  static const String _themeModeKey = 'theme_mode';
  
  bool _isDarkMode = true; // Default to dark mode
  bool get isDarkMode => _isDarkMode;

  /// Initialize theme from saved preferences or system preference
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeModeKey);
      
      if (savedTheme != null) {
        _isDarkMode = savedTheme == 'dark';
        print('🎨 [Theme] Loaded saved theme: ${_isDarkMode ? 'Dark' : 'Light'}');
      } else {
        // Use system preference
        final brightness = MediaQueryData.fromWindow(WidgetsBinding.instance.window).platformBrightness;
        _isDarkMode = brightness == Brightness.dark;
        print('🎨 [Theme] Using system theme: ${_isDarkMode ? 'Dark' : 'Light'}');
      }
      notifyListeners();
    } catch (e) {
      print('❌ [Theme] Error initializing theme: $e');
    }
  }

  /// Toggle between dark and light mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _saveTheme();
    notifyListeners();
    print('🎨 [Theme] Switched to: ${_isDarkMode ? 'Dark' : 'Light'} mode');
  }

  /// Set specific theme mode
  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    await _saveTheme();
    notifyListeners();
    print('🎨 [Theme] Set to: ${_isDarkMode ? 'Dark' : 'Light'} mode');
  }

  /// Save theme to preferences
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, _isDarkMode ? 'dark' : 'light');
    } catch (e) {
      print('❌ [Theme] Error saving theme: $e');
    }
  }
}
