import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lactosure_reading.dart';
import 'offline_cache_service.dart';

/// Service for generating local reports from stored readings
/// Mimics the cloud report structure and format
class LocalReportsService {
  static final LocalReportsService _instance = LocalReportsService._internal();
  factory LocalReportsService() => _instance;
  LocalReportsService._internal();

  final OfflineCacheService _cacheService = OfflineCacheService();

  // Society details from auth
  String? _societyId;
  String? _societyName;
  
  // Machine details
  String? _machineType;
  
  /// Set society details from auth provider
  void setSocietyDetails({String? societyId, String? societyName}) {
    _societyId = societyId;
    _societyName = societyName;
    print('📋 [LocalReports] Society set: ID=$societyId, Name=$societyName');
  }
  
  /// Load society details from cache (for offline use)
  Future<void> loadCachedSocietyDetails() async {
    if (_societyId == null || _societyName == null) {
      final cached = await _cacheService.getCachedSocietyDetails();
      if (cached != null) {
        _societyId = cached['society_id']?.toString();
        _societyName = cached['society_name']?.toString();
        print('📋 [LocalReports] Loaded cached society: ID=$_societyId, Name=$_societyName');
      }
    }
  }
  
  /// Set machine type/model from control panel
  void setMachineType(String? machineType) {
    _machineType = machineType;
    print('📋 [LocalReports] Machine type set: $machineType');
  }
  
  /// Load machine type from cached machines
  Future<void> loadCachedMachineType() async {
    if (_machineType == null) {
      final cachedMachines = await _cacheService.getCachedMachines();
      if (cachedMachines.isNotEmpty) {
        _machineType = cachedMachines.first['machine_type']?.toString();
        print('📋 [LocalReports] Loaded cached machine type: $_machineType');
      }
    }
  }

