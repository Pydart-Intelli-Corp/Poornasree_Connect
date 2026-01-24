import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/config/api_config.dart';

class RateChartService {
  static const String _cacheKey = 'rate_chart_cache';
  static const String _cacheTimestampKey = 'rate_chart_cache_timestamp';

  /// Fetch rate chart data for the authenticated user's society
  /// Returns data for all channels (CH1, CH2, CH3)
  Future<Map<String, dynamic>> fetchRateChart(String token) async {
    try {
      print('📊 Fetching rate chart data for all channels...');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/external/ratechart'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      print('📊 Rate Chart Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // Extract society info and channels
          final societyInfo = data['data']['society'] ?? {};
          final backendChannels = data['data']['channels'] ?? {};

          print(
            'ℹ️  Society: ${societyInfo['name']} (Code: ${societyInfo['societyCode']})',
          );
          print('📊 Available channels: ${backendChannels.keys.join(', ')}');

          final mappedChannels = <String, dynamic>{};

          // Map: COW -> CH1, BUFFALO/BUF -> CH2, MIXED/MIX -> CH3
          if (backendChannels['COW'] != null) {
            final cowData = backendChannels['COW'];
            mappedChannels['CH1'] = cowData;
            print('  ✅ COW (CH1): ${cowData['data']?.length ?? 0} records');
          }
          if (backendChannels['BUFFALO'] != null ||
              backendChannels['BUF'] != null) {
            final bufData =
                backendChannels['BUFFALO'] ?? backendChannels['BUF'];
            mappedChannels['CH2'] = bufData;
            print('  ✅ BUFFALO (CH2): ${bufData['data']?.length ?? 0} records');
          }
          if (backendChannels['MIXED'] != null ||
              backendChannels['MIX'] != null) {
            final mixData = backendChannels['MIXED'] ?? backendChannels['MIX'];
            mappedChannels['CH3'] = mixData;
            print('  ✅ MIXED (CH3): ${mixData['data']?.length ?? 0} records');
          }

          if (mappedChannels.isEmpty) {
            print('⚠️  No channels found in response');
            return {
              'success': false,
              'message': 'No rate charts available for any channel',
            };
          }

          // Save to cache on successful fetch
          final cacheData = {
            'success': true,
            'data': {'society': societyInfo, 'channels': mappedChannels},
          };
          await _saveToCache(cacheData);

          return {
            'success': true,
            'society': societyInfo,
            'channels': mappedChannels,
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
      } else if (response.statusCode >= 500) {
        return {
          'success': false,
          'message': 'Server is temporarily unavailable',
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
        'message': 'Unable to connect to server',
      };
    }
  }

  /// Save rate chart data to local cache
  Future<void> _saveToCache(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(data));
      await prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
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
