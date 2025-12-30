class ApiConfig {
  // Update this to match your actual backend URL
  // For development, use the web app's API endpoints
  static const String baseUrl = 'http://192.168.1.68:3000';
  
  // API Endpoints
  static const String sendOtpEndpoint = '/api/external/auth/send-otp';
  static const String verifyOtpEndpoint = '/api/external/auth/verify-otp';
  static const String dashboardEndpoint = '/api/external/auth/dashboard';
  static const String machinesEndpoint = '/api/external/auth/machines';
  static const String profileEndpoint = '/api/external/auth/profile';
  static const String refreshEndpoint = '/api/external/auth/refresh';
  static const String logoutEndpoint = '/api/external/auth/logout';
  static const String statisticsEndpoint = '/api/external/dashboard/statistics';
  static const String sendReportEmailEndpoint = '/api/user/reports/send-email';
  
  // Full URL getters
  static String get sendOtp => '$baseUrl$sendOtpEndpoint';
  static String get verifyOtp => '$baseUrl$verifyOtpEndpoint';
  static String get dashboard => '$baseUrl$dashboardEndpoint';
  static String get machines => '$baseUrl$machinesEndpoint';
  static String get profile => '$baseUrl$profileEndpoint';
  static String get refresh => '$baseUrl$refreshEndpoint';
  static String get logout => '$baseUrl$logoutEndpoint';
  static String get statistics => '$baseUrl$statisticsEndpoint';
  static String get sendReportEmail => '$baseUrl$sendReportEmailEndpoint';
}
