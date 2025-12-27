export 'ui_constants.dart';

class AppConstants {
  // App Information
  static const String appName = 'Poornasree Connect';
  static const String appDescription = 'Dairy Management System';
  
  // API Configuration
  static const int apiTimeoutDuration = 30; // seconds
  static const int maxRetryAttempts = 3;
  
  // OTP Configuration
  static const int otpLength = 6;
  static const int otpResendTimer = 60; // seconds
  
  // Animation Durations
  static const int splashDuration = 3000; // milliseconds
  static const int pageTransitionDuration = 300; // milliseconds
  
  // Storage Keys
  static const String tokenStorageKey = 'auth_token';
  static const String userStorageKey = 'user_data';
  static const String lastLoginKey = 'last_login';
  
  // Validation Patterns
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  
  // Default Values
  static const int defaultPageSize = 20;
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
}

class ErrorMessages {
  static const String networkError = 'Network connection failed. Please check your internet connection.';
  static const String serverError = 'Server error occurred. Please try again later.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String invalidOtp = 'Please enter a valid 6-digit OTP.';
  static const String otpExpired = 'OTP has expired. Please request a new one.';
  static const String authenticationFailed = 'Authentication failed. Please try again.';
  static const String tokenExpired = 'Session expired. Please login again.';
  static const String noMachinesFound = 'No machines found for your account.';
  static const String dataLoadFailed = 'Failed to load data. Please try again.';
}

class SuccessMessages {
  static const String otpSent = 'OTP sent successfully to your email.';
  static const String loginSuccess = 'Login successful.';
  static const String dataRefreshed = 'Data refreshed successfully.';
  static const String logoutSuccess = 'Logged out successfully.';
}