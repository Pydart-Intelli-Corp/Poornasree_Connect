import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';

class DispatchesReportScreen extends StatefulWidget {
  const DispatchesReportScreen({super.key});

  @override
  State<DispatchesReportScreen> createState() => _DispatchesReportScreenState();
}

class _DispatchesReportScreenState extends State<DispatchesReportScreen> {
  bool _isLoading = true;
  List<dynamic> _records = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check internet connection first
      final connectivityService = ConnectivityService();
      final isOnline = await connectivityService.checkConnectivity();
      
      if (!isOnline) {
        setState(() {
          _errorMessage = 'NO_INTERNET';
          _isLoading = false;
        });
        return;
      }
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.user?.token;

      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/external/reports/dispatches?limit=100&offset=0'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _records = data['data']['records'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load dispatches');
      }
    } on TimeoutException {
      setState(() {
        _errorMessage = 'CONNECTION_TIMEOUT';
        _isLoading = false;
      });
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused') ||
          e.toString().contains('Network is unreachable')) {
        setState(() {
          _errorMessage = 'NO_INTERNET';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Build error widget based on error type
  Widget _buildErrorWidget() {
    final isNoInternet = _errorMessage == 'NO_INTERNET';
    final isTimeout = _errorMessage == 'CONNECTION_TIMEOUT';
    
    IconData icon;
    Color iconColor;
    String title;
    String message;
    
    if (isNoInternet) {
      icon = Icons.cloud_off_rounded;
      iconColor = Colors.orange;
      title = 'No Internet Connection';
      message = 'Dispatches report requires an internet connection.\n\nPlease check your network and try again.';
    } else if (isTimeout) {
      icon = Icons.timer_off_rounded;
      iconColor = Colors.amber;
      title = 'Connection Timeout';
      message = 'The server took too long to respond.\nPlease check your connection and try again.';
    } else {
      icon = Icons.error_outline_rounded;
      iconColor = Colors.red.shade300;
      title = 'Error loading dispatches';
      message = _errorMessage ?? 'Unknown error occurred';
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: iconColor),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh, size: 20),
              label: Text(AppLocalizations().tr('retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_transit':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatStatus(String? status) {
    if (status == null) return '-';
    return status.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations().tr('dispatches_report')),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
            tooltip: AppLocalizations().tr('refresh'),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: FlowerSpinner(size: 48),
            )
          : _errorMessage != null
              ? _buildErrorWidget()
              : _records.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 64,
                            color: AppTheme.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No dispatches found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Dispatches data will appear here',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _records.length,
                      itemBuilder: (context, index) {
                        final record = _records[index];
                        return _buildDispatchCard(record);
                      },
                    ),
    );
  }

  Widget _buildDispatchCard(Map<String, dynamic> record) {
    return Card(
      color: AppTheme.cardDark,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppTheme.primaryGreen.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDispatchDetails(record),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        color: AppTheme.primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        record['vehicle_number'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getStatusColor(record['status']).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatStatus(record['status']),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(record['status']),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    record['dispatch_date']?.toString() ?? '-',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      record['shift']?.toString() ?? '-',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
              if (record['bmc_name'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'To: ${record['bmc_name']}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Divider(color: AppTheme.primaryGreen.withOpacity(0.15), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetric('Quantity', '${record['quantity'] ?? 0} L'),
                  _buildMetric('Fat', '${record['fat_percentage'] ?? 0}%'),
                  _buildMetric('SNF', '${record['snf_percentage'] ?? 0}%'),
                  _buildMetric('Temp', '${record['temperature'] ?? 0}°C'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showDispatchDetails(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkBg,
        title: Text(
          'Dispatch Details',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Date', record['dispatch_date'] ?? '-'),
              _buildDetailRow('Shift', record['shift'] ?? '-'),
              _buildDetailRow('BMC', record['bmc_name'] ?? '-'),
              _buildDetailRow('Quantity', '${record['quantity'] ?? 0} L'),
              _buildDetailRow('Fat %', '${record['fat_percentage'] ?? 0}'),
              _buildDetailRow('SNF %', '${record['snf_percentage'] ?? 0}'),
              _buildDetailRow('Temperature', '${record['temperature'] ?? 0}°C'),
              _buildDetailRow('Vehicle', record['vehicle_number'] ?? '-'),
              _buildDetailRow('Driver', record['driver_name'] ?? '-'),
              _buildDetailRow('Receiver', record['receiver_name'] ?? '-'),
              _buildDetailRow('Status', _formatStatus(record['status'])),
              if (record['remarks'] != null)
                _buildDetailRow('Remarks', record['remarks']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations().tr('close'), style: TextStyle(color: AppTheme.primaryGreen)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
