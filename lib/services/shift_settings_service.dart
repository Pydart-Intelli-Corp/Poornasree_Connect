import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage shift time settings
class ShiftSettingsService {
  static final ShiftSettingsService _instance = ShiftSettingsService._internal();
  factory ShiftSettingsService() => _instance;
  ShiftSettingsService._internal();

  // Storage keys
  static const String _mrStartKey = 'shift_mr_start';
  static const String _mrEndKey = 'shift_mr_end';
  static const String _evStartKey = 'shift_ev_start';
  static const String _evEndKey = 'shift_ev_end';

  // Default shift times (in minutes from midnight)
  // Morning: 6:00 AM - 12:00 PM
  // Evening: 12:00 PM - 8:00 PM
  int _mrStartMinutes = 6 * 60;  // 6:00 AM
  int _mrEndMinutes = 12 * 60;   // 12:00 PM
  int _evStartMinutes = 12 * 60; // 12:00 PM
  int _evEndMinutes = 20 * 60;   // 8:00 PM

  // Getters
  int get mrStartMinutes => _mrStartMinutes;
  int get mrEndMinutes => _mrEndMinutes;
  int get evStartMinutes => _evStartMinutes;
  int get evEndMinutes => _evEndMinutes;

  // Time conversion helpers
  String minutesToTimeString(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final period = hours >= 12 ? 'PM' : 'AM';
    final displayHours = hours > 12 ? hours - 12 : (hours == 0 ? 12 : hours);
    return '${displayHours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')} $period';
  }

  int timeOfDayToMinutes(int hour, int minute) {
    return hour * 60 + minute;
  }

  /// Load settings from storage
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _mrStartMinutes = prefs.getInt(_mrStartKey) ?? 6 * 60;
      _mrEndMinutes = prefs.getInt(_mrEndKey) ?? 12 * 60;
      _evStartMinutes = prefs.getInt(_evStartKey) ?? 12 * 60;
      _evEndMinutes = prefs.getInt(_evEndKey) ?? 20 * 60;
      
      print('📋 [ShiftSettings] Loaded: MR ${minutesToTimeString(_mrStartMinutes)}-${minutesToTimeString(_mrEndMinutes)}, EV ${minutesToTimeString(_evStartMinutes)}-${minutesToTimeString(_evEndMinutes)}');
    } catch (e) {
      print('❌ [ShiftSettings] Error loading settings: $e');
    }
  }

  /// Save settings to storage
  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setInt(_mrStartKey, _mrStartMinutes);
      await prefs.setInt(_mrEndKey, _mrEndMinutes);
      await prefs.setInt(_evStartKey, _evStartMinutes);
      await prefs.setInt(_evEndKey, _evEndMinutes);
      
      print('💾 [ShiftSettings] Saved: MR ${minutesToTimeString(_mrStartMinutes)}-${minutesToTimeString(_mrEndMinutes)}, EV ${minutesToTimeString(_evStartMinutes)}-${minutesToTimeString(_evEndMinutes)}');
    } catch (e) {
      print('❌ [ShiftSettings] Error saving settings: $e');
    }
  }

  /// Set morning shift times
  void setMorningShift(int startMinutes, int endMinutes) {
    _mrStartMinutes = startMinutes;
    _mrEndMinutes = endMinutes;
  }

  /// Set evening shift times
  void setEveningShift(int startMinutes, int endMinutes) {
    _evStartMinutes = startMinutes;
    _evEndMinutes = endMinutes;
  }

  /// Determine shift based on time
  /// Returns 'Morning' or 'Evening'
  String getShiftForTime(DateTime time) {
    final timeMinutes = time.hour * 60 + time.minute;
    
    // Check if within morning shift
    if (timeMinutes >= _mrStartMinutes && timeMinutes < _mrEndMinutes) {
      return 'Morning';
    }
    
    // Check if within evening shift
    if (timeMinutes >= _evStartMinutes && timeMinutes < _evEndMinutes) {
      return 'Evening';
    }
    
    // Handle edge cases (before morning or after evening)
    // If before morning start, consider it evening (late night collection)
    if (timeMinutes < _mrStartMinutes) {
      return 'Evening';
    }
    
    // If after evening end, still evening
    if (timeMinutes >= _evEndMinutes) {
      return 'Evening';
    }
    
    // Between morning end and evening start
    if (timeMinutes >= _mrEndMinutes && timeMinutes < _evStartMinutes) {
      return 'Morning'; // Default to morning for midday gap
    }
    
    return 'Morning'; // Default fallback
  }

  /// Get shift code (MR/EV) based on time
  String getShiftCodeForTime(DateTime time) {
    return getShiftForTime(time) == 'Morning' ? 'MR' : 'EV';
  }
}
