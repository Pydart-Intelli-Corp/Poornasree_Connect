import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/utils.dart';

class MachineService {
  /// Update machine status
  /// 
  /// [machineId] - The ID of the machine to update
  /// [status] - New status: 'active', 'inactive', 'maintenance', or 'suspended'
  /// [token] - Authentication token
  Future<Map<String, dynamic>> updateMachineStatus({
    required int machineId,
    required String status,
    required String token,
  }) async {
    try {
      print('📡 Updating machine status...');
      print('📡 Machine ID: $machineId');
      print('📡 New Status: $status');
      
      final response = await http.put(
        Uri.parse(ApiConfig.machines),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id': machineId,
          'status': status,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Machine status updated successfully');
        return {
          'success': true,
          'message': data['message'] ?? 'Machine status updated successfully',
        };
      } else {
        print('❌ API Error: ${data['error'] ?? data['message']}');
        return {
          'success': false,
          'message': data['error'] ?? data['message'] ?? 'Failed to update machine status',
        };
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Update multiple machines' status (bulk update)
  /// 
  /// [machineIds] - List of machine IDs to update
  /// [status] - New status for all machines
  /// [token] - Authentication token
  Future<Map<String, dynamic>> bulkUpdateStatus({
    required List<int> machineIds,
    required String status,
    required String token,
  }) async {
    try {
      print('📡 Bulk updating machine status...');
      print('📡 Machine IDs: $machineIds');
      print('📡 New Status: $status');
      
      final response = await http.put(
        Uri.parse(ApiConfig.machines),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'bulkStatusUpdate': true,
          'machineIds': machineIds,
          'status': status,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Bulk status update successful');
        return {
          'success': true,
          'message': data['message'] ?? 'Machines updated successfully',
          'updated': data['data']?['updated'] ?? machineIds.length,
        };
      } else {
        print('❌ API Error: ${data['error'] ?? data['message']}');
        return {
          'success': false,
          'message': data['error'] ?? data['message'] ?? 'Failed to update machines',
        };
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Set machine as master and optionally update all machines in society
  /// 
  /// [machineId] - The ID of the machine to set as master
  /// [setForAll] - If true, updates all machines in society with master's passwords
  /// [token] - Authentication token
  Future<Map<String, dynamic>> setMasterMachine({
    required int machineId,
    required bool setForAll,
    required String token,
  }) async {
    try {
      print('📡 Setting master machine...');
      print('📡 Machine ID: $machineId');
      print('📡 Set for all: $setForAll');
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/user/machine/$machineId/set-master'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'setForAll': setForAll,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Master machine set successfully');
        return {
          'success': true,
          'message': data['message'] ?? 'Master machine updated successfully',
        };
      } else {
        print('❌ API Error: ${data['error'] ?? data['message']}');
        return {
          'success': false,
          'message': data['error'] ?? data['message'] ?? 'Failed to set master machine',
        };
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Check access request status
  Future<Map<String, dynamic>> checkAccessStatus({
    required int machineId,
    required String token,
  }) async {
    try {
      print('📡 Checking access status...');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user/machine/$machineId/access-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Access status retrieved');
        return {
          'success': true,
          'hasRequest': data['hasRequest'] ?? false,
          'status': data['status'],
          'message': data['message'] ?? '',
          'isExpired': data['isExpired'] ?? true,
          'expiresAt': data['expiresAt'],
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
        };
      } else {
        return {
          'success': false,
          'hasRequest': false,
          'message': data['message'] ?? 'Failed to check status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'hasRequest': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Request access to change master machine
  Future<Map<String, dynamic>> requestMasterAccess({
    required int machineId,
    required String societyName,
    required String machineName,
    required String token,
  }) async {
    try {
      print('📡 Requesting master access...');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/user/machine/$machineId/request-master-access'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'societyName': societyName,
          'machineName': machineName,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Access request sent successfully');
        return {
          'success': true,
          'message': data['message'] ?? 'Access request sent to admin',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send access request',
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
