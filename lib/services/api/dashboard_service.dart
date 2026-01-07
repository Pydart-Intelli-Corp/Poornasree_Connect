import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/utils.dart';
import '../connectivity_service.dart';
import '../offline_cache_service.dart';

class DashboardService {
  final OfflineCacheService _cacheService = OfflineCacheService();
  final ConnectivityService _connectivityService = ConnectivityService();

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
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch dashboard data',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Fetch machines list with offline support
  Future<Map<String, dynamic>> getMachinesList(String token, {bool forceRefresh = false}) async {
    // Check connectivity
    final isOnline = await _connectivityService.checkConnectivity();
    
    // If offline, return cached data
    if (!isOnline) {
      print('📴 [Dashboard] Offline - loading cached machines');
      final cachedMachines = await _cacheService.getCachedMachines();
      if (cachedMachines.isNotEmpty) {
        return {
          'success': true,
          'machines': cachedMachines,
          'fromCache': true,
        };
      } else {
        return {
          'success': false,
          'message': 'No internet connection and no cached data available',
          'machines': [],
          'fromCache': true,
        };
      }
    }

    // Online - fetch from API
    try {
      print('📡 Fetching machines list...');
      final response = await http.get(
        Uri.parse(ApiConfig.machines),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('📡 Machines API response status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Machines API success');

        // Handle different response structures
        List<dynamic> machines = [];
        if (data['data'] is List) {
          machines = data['data'];
        } else if (data['data'] is Map && data['data']['machines'] != null) {
          machines = data['data']['machines'];
        }

        print('✅ Machines count: ${machines.length}');
        
        // Cache the machines for offline use
        await _cacheService.cacheMachines(machines);

        return {'success': true, 'machines': machines, 'fromCache': false};
      } else {
        print('❌ Machines API error: ${data['message']}');
        // On API error, try to return cached data
        final cachedMachines = await _cacheService.getCachedMachines();
        if (cachedMachines.isNotEmpty) {
          return {
            'success': true,
            'machines': cachedMachines,
            'fromCache': true,
            'apiError': data['message'],
          };
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch machines',
          'machines': [],
        };
      }
    } catch (e, stackTrace) {
      print('❌ Network/Parse error in getMachinesList: $e');
      print('❌ Stack trace: $stackTrace');
      
      // On network error, try to return cached data
      final cachedMachines = await _cacheService.getCachedMachines();
      if (cachedMachines.isNotEmpty) {
        return {
          'success': true,
          'machines': cachedMachines,
          'fromCache': true,
          'networkError': e.toString(),
        };
      }
      
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'machines': [],
      };
    }
  }

  // Update machine passwords
  Future<Map<String, dynamic>> updateMachinePasswords(
    String token,
    String machineId,
    String? userPassword,
    String? supervisorPassword,
  ) async {
    try {
      print('🔐 Updating machine passwords for ID: $machineId');

      final body = <String, dynamic>{};
      if (userPassword != null && userPassword.isNotEmpty) {
        body['userPassword'] = userPassword;
      }
      if (supervisorPassword != null && supervisorPassword.isNotEmpty) {
        body['supervisorPassword'] = supervisorPassword;
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.machines}/$machineId/password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print('🔐 Password update response status: ${response.statusCode}');
      print('🔐 Password update response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Machine passwords updated successfully');
        return {
          'success': true,
          'message': data['message'] ?? 'Passwords updated successfully',
          'data': data['data'],
        };
      } else {
        print('❌ Password update error: ${data['message'] ?? data['error']}');
        return {
          'success': false,
          'message':
              data['message'] ?? data['error'] ?? 'Failed to update passwords',
        };
      }
    } catch (e, stackTrace) {
      print('❌ Network/Parse error in updateMachinePasswords: $e');
      print('❌ Stack trace: $stackTrace');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get machine password status
  Future<Map<String, dynamic>?> getMachinePasswordStatus(
    String token,
    String machineId,
  ) async {
    try {
      print('🔐 Getting password status for machine ID: $machineId');

      final response = await http.get(
        Uri.parse('${ApiConfig.machines}/$machineId/password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔐 Password status response status: ${response.statusCode}');
      print('🔐 Password status response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Password status retrieved successfully');
        return data['data'] as Map<String, dynamic>?;
      } else {
        print('❌ Password status error: ${data['message'] ?? data['error']}');
        return null;
      }
    } catch (e) {
      print('❌ Network/Parse error in getMachinePasswordStatus: $e');
      return null;
    }
  }

  // Fetch user profile with offline support
  Future<Map<String, dynamic>> getProfile(String token, {bool forceRefresh = false}) async {
    // Check connectivity
    final isOnline = await _connectivityService.checkConnectivity();
    
    // If offline, return cached data
    if (!isOnline) {
      print('📴 [Dashboard] Offline - loading cached profile');
      final cachedProfile = await _cacheService.getCachedUserProfile();
      if (cachedProfile != null) {
        return {
          'success': true,
          'profile': cachedProfile,
          'fromCache': true,
        };
      } else {
        return {
          'success': false,
          'message': 'No internet connection and no cached data available',
          'fromCache': true,
        };
      }
    }

    // Online - fetch from API
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.profile),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final profile = data['data'] as Map<String, dynamic>;
        
        // Cache the profile for offline use
        await _cacheService.cacheUserProfile(profile);
        
        return {'success': true, 'profile': profile, 'fromCache': false};
      } else {
        // On API error, try to return cached data
        final cachedProfile = await _cacheService.getCachedUserProfile();
        if (cachedProfile != null) {
          return {
            'success': true,
            'profile': cachedProfile,
            'fromCache': true,
            'apiError': data['message'],
          };
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch profile',
        };
      }
    } catch (e) {
      // On network error, try to return cached data
      final cachedProfile = await _cacheService.getCachedUserProfile();
      if (cachedProfile != null) {
        return {
          'success': true,
          'profile': cachedProfile,
          'fromCache': true,
          'networkError': e.toString(),
        };
      }
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Fetch dashboard statistics (last 30 days) with offline support
  Future<Map<String, dynamic>> getStatistics(String token, {bool forceRefresh = false}) async {
    // Check connectivity
    final isOnline = await _connectivityService.checkConnectivity();
    
    // If offline, return cached data
    if (!isOnline) {
      print('📴 [Dashboard] Offline - loading cached statistics');
      final cachedStats = await _cacheService.getCachedStatistics();
      if (cachedStats != null) {
        return {
          'success': true,
          'statistics': cachedStats,
          'fromCache': true,
        };
      } else {
        return {
          'success': false,
          'message': 'No internet connection and no cached data available',
          'statistics': null,
          'fromCache': true,
        };
      }
    }

    // Online - fetch from API
    try {
      print('📊 ===== FETCHING DASHBOARD STATISTICS =====');
      print('📊 API URL: ${ApiConfig.statistics}');

      final response = await http.get(
        Uri.parse(ApiConfig.statistics),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('📊 Statistics API response status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Statistics fetched successfully');
        final statistics = data['data'] as Map<String, dynamic>;
        
        // Cache the statistics for offline use
        await _cacheService.cacheStatistics(statistics);
        
        return {'success': true, 'statistics': statistics, 'fromCache': false};
      } else {
        print('❌ Statistics API error: ${data['message']}');
        // On API error, try to return cached data
        final cachedStats = await _cacheService.getCachedStatistics();
        if (cachedStats != null) {
          return {
            'success': true,
            'statistics': cachedStats,
            'fromCache': true,
            'apiError': data['message'],
          };
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch statistics',
          'statistics': null,
        };
      }
    } catch (e, stackTrace) {
      print('❌ Network/Parse error in getStatistics: $e');
      print('❌ Stack trace: $stackTrace');
      
      // On network error, try to return cached data
      final cachedStats = await _cacheService.getCachedStatistics();
      if (cachedStats != null) {
        return {
          'success': true,
          'statistics': cachedStats,
          'fromCache': true,
          'networkError': e.toString(),
        };
      }
      
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'statistics': null,
      };
    }
  }
}
