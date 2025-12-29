import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/utils.dart';

class DashboardService {
  // Fetch dashboard data
  Future<Map<String, dynamic>> getDashboardData(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.dashboard),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch dashboard data',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Fetch machines list
  Future<Map<String, dynamic>> getMachinesList(String token) async {
    try {
      print('📡 Fetching machines list...');
      final response = await http.get(
        Uri.parse(ApiConfig.machines),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Machines API response status: ${response.statusCode}');
      print('📡 Machines API response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Machines API success');
        print('✅ Data type: ${data['data'].runtimeType}');
        print('✅ Data keys: ${data['data'] is Map ? (data['data'] as Map).keys.toList() : "Not a Map"}');
        
        // Handle different response structures
        List<dynamic> machines = [];
        if (data['data'] is List) {
          machines = data['data'];
        } else if (data['data'] is Map && data['data']['machines'] != null) {
          machines = data['data']['machines'];
        } else if (data['data'] is Map) {
          // If data is a map but doesn't have 'machines' key, try to extract from known keys
          print('✅ Data map contents: ${data['data']}');
          machines = [];
        }
        
        print('✅ Machines count: ${machines.length}');
        
        return {
          'success': true,
          'machines': machines,
        };
      } else {
        print('❌ Machines API error: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch machines',
          'machines': [],
        };
      }
    } catch (e, stackTrace) {
      print('❌ Network/Parse error in getMachinesList: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'machines': [],
      };
    }
  }

  // Fetch user profile
  Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.profile),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'profile': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Fetch dashboard statistics (last 30 days)
  Future<Map<String, dynamic>> getStatistics(String token) async {
    try {
      print('📊 ===== FETCHING DASHBOARD STATISTICS =====');
      print('📊 API URL: ${ApiConfig.statistics}');
      print('📊 Token length: ${token.length}');
      print('📊 Token preview: ${token.substring(0, 20)}...');
      
      final response = await http.get(
        Uri.parse(ApiConfig.statistics),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📊 Statistics API response status: ${response.statusCode}');
      print('📊 Statistics API response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Statistics fetched successfully');
        print('✅ Statistics data: ${data['data']}');
        return {
          'success': true,
          'statistics': data['data'],
        };
      } else {
        print('❌ Statistics API error: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch statistics',
          'statistics': null,
        };
      }
    } catch (e, stackTrace) {
      print('❌ Network/Parse error in getStatistics: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'statistics': null,
      };
    }
  }
}
