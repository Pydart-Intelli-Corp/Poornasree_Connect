import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../utils/utils.dart';

class CollectionsReportScreen extends StatefulWidget {
  const CollectionsReportScreen({super.key});

  @override
  State<CollectionsReportScreen> createState() => _CollectionsReportScreenState();
}

class _CollectionsReportScreenState extends State<CollectionsReportScreen> {
  final ReportsService _reportsService = ReportsService();
  bool _isLoading = true;
  bool _isLoadingFromNetwork = false;
  bool _isOffline = false;
  List<dynamic> _records = [];
  String? _errorMessage;
  DateTime? _cacheTimestamp;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    // Load from cache first
    if (!forceRefresh) {
      await _loadFromCache();
    }

    // Then try to fetch from network
    await _fetchFromNetwork();
  }

  Future<void> _loadFromCache() async {
    try {
      final cachedData = await _reportsService.loadCollectionsFromCache();
      final cacheTime = await _reportsService.getCollectionsCacheTimestamp();
      
      print('📦 [Collections] Cache loaded: ${cachedData != null}');
      if (cachedData != null) {
        print('📦 [Collections] Cache success: ${cachedData['success']}');
        print('📦 [Collections] Cache data: ${cachedData['data']}');
        if (cachedData['data'] != null) {
          print('📦 [Collections] Collections count: ${cachedData['data']['collections']?.length ?? 0}');
        }
      }
      
      if (cachedData != null && cachedData['success'] == true) {
        setState(() {
          _records = cachedData['data']['collections'] ?? [];
          _cacheTimestamp = cacheTime;
          _isLoading = false;
          _isOffline = true;
        });
        print('✅ [Collections] Loaded ${_records.length} records from cache');
      } else {
        setState(() {
          _isLoading = true;
        });
        print('⚠️ [Collections] No valid cache data');
      }
    } catch (e) {
      print('❌ [Collections] Cache load error: $e');
      setState(() {
        _isLoading = true;
      });
    }
  }

  Future<void> _fetchFromNetwork() async {
    // Don't show loading if we already have cached data
    if (_records.isEmpty) {
      setState(() {
        _isLoadingFromNetwork = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoadingFromNetwork = true;
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.user?.token;

      if (token == null) {
        throw Exception('No authentication token');
      }

      final result = await _reportsService.getCollectionReports(token);

      if (result['success'] == true) {
        final cacheTime = await _reportsService.getCollectionsCacheTimestamp();
        setState(() {
          _records = result['data']['collections'] ?? [];
          _cacheTimestamp = cacheTime;
          _isLoading = false;
          _isLoadingFromNetwork = false;
          _isOffline = false;
        });
      } else {
        // Network fetch failed, keep showing cached data if available
        setState(() {
          _isLoadingFromNetwork = false;
          if (_records.isEmpty) {
            _errorMessage = result['message'] ?? 'Failed to load collections';
            _isLoading = false;
          } else {
            _isOffline = true;
          }
        });
      }
    } catch (e) {
      // Network error - silently fail if we have cached data
      print('⚠️ [Collections] Network error (cached data available): $e');
      setState(() {
        _isLoadingFromNetwork = false;
        if (_records.isEmpty) {
          _errorMessage = e.toString();
          _isLoading = false;
        } else {
          _isOffline = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              child: Text(AppLocalizations().tr('collections_report')),
            ),
            if (_isOffline) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.cloud_off,
                size: 18,
                color: AppTheme.warningColor,
              ),
            ],
          ],
        ),
        elevation: 0,
        actions: [
          if (_isLoadingFromNetwork)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadData(forceRefresh: true),
              tooltip: AppLocalizations().tr('refresh'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadData(forceRefresh: true);
        },
        color: AppTheme.primaryGreen,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryGreen,
                ),
              )
            : _errorMessage != null
                ? _buildErrorView()
                : _records.isEmpty
                    ? _buildEmptyView()
                    : _buildListView(),
      ),
    );
  }

  Widget _buildErrorView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 64,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Data Available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No cached data available. Please connect to internet to download reports.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _loadData(forceRefresh: true),
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations().tr('retry')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.water_drop_outlined,
                size: 64,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No collections found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Collections data will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (_cacheTimestamp != null && _isOffline) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 16,
                      color: AppTheme.warningColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Offline - Last synced: ${_formatDateTime(_cacheTimestamp!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.warningColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        if (_cacheTimestamp != null && _isOffline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.warningColor.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 16,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Offline - Last synced: ${_formatDateTime(_cacheTimestamp!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.warningColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _records.length,
            itemBuilder: (context, index) {
              final record = _records[index];
              return _buildCollectionCard(record);
            },
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final l10n = AppLocalizations();
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return l10n.tr('just_now');
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildCollectionCard(Map<String, dynamic> record) {
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
        onTap: () => _showCollectionDetails(record),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      record['farmer_name'] ?? AppLocalizations().tr('unknown_farmer'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    record['collection_date']?.toString() ?? '-',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    record['collection_time']?.toString() ?? '-',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: AppTheme.primaryGreen.withOpacity(0.15), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetric('Quantity', '${record['quantity'] ?? 0} L'),
                  _buildMetric('Fat', '${record['fat_percentage'] ?? 0}%'),
                  _buildMetric('SNF', '${record['snf_percentage'] ?? 0}%'),
                  _buildMetric('Amount', '₹${record['total_amount'] ?? 0}'),
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

  void _showCollectionDetails(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkBg,
        title: Text(
          'Collection Details',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Farmer', record['farmer_name'] ?? '-'),
              _buildDetailRow('Date', record['collection_date'] ?? '-'),
              _buildDetailRow('Time', record['collection_time'] ?? '-'),
              _buildDetailRow('Shift', record['shift'] ?? '-'),
              _buildDetailRow('Quantity', '${record['quantity'] ?? 0} L'),
              _buildDetailRow('Fat %', '${record['fat_percentage'] ?? 0}'),
              _buildDetailRow('SNF %', '${record['snf_percentage'] ?? 0}'),
              _buildDetailRow('CLR', '${record['clr_value'] ?? 0}'),
              _buildDetailRow('Rate', '₹${record['rate'] ?? 0}'),
              _buildDetailRow('Amount', '₹${record['total_amount'] ?? 0}'),
              _buildDetailRow('Status', record['payment_status'] ?? '-'),
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
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
