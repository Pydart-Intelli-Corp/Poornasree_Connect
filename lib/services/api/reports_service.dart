import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/utils.dart';

class ReportsService {
  static const String _collectionsCacheKey = 'collections_report_cache';
  static const String _collectionsCacheTimestampKey = 'collections_report_cache_timestamp';

  // Fetch collection reports
  Future<Map<String, dynamic>> getCollectionReports(String token, {
    String? fromDate,
    String? toDate,
    String? machineId,
    String? societyId,
    String? bmcId,
    String? dairyId,
  }) async {
    try {
      var url = ApiConfig.collections;
      
      // Add query parameters
      final queryParams = <String, String>{};
      if (fromDate != null) queryParams['fromDate'] = fromDate;
      if (toDate != null) queryParams['toDate'] = toDate;
      if (machineId != null) queryParams['machineId'] = machineId;
      if (societyId != null) queryParams['societyId'] = societyId;
      if (bmcId != null) queryParams['bmcId'] = bmcId;
      if (dairyId != null) queryParams['dairyId'] = dairyId;
      
      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.entries
            .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
            .join('&');
      }

      print('📡 Fetching collection reports from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      print('📡 Collection Reports API response status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Collection Reports API success');
        
        // Calculate statistics from the data
        final records = data['data']['collections'] ?? [];
        final stats = _calculateStatistics(List<Map<String, dynamic>>.from(records));
        
        final result = {
          'success': true,
          'data': {
            'collections': records,
            'stats': stats,
          },
        };

        // Save to cache with proper structure
        await _saveCollectionsToCache(result);
        
        return result;
      } else if (response.statusCode >= 500) {
        return {
          'success': false,
          'message': 'Server is temporarily unavailable',
          'data': {
            'collections': [],
            'stats': _getEmptyStats(),
          },
        };
      } else {
        print('❌ Collection Reports API error: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch collection reports',
          'data': {
            'collections': [],
            'stats': _getEmptyStats(),
          },
        };
      }
    } catch (e, stackTrace) {
      print('❌ Network/Parse error in getCollectionReports: $e');
      return {
        'success': false,
        'message': 'Unable to connect to server',
        'data': {
          'collections': [],
          'stats': _getEmptyStats(),
        },
      };
    }
  }

  // Calculate statistics from collection records (similar to web app)
  Map<String, dynamic> _calculateStatistics(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      return _getEmptyStats();
    }

    double totalQuantity = 0;
    double totalAmount = 0;
    double weightedFat = 0;
    double weightedSnf = 0;
    double weightedClr = 0;
    double totalFatQuantity = 0;
    double totalSnfQuantity = 0;
    double totalClrQuantity = 0;

    for (final record in records) {
      final quantity = double.tryParse(record['quantity']?.toString() ?? '0') ?? 0;
      final amount = double.tryParse(record['total_amount']?.toString() ?? '0') ?? 0;
      final fat = double.tryParse(record['fat_percentage']?.toString() ?? '0') ?? 0;
      final snf = double.tryParse(record['snf_percentage']?.toString() ?? '0') ?? 0;
      final clr = double.tryParse(record['clr_value']?.toString() ?? '0') ?? 0;

      totalQuantity += quantity;
      totalAmount += amount;
      
      // Calculate weighted averages
      totalFatQuantity += fat * quantity;
      totalSnfQuantity += snf * quantity;
      totalClrQuantity += clr * quantity;
    }

    // Calculate weighted averages
    if (totalQuantity > 0) {
      weightedFat = totalFatQuantity / totalQuantity;
      weightedSnf = totalSnfQuantity / totalQuantity;
      weightedClr = totalClrQuantity / totalQuantity;
    }

    final averageRate = totalQuantity > 0 ? totalAmount / totalQuantity : 0;

    return {
      'totalCollections': records.length,
      'totalQuantity': totalQuantity,
      'totalAmount': totalAmount,
      'averageRate': averageRate,
      'weightedFat': weightedFat,
      'weightedSnf': weightedSnf,
      'weightedClr': weightedClr,
    };
  }

  Map<String, dynamic> _getEmptyStats() {
    return {
      'totalCollections': 0,
      'totalQuantity': 0.0,
      'totalAmount': 0.0,
      'averageRate': 0.0,
      'weightedFat': 0.0,
      'weightedSnf': 0.0,
      'weightedClr': 0.0,
    };
  }

  // Cache management methods
  Future<void> _saveCollectionsToCache(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_collectionsCacheKey, json.encode(data));
      await prefs.setInt(
        _collectionsCacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      print('Failed to save collections to cache: $e');
    }
  }

  Future<Map<String, dynamic>?> loadCollectionsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_collectionsCacheKey);

      print('📦 [Service] Loading collections from cache...');
      print('📦 [Service] Cache key: $_collectionsCacheKey');
      print('📦 [Service] Cache exists: ${cachedData != null}');
      
      if (cachedData != null) {
        final decoded = json.decode(cachedData);
        print('📦 [Service] Decoded cache: $decoded');
        return decoded;
      }
      print('⚠️ [Service] No cache found');
      return null;
    } catch (e) {
      print('❌ [Service] Failed to load collections from cache: $e');
      return null;
    }
  }

  Future<DateTime?> getCollectionsCacheTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_collectionsCacheTimestampKey);

      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}