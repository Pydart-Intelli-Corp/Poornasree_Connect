import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/utils.dart';

class ReportsService {
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
      var url = ApiConfig.statistics;
      
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
      );

      print('📡 Collection Reports API response status: ${response.statusCode}');
      print('📡 Collection Reports API response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Collection Reports API success');
        
        // Calculate statistics from the data
        final records = data['data']['collections'] ?? [];
        final stats = _calculateStatistics(List<Map<String, dynamic>>.from(records));
        
        return {
          'success': true,
          'data': {
            'collections': records,
            'stats': stats,
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
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
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
}