  /// Get collection records from local storage
  /// Format matches cloud API response
  Future<List<Map<String, dynamic>>> getCollectionRecords({
    DateTime? fromDate,
    DateTime? toDate,
    String? machineFilter,
    String? farmerFilter,
    String shiftFilter = 'all',
    String channelFilter = 'all',
  }) async {
    try {
      final List<Map<String, dynamic>> allRecords = [];
      
      // If no date range specified, load all available data
      if (fromDate == null && toDate == null) {
        allRecords.addAll(await _loadAllLocalReadings());
        print('📂 [LocalReports] Loaded ${allRecords.length} total records from all dates');
      } else {
        // Get date range
        final startDate = fromDate ?? DateTime.now();
        final endDate = toDate ?? DateTime.now();
        
        // Load readings for each date in range
        for (var date = startDate; 
             date.isBefore(endDate.add(const Duration(days: 1))); 
             date = date.add(const Duration(days: 1))) {
          final readings = await _loadReadingsForDate(date);
          allRecords.addAll(readings);
        }
        print('📂 [LocalReports] Loaded ${allRecords.length} records from date range');
      }
      
      // Apply filters
      var filteredRecords = allRecords;
      
      if (machineFilter != null && machineFilter.isNotEmpty) {
        filteredRecords = filteredRecords.where((r) {
          final machineId = r['machine_id']?.toString() ?? '';
          return machineId.contains(machineFilter);
        }).toList();
      }
      
      if (farmerFilter != null && farmerFilter.isNotEmpty) {
        filteredRecords = filteredRecords.where((r) {
          final farmerName = r['farmer']?.toString().toLowerCase() ?? '';
          return farmerName.contains(farmerFilter.toLowerCase());
        }).toList();
      }
      
      if (shiftFilter != 'all') {
        filteredRecords = filteredRecords.where((r) {
          return r['shift']?.toString().toLowerCase() == shiftFilter.toLowerCase();
        }).toList();
      }
      
      if (channelFilter != 'all') {
        filteredRecords = filteredRecords.where((r) {
          final channel = r['channel']?.toString().toUpperCase() ?? '';
          final filter = channelFilter.toUpperCase();
          return channel.contains(filter) || channel == filter;
        }).toList();
      }
      
      // Sort by timestamp descending (newest first)
      filteredRecords.sort((a, b) {
        final aTime = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      
      print('📊 [LocalReports] Returning ${filteredRecords.length} filtered records');
      return filteredRecords;
    } catch (e) {
      print('❌ [LocalReports] Error getting collection records: $e');
      return [];
    }
  }

  /// Load readings for a specific date from all machines
  Future<List<Map<String, dynamic>>> _loadReadingsForDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final allKeys = prefs.getKeys();
      final dateKeys = allKeys.where((k) => k.contains('readings_$dateKey')).toList();
      
      final List<Map<String, dynamic>> records = [];
      
      for (final key in dateKeys) {
        // Extract machine ID from key
        final machineId = key.split('_').last;
        
        final json = prefs.getString(key);
        if (json != null) {
          final decoded = jsonDecode(json) as List;
          final readings = decoded
              .map((e) => LactosureReading.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          
          // Convert each reading to report format
          for (int i = 0; i < readings.length; i++) {
            records.add(_readingToReportFormat(readings[i], machineId, i + 1));
          }
        }
      }
      
      return records;
    } catch (e) {
      print('❌ [LocalReports] Error loading readings for date: $e');
      return [];
    }
  }

  /// Convert LactosureReading to report record format
  /// Field names must match cloud API response format for compatibility
  Map<String, dynamic> _readingToReportFormat(
    LactosureReading reading,
    String machineId,
    int slNo,
  ) {
    // Debug: Print the reading values to verify they match control panel
    print('📊 [LocalReports] Converting reading $slNo:');
    print('   FAT: ${reading.fat}, SNF: ${reading.snf}, CLR: ${reading.clr}');
    print('   Protein: ${reading.protein}, Lactose: ${reading.lactose}');
    print('   Salt: ${reading.salt}, Water: ${reading.water}');
    print('   Qty: ${reading.quantity}, Rate: ${reading.rate}, Amount: ${reading.totalAmount}');
    print('   MilkType raw: "${reading.milkType}", MilkTypeName: "${reading.milkTypeName}"');
    
    // Use the actual reading timestamp, or current time as fallback
    final readingTime = reading.timestamp ?? DateTime.now();
    final timestamp = readingTime.toIso8601String();
    
    // Format date and time separately (like cloud API)
    final dateStr = '${readingTime.year}-${readingTime.month.toString().padLeft(2, '0')}-${readingTime.day.toString().padLeft(2, '0')}';
    final timeStr = '${readingTime.hour.toString().padLeft(2, '0')}:${readingTime.minute.toString().padLeft(2, '0')}:${readingTime.second.toString().padLeft(2, '0')}';
    
    // Use stored shift if available (new readings have shift stored at save time)
    // For old readings without stored shift, use fixed time-based logic (not configurable settings)
    String shift;
    if (reading.shift != null && reading.shift!.isNotEmpty) {
      shift = reading.shift!;
    } else {
      // Fallback for readings saved before shift storage was added
      // Use fixed logic: before 12 PM = MR, after = EV (don't use current settings)
      final hour = readingTime.hour;
      shift = (hour < 12) ? 'MR' : 'EV';
    }
    
    // Get channel string from milkType (CH1, CH2, CH3)
    final channel = 'CH${reading.milkType}';
    print('   Channel: "$channel" (from milkType: "${reading.milkType}")');
    
    // Return format matching cloud API response
    return {
      'sl_no': slNo,
      'timestamp': timestamp,
      
      // Date/Time fields (cloud API format)
      'collection_date': dateStr,
      'collection_time': timeStr,
      'date_time': _formatDateTime(readingTime),
      
      // Farmer fields
      'farmer': reading.farmerId,
      'farmer_id': reading.farmerId,
      'farmer_name': '', // No name stored locally
      
      // Location/Machine fields - use society from auth, machine type from control panel
      'society': _societyName ?? 'Local',
      'society_id': _societyId ?? '',
      'society_name': _societyName ?? 'Local',
      'machine': 'M$machineId',
      'machine_id': machineId,
      'machine_name': _machineType ?? 'Lactosure',
      'machine_type': _machineType ?? 'Lactosure',
      
      // Shift/Channel fields
      'shift': shift,
      'shift_type': shift,
      'channel': channel,
      'milk_type': reading.milkTypeName,
      
      // Quality values (cloud API uses _percentage suffix)
      'fat': reading.fat,
      'fat_percentage': reading.fat,
      'snf': reading.snf,
      'snf_percentage': reading.snf,
      'clr': reading.clr,
      'clr_value': reading.clr,
      'protein': reading.protein,
      'protein_percentage': reading.protein,
      'lactose': reading.lactose,
      'lactose_percentage': reading.lactose,
      'salt': reading.salt,
      'salt_percentage': reading.salt,
      'water': reading.water,
      'water_percentage': reading.water,
      'temperature': reading.temperature,
      
      // Amount fields (cloud API uses different names)
      'rate': reading.rate,
      'rate_per_liter': reading.rate,
      'bonus': reading.incentive,
      'qty': reading.quantity,
      'quantity': reading.quantity,
      'amount': reading.totalAmount,
      'total_amount': reading.totalAmount,
    };
  }

  /// Format datetime for display
  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Get unique machines from local storage
  Future<List<Map<String, dynamic>>> getLocalMachines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final readingKeys = allKeys.where((k) => k.startsWith('readings_')).toList();
      
      final Set<String> machineIds = {};
      for (final key in readingKeys) {
        final machineId = key.split('_').last;
        machineIds.add(machineId);
      }
      
      return machineIds.map((id) => {
        'id': id,
        'machine_id': id, // Use raw ID without prefix to match records
        'name': 'Machine $id',
        'machine_type': _machineType ?? 'Lactosure',
      }).toList();
    } catch (e) {
      print('❌ [LocalReports] Error getting local machines: $e');
      return [];
    }
  }

  /// Get unique farmers from local storage readings
  Future<List<Map<String, dynamic>>> getLocalFarmers() async {
    try {
      final allReadings = await _loadAllLocalReadings();
      final Set<String> farmerNames = {};
      
      for (final reading in allReadings) {
        final farmer = reading['farmer']?.toString();
        if (farmer != null && farmer.isNotEmpty && farmer != 'Unknown') {
          farmerNames.add(farmer);
        }
      }
      
      return farmerNames.map((name) => {
        'id': name.hashCode.toString(),
        'name': name,
      }).toList();
    } catch (e) {
      print('❌ [LocalReports] Error getting local farmers: $e');
      return [];
    }
  }

  /// Load all local readings from storage
  Future<List<Map<String, dynamic>>> _loadAllLocalReadings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final readingKeys = allKeys.where((k) => k.startsWith('readings_')).toList();
      
      final List<Map<String, dynamic>> allReadings = [];
      
      for (final key in readingKeys) {
        final machineId = key.split('_').last;
        final json = prefs.getString(key);
        
        if (json != null) {
          final decoded = jsonDecode(json) as List;
          final readings = decoded
              .map((e) => LactosureReading.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          
          for (int i = 0; i < readings.length; i++) {
            allReadings.add(_readingToReportFormat(readings[i], machineId, i + 1));
          }
        }
      }
      
      return allReadings;
    } catch (e) {
      print('❌ [LocalReports] Error loading all local readings: $e');
      return [];
    }
  }

  /// Get statistics for local data
  Future<Map<String, dynamic>> getLocalStatistics() async {
    try {
      final allReadings = await _loadAllLocalReadings();
      
      if (allReadings.isEmpty) {
        return {
          'total_records': 0,
          'total_quantity': 0.0,
          'total_amount': 0.0,
          'avg_fat': 0.0,
          'avg_snf': 0.0,
        };
      }
      
      double totalQty = 0;
      double totalAmount = 0;
      double totalFat = 0;
      double totalSnf = 0;
      
      for (final reading in allReadings) {
        totalQty += (reading['qty'] as num?)?.toDouble() ?? 0;
        totalAmount += (reading['amount'] as num?)?.toDouble() ?? 0;
        totalFat += (reading['fat'] as num?)?.toDouble() ?? 0;
        totalSnf += (reading['snf'] as num?)?.toDouble() ?? 0;
      }
      
      return {
        'total_records': allReadings.length,
        'total_quantity': totalQty,
        'total_amount': totalAmount,
        'avg_fat': totalFat / allReadings.length,
        'avg_snf': totalSnf / allReadings.length,
      };
    } catch (e) {
      print('❌ [LocalReports] Error getting statistics: $e');
      return {
        'total_records': 0,
        'total_quantity': 0.0,
        'total_amount': 0.0,
        'avg_fat': 0.0,
        'avg_snf': 0.0,
      };
    }
  }
}
