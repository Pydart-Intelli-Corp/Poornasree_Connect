import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Extension on BuildContext for easy theme access
extension ThemeExtension on BuildContext {
  /// Check if dark mode is enabled
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  /// Get current theme
  ThemeData get themeData => Theme.of(this);
  
  /// Get primary color
  Color get primaryColor => AppTheme.primaryGreen;
  
  /// Get text primary color
  Color get textPrimaryColor => isDarkMode ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
  
  /// Get text secondary color
  Color get textSecondaryColor => isDarkMode ? AppTheme.textSecondary : AppTheme.textSecondaryLight;
  
  /// Get background color
  Color get backgroundColor => isDarkMode ? AppTheme.darkBg : AppTheme.lightBg;
  
  /// Get card color
  Color get cardColor => isDarkMode ? AppTheme.cardDark : AppTheme.cardLight;
  
  /// Get border color
  Color get borderColor => isDarkMode ? AppTheme.borderDark : AppTheme.borderLight;
  
  /// Get surface color
  Color get surfaceColor => isDarkMode ? AppTheme.cardDark2 : AppTheme.cardLight2;
}
