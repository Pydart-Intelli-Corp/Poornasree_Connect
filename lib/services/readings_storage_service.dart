import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lactosure_reading.dart';

/// Service for storing and retrieving daily milk readings
class ReadingsStorageService {
  static final ReadingsStorageService _instance =
      ReadingsStorageService._internal();
  factory ReadingsStorageService() => _instance;
  ReadingsStorageService._internal();

  static const String _keyPrefix = 'readings_';
  static const int _maxReadingsPerMachine =
      100; // Max readings to store per machine per day

  /// Get today's date string for storage key
  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Get storage key for a machine on a specific date
  String _getStorageKey(String machineId, String date) {
    // Normalize machine ID (remove prefix, leading zeros)
    final normalizedId = machineId
        .replaceFirst(RegExp(r'^[Mm]+'), '')
        .replaceFirst(RegExp(r'^0+'), '');
    return '$_keyPrefix${date}_$normalizedId';
  }

  /// Save a reading for a machine (today)
  Future<void> saveReading(String machineId, LactosureReading reading) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getTodayKey();
      final key = _getStorageKey(machineId, today);

      // Get existing readings
      final existingJson = prefs.getString(key);
      List<Map<String, dynamic>> readings = [];

      if (existingJson != null) {
        final decoded = jsonDecode(existingJson) as List;
        readings = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      // Add new reading
      readings.add(reading.toJson());

      // Limit to max readings
      if (readings.length > _maxReadingsPerMachine) {
        readings = readings.sublist(readings.length - _maxReadingsPerMachine);
      }

      // Save back
      await prefs.setString(key, jsonEncode(readings));
      print(
        '💾 [Storage] Saved reading for machine $machineId (${readings.length} total today)',
      );
    } catch (e) {
      print('❌ [Storage] Error saving reading: $e');
    }
  }

  /// Save multiple readings for a machine (today)
  Future<void> saveReadings(
    String machineId,
    List<LactosureReading> newReadings,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getTodayKey();
      final key = _getStorageKey(machineId, today);

      // Get existing readings
      final existingJson = prefs.getString(key);
      List<Map<String, dynamic>> readings = [];

      if (existingJson != null) {
        final decoded = jsonDecode(existingJson) as List;
        readings = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      // Add new readings
      for (final reading in newReadings) {
        readings.add(reading.toJson());
      }

      // Limit to max readings
      if (readings.length > _maxReadingsPerMachine) {
        readings = readings.sublist(readings.length - _maxReadingsPerMachine);
      }

      // Save back
      await prefs.setString(key, jsonEncode(readings));
      print(
        '💾 [Storage] Saved ${newReadings.length} readings for machine $machineId (${readings.length} total today)',
      );
    } catch (e) {
      print('❌ [Storage] Error saving readings: $e');
    }
  }

  /// Load today's readings for a machine
  Future<List<LactosureReading>> loadTodayReadings(String machineId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getTodayKey();
      final key = _getStorageKey(machineId, today);

      final json = prefs.getString(key);
      if (json == null) {
        print('📂 [Storage] No readings found for machine $machineId today');
        return [];
      }

      final decoded = jsonDecode(json) as List;
      final readings = decoded
          .map((e) => LactosureReading.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      print(
        '📂 [Storage] Loaded ${readings.length} readings for machine $machineId',
      );
      return readings;
    } catch (e) {
      print('❌ [Storage] Error loading readings: $e');
      return [];
    }
  }

  /// Load today's readings for all machines
  Future<Map<String, List<LactosureReading>>> loadAllTodayReadings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getTodayKey();
      final prefix = '$_keyPrefix$today';

      final allKeys = prefs.getKeys();
      final todayKeys = allKeys.where((k) => k.startsWith(prefix)).toList();

      Map<String, List<LactosureReading>> result = {};

      for (final key in todayKeys) {
        // Extract machine ID from key
        final machineId = key.replaceFirst('${prefix}_', '');

        final json = prefs.getString(key);
        if (json != null) {
          final decoded = jsonDecode(json) as List;
          final readings = decoded
              .map(
                (e) => LactosureReading.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList();
          result[machineId] = readings;
        }
      }

      print('📂 [Storage] Loaded readings for ${result.length} machines today');
      return result;
    } catch (e) {
      print('❌ [Storage] Error loading all readings: $e');
      return {};
    }
  }

  /// Clear old readings (older than today)
  Future<void> clearOldReadings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getTodayKey();

      final allKeys = prefs.getKeys();
      final readingKeys = allKeys
          .where((k) => k.startsWith(_keyPrefix))
          .toList();

      int removedCount = 0;
      for (final key in readingKeys) {
        // Check if key is NOT from today
        if (!key.contains(today)) {
          await prefs.remove(key);
          removedCount++;
        }
      }

      if (removedCount > 0) {
        print('🧹 [Storage] Cleared $removedCount old reading entries');
      }
    } catch (e) {
      print('❌ [Storage] Error clearing old readings: $e');
    }
  }

  /// Get the latest reading for a machine (today)
  Future<LactosureReading?> getLatestReading(String machineId) async {
    final readings = await loadTodayReadings(machineId);
    if (readings.isEmpty) return null;
    return readings.last;
  }

  /// Clear all readings for today (for testing)
  Future<void> clearTodayReadings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getTodayKey();
      final prefix = '$_keyPrefix$today';

      final allKeys = prefs.getKeys();
      final todayKeys = allKeys.where((k) => k.startsWith(prefix)).toList();

      for (final key in todayKeys) {
        await prefs.remove(key);
      }

      print('🧹 [Storage] Cleared all readings for today');
    } catch (e) {
      print('❌ [Storage] Error clearing today readings: $e');
    }
  }
}
