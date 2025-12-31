import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  UserModel? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;

  // Storage keys
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  // Initialize and check if user is already logged in
  Future<void> init() async {
    _isLoading = true;

    try {
      final userData = await _storage.read(key: _userKey);
      final token = await _storage.read(key: _tokenKey);

      print('🔍 AuthProvider.init: Checking stored credentials...');
      print('🔍 AuthProvider.init: User data exists: ${userData != null}');
      print('🔍 AuthProvider.init: Token exists: ${token != null}');

      if (userData != null && token != null) {
        print('🔍 AuthProvider.init: Raw user data: $userData');
        final userMap = jsonDecode(userData);
        print('🔍 AuthProvider.init: Parsed user map: $userMap');
        print('🔍 AuthProvider.init: User map keys: ${userMap.keys.toList()}');
        
        _user = UserModel.fromJson(userMap);
        _isAuthenticated = true;
        
        print('✅ AuthProvider.init: User authenticated');
        print('✅ ID: ${_user?.id}');
        print('✅ Email: ${_user?.email}');
        print('✅ Name: ${_user?.name}');
        print('✅ Role: ${_user?.role}');
        print('✅ User toString: ${_user.toString()}');
      } else {
        _isAuthenticated = false;
        _user = null;
        print('ℹ️ AuthProvider.init: No stored credentials found');
      }
    } catch (e, stackTrace) {
      print('❌ AuthProvider.init: Error loading user data: $e');
      print('❌ Stack trace: $stackTrace');
      _isAuthenticated = false;
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Send OTP
  Future<bool> sendOtp(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.sendOtp(email);
      
      if (result['success']) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Verify OTP and login
  Future<bool> verifyOtp(String email, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔐 Starting OTP verification for: $email');
      final result = await _authService.verifyOtp(email, otp);
      
      print('🔐 API Response received: ${result['success']}');
      print('🔐 Result keys: ${result.keys.toList()}');
      
      if (result['success']) {
        print('🔐 Parsing user data...');
        print('🔐 User data type: ${result['user'].runtimeType}');
        
        // result['user'] is already a UserModel object from auth_service
        _user = result['user'] as UserModel;
        
        print('✅ Login Success: User parsed successfully');
        print('✅ User: ${_user?.email}, Role: ${_user?.role}');
        print('✅ Token: ${_user?.token != null ? "Present" : "Missing"}');
        print('✅ Refresh Token: ${_user?.refreshToken != null ? "Present" : "Missing"}');

        // Store user data and tokens securely
        await _storage.write(key: _userKey, value: jsonEncode(_user!.toJson()));
        await _storage.write(key: _tokenKey, value: _user!.token);
        await _storage.write(key: _refreshTokenKey, value: _user!.refreshToken);

        print('✅ Credentials stored in secure storage');
        _isAuthenticated = true;

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        print('❌ Verification failed: ${result['message']}');
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ ERROR in verifyOtp: $e');
      print('❌ Stack trace: $stackTrace');
      _errorMessage = 'An error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      print('🔓 Logout: Starting logout process...');
      
      if (_user?.token != null) {
        await _authService.logout(_user!.token!);
        print('🔓 Logout: API call completed');
      }

      // Clear stored data
      await _storage.delete(key: _userKey);
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshTokenKey);

      print('🔓 Logout: Cleared all stored credentials');

      _user = null;
      _isAuthenticated = false;
      _errorMessage = null;
    } catch (e) {
      print('❌ Logout Error: $e');
      _user = null;
      _isAuthenticated = false;
      _errorMessage = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Refresh token
  Future<bool> refreshAuthToken() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      
      if (refreshToken == null) {
        await logout();
        return false;
      }

      final result = await _authService.refreshToken(refreshToken);
      
      if (result['success']) {
        // Update tokens
        await _storage.write(key: _tokenKey, value: result['token']);
        await _storage.write(key: _refreshTokenKey, value: result['refreshToken']);
        
        // Update user object
        if (_user != null) {
          _user = _user!.copyWith(
            token: result['token'],
            refreshToken: result['refreshToken'],
          );
          await _storage.write(key: _userKey, value: jsonEncode(_user!.toJson()));
          notifyListeners();
        }
        
        return true;
      } else {
        await logout();
        return false;
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      await logout();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Update profile
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_user?.token == null) {
        _errorMessage = 'Authentication token not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _authService.updateProfile(_user!.token!, profileData);
      
      if (result['success']) {
        print('✅ Profile updated successfully');
        
        // Update local user data with new values
        _user = _user!.copyWith(
          name: profileData['name'] ?? _user!.name,
          location: profileData['location'] ?? _user!.location,
          presidentName: profileData['president_name'] ?? _user!.presidentName,
          contactPhone: profileData['contact_phone'] ?? _user!.contactPhone,
          phone: profileData['phone'] ?? _user!.phone,
        );
        
        // Persist updated user data
        await _storage.write(key: _userKey, value: jsonEncode(_user!.toJson()));
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Error updating profile: $e');
      _errorMessage = 'An error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
