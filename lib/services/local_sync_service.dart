import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lactosure_reading.dart';
import '../utils/config/api_config.dart';

/// Sync status for local readings
enum SyncStatus {
  pending,   // Not yet synced
  synced,    // Successfully synced to cloud
  duplicate, // Already exists in cloud
  error,     // Sync failed
}

/// Service for syncing local reports to cloud
class LocalSyncService {
  static final LocalSyncService _instance = LocalSyncService._internal();
  factory LocalSyncService() => _instance;
  LocalSyncService._internal();

  // Keys for storing sync status
  static const String _syncStatusPrefix = 'sync_status_';
  static const String _lastSyncKey = 'last_sync_timestamp';

  /// Get sync status for a reading
  Future<SyncStatus> getSyncStatus(String readingKey) async {
    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getString('$_syncStatusPrefix$readingKey');
    
    switch (status) {
      case 'synced':
        return SyncStatus.synced;
      case 'duplicate':
        return SyncStatus.duplicate;
      case 'error':
        return SyncStatus.error;
      default:
        return SyncStatus.pending;
    }
  }

  /// Set sync status for a reading
  Future<void> setSyncStatus(String readingKey, SyncStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_syncStatusPrefix$readingKey', status.name);
  }

  /// Generate a unique key for a reading
  String generateReadingKey(LactosureReading reading) {
    final date = reading.timestamp ?? DateTime.now();
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
    return '${reading.farmerId}_${dateStr}_$timeStr';
  }

  /// Get all local readings with their sync status
  Future<List<Map<String, dynamic>>> getReadingsWithSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final readingKeys = allKeys.where((k) => k.startsWith('readings_')).toList();
    
    final List<Map<String, dynamic>> readings = [];
    
    for (final key in readingKeys) {
      final json = prefs.getString(key);
      if (json != null) {
        final decoded = jsonDecode(json) as List;
        for (final item in decoded) {
          final reading = LactosureReading.fromJson(Map<String, dynamic>.from(item));
          final readingKey = generateReadingKey(reading);
          final syncStatus = await getSyncStatus(readingKey);
          
          readings.add({
            'reading': reading,
            'key': readingKey,
            'sync_status': syncStatus,
          });
        }
      }
    }
    
