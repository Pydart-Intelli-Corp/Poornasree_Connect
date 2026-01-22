import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/config/api_config.dart';

class RateChartService {
  static const String _cacheKey = 'rate_chart_cache';
  static const String _cacheTimestampKey = 'rate_chart_cache_timestamp';
  
  /// Fetch rate chart data for the authenticated user's society
  Future<Map<String, dynamic>> fetchRateChart(String token) async {
    try {
      print('📊 Fetching rate chart data...');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/external/ratechart'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📊 Rate Chart Response Status: ${response.statusCode}');
      print('📊 Rate Chart Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          // Save to cache on successful fetch
          await _saveToCache(data);
          return {
            'success': true,
            'data': data['data'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to fetch rate chart',
          };
        }
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'No rate chart assigned to your society',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch rate chart (${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Rate Chart Error: $e');
      return {
        'success': false,
        'message': 'Network error: Unable to fetch rate chart',
      };
    }
  }

  /// Save rate chart data to local cache
  Future<void> _saveToCache(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(data));
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Failed to save rate chart to cache: $e');
    }
  }

  /// Load rate chart data from local cache
  Future<Map<String, dynamic>?> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      
      if (cachedData != null) {
        return json.decode(cachedData);
      }
      return null;
    } catch (e) {
      print('Failed to load rate chart from cache: $e');
      return null;
    }
  }

  /// Get cache timestamp
  Future<DateTime?> getCacheTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey);
      
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clear cached data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
    } catch (e) {
      print('Failed to clear rate chart cache: $e');
    }
  }
}
