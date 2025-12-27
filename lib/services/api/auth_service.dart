import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/utils.dart';
import '../../models/models.dart';

class AuthService {
  // Send OTP to email
  Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      print('📡 Sending OTP request for email: $email');
      
      final response = await http.post(
        Uri.parse(ApiConfig.sendOtp),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent successfully',
        };
      } else {
        // Handle error response - API returns error message in 'error' field
        String errorMessage = 'Failed to send OTP';
        
        // Check 'error' field first (this is where backend sends actual error details)
        if (data['error'] != null) {
          errorMessage = data['error'];
        } else if (data['message'] != null && data['message'] != 'Error occurred') {
          errorMessage = data['message'];
        } else if (data['data'] != null && data['data']['message'] != null) {
          errorMessage = data['data']['message'];
        }
        
        print('❌ API Error: $errorMessage');
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {
        'success': false,
        'message': 'Network error: Unable to connect to server',
      };
    }
  }

  // Verify OTP and login
  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      print('📡 Sending OTP verification request...');
      print('📡 URL: ${ApiConfig.verifyOtp}');
      print('📡 Email: $email');
      
      final response = await http.post(
        Uri.parse(ApiConfig.verifyOtp),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ API Success: Parsing user data...');
        // The API returns user data in data.user, not data directly
        final responseData = data['data'];
        final userData = responseData['user'];
        print('✅ User data: $userData');
        print('✅ User data keys: ${userData.keys.toList()}');
        
        // Create UserModel with all fields from the API response
        final user = UserModel.fromJson({
          ...userData, // Spread all user data fields
          'token': responseData['token'],
          'refreshToken': responseData['refreshToken'],
        });
        
        print('✅ UserModel created successfully');
        print('✅ User ID: ${user.id}');
        print('✅ User Email: ${user.email}');
        print('✅ User Name: ${user.name}');
        print('✅ User Role: ${user.role}');

        return {
          'success': true,
          'message': data['message'] ?? 'Login successful',
          'user': user,
        };
      } else {
        print('❌ API Error: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Invalid OTP',
        };
      }
    } catch (e, stackTrace) {
      print('❌ Network/Parse Error: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Logout
  Future<Map<String, dynamic>> logout(String token) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.logout),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Logout successful',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Logout failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Refresh token
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.refresh),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'token': data['data']['token'],
          'refreshToken': data['data']['refreshToken'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Token refresh failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}