    return readings;
  }

  /// Get count of pending (unsynced) readings
  Future<int> getPendingCount() async {
    final readings = await getReadingsWithSyncStatus();
    return readings.where((r) => r['sync_status'] == SyncStatus.pending).length;
  }

  /// Sync local readings to cloud
  /// Returns a map with sync results
  Future<Map<String, dynamic>> syncToCloud({
    required String token,
    required String societyId,
    Function(int synced, int total)? onProgress,
  }) async {
    print('🔄 [LocalSync] Starting sync to cloud...');
    
    final readings = await getReadingsWithSyncStatus();
    final pendingReadings = readings.where((r) => r['sync_status'] == SyncStatus.pending).toList();
    
    if (pendingReadings.isEmpty) {
      print('✅ [LocalSync] No pending readings to sync');
      return {
        'success': true,
        'total': 0,
        'synced': 0,
        'duplicates': 0,
        'errors': 0,
        'message': 'No pending readings to sync',
      };
    }

    print('📤 [LocalSync] Found ${pendingReadings.length} pending readings');

    // Prepare readings for API
    final List<Map<String, dynamic>> readingsToSync = pendingReadings.map((r) {
      final reading = r['reading'] as LactosureReading;
      final date = reading.timestamp ?? DateTime.now();
      
      return {
        'local_id': r['key'],
        'timestamp': date.toIso8601String(),
        'collection_date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'collection_time': '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}',
        'farmer_id': reading.farmerId,
        'shift': reading.shift ?? 'MR',
        'channel': 'CH${reading.milkType}',
        'fat': reading.fat,
        'snf': reading.snf,
        'clr': reading.clr,
        'protein': reading.protein,
        'lactose': reading.lactose,
        'salt': reading.salt,
        'water': reading.water,
        'temperature': reading.temperature,
        'quantity': reading.quantity,
        'rate': reading.rate,
        'total_amount': reading.totalAmount,
        'bonus': reading.incentive,
        'machine_id': reading.machineId,
      };
    }).toList();

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/external/reports/collections/sync'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'readings': readingsToSync}),
      );

      print('📡 [LocalSync] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['data']['results'] as List;
        
        int syncedCount = 0;
        int duplicateCount = 0;
        int errorCount = 0;

        // Update sync status for each reading
        for (final result in results) {
          final localId = result['local_id'];
          final status = result['status'];
          
          switch (status) {
            case 'synced':
              await setSyncStatus(localId, SyncStatus.synced);
              syncedCount++;
              break;
            case 'duplicate':
              await setSyncStatus(localId, SyncStatus.duplicate);
              duplicateCount++;
              break;
            default:
              await setSyncStatus(localId, SyncStatus.error);
              errorCount++;
          }
          
          if (onProgress != null) {
            onProgress(syncedCount + duplicateCount + errorCount, pendingReadings.length);
          }
        }

        // Update last sync timestamp
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

        print('✅ [LocalSync] Sync complete: $syncedCount synced, $duplicateCount duplicates, $errorCount errors');

        return {
          'success': true,
          'total': pendingReadings.length,
          'synced': syncedCount,
          'duplicates': duplicateCount,
          'errors': errorCount,
          'message': 'Sync completed successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        print('❌ [LocalSync] Sync failed: ${errorData['error']}');
        return {
          'success': false,
          'total': pendingReadings.length,
          'synced': 0,
          'duplicates': 0,
          'errors': pendingReadings.length,
          'message': errorData['error'] ?? 'Sync failed',
        };
      }
    } catch (e) {
      print('❌ [LocalSync] Error during sync: $e');
      return {
        'success': false,
        'total': pendingReadings.length,
        'synced': 0,
        'duplicates': 0,
        'errors': pendingReadings.length,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastSyncKey);
    if (timestamp != null) {
      return DateTime.tryParse(timestamp);
    }
    return null;
  }

  /// Get sync summary with smart pending count
  /// Optionally checks cloud to show accurate pending count (excluding duplicates)
  Future<Map<String, int>> getSyncSummary({String? token, bool checkCloud = false}) async {
    final readings = await getReadingsWithSyncStatus();
    
    int pending = 0;
    int synced = 0;
    int duplicates = 0;
    int errors = 0;
    int truePending = 0; // Actual records that will be synced
    
    for (final r in readings) {
      switch (r['sync_status']) {
        case SyncStatus.pending:
          pending++;
          break;
        case SyncStatus.synced:
          synced++;
          break;
        case SyncStatus.duplicate:
          duplicates++;
          break;
        case SyncStatus.error:
          errors++;
          break;
      }
    }
    
    // If cloud check is enabled and token provided, do a pre-flight check
    if (checkCloud && token != null && pending > 0) {
      try {
        final pendingReadings = readings.where((r) => r['sync_status'] == SyncStatus.pending).toList();
        final readingsToCheck = pendingReadings.map((r) {
          final reading = r['reading'] as LactosureReading;
          final date = reading.timestamp ?? DateTime.now();
          
          return {
            'local_id': r['key'],
            'timestamp': date.toIso8601String(),
            'collection_date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
            'collection_time': '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}',
            'farmer_id': reading.farmerId,
            'shift': reading.shift ?? 'MR',
            'channel': 'CH${reading.milkType}',
            'fat': reading.fat,
            'snf': reading.snf,
            'clr': reading.clr,
            'protein': reading.protein ?? 0.0,
            'lactose': reading.lactose ?? 0.0,
            'salt': reading.salt ?? 0.0,
            'water': reading.water ?? 0.0,
            'temperature': reading.temperature ?? 0.0,
            'quantity': reading.quantity ?? 0.0,
            'machine_id': reading.machineId,
          };
        }).toList();

        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/external/reports/collections/sync'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'readings': readingsToCheck, 'checkOnly': true}),
        ).timeout(const Duration(seconds: 5));

        print('📡 [LocalSync] Cloud check response: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('📥 [LocalSync] Response data: ${jsonEncode(data)}');
          
          final results = data['data']['results'] as List;
          
          int cloudDuplicates = 0;
          int willSync = 0;
          for (final result in results) {
            final status = result['status'];
            print('   Record ${result['local_id']}: status = $status');
            if (status == 'duplicate') {
              cloudDuplicates++;
            } else if (status == 'synced') {
              willSync++;
            }
          }
          
          truePending = pending - cloudDuplicates;
          print('📊 [LocalSync] Cloud pre-check: $pending pending, $cloudDuplicates already in cloud, $willSync will sync, $truePending true pending');
        } else {
          print('⚠️ [LocalSync] Cloud check failed with status ${response.statusCode}: ${response.body}');
          truePending = pending; // Fallback if check fails
        }
      } catch (e) {
        print('⚠️ [LocalSync] Cloud pre-check failed: $e, using local count');
        truePending = pending; // Fallback on error
      }
    } else {
      truePending = pending;
    }
    
    return {
      'total': readings.length,
      'pending': truePending, // Show smart pending count
      'pending_local': pending, // Keep original pending count
      'synced': synced,
      'duplicates': duplicates,
      'errors': errors,
    };
  }

  /// Clear sync status for all readings (reset to pending)
  Future<void> resetAllSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final syncKeys = allKeys.where((k) => k.startsWith(_syncStatusPrefix)).toList();
    
    for (final key in syncKeys) {
      await prefs.remove(key);
    }
    
    print('🔄 [LocalSync] Reset sync status for ${syncKeys.length} readings');
  }
}
