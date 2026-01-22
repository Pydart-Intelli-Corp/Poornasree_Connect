import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';
import '../../l10n/l10n.dart';

class RateChartScreen extends StatefulWidget {
  const RateChartScreen({super.key});

  @override
  State<RateChartScreen> createState() => _RateChartScreenState();
}

class _RateChartScreenState extends State<RateChartScreen> {
  final RateChartService _rateChartService = RateChartService();
  final TextEditingController _fatController = TextEditingController();
  final TextEditingController _snfController = TextEditingController();
  final TextEditingController _clrController = TextEditingController();
  
  bool _isLoading = true;
  bool _isLoadingFromNetwork = false;
  bool _isOffline = false;
  bool _showSearch = false;
  String? _errorMessage;
  Map<String, dynamic>? _rateChartInfo;
  List<dynamic> _rateData = [];
  List<dynamic> _filteredRateData = [];
  DateTime? _cacheTimestamp;
  int? _highlightedIndex;

  @override
  void initState() {
    super.initState();
    _loadRateChart();
  }

  @override
  void dispose() {
    _fatController.dispose();
    _snfController.dispose();
    _clrController.dispose();
    super.dispose();
  }

  Future<void> _loadRateChart({bool forceRefresh = false}) async {
    // Load from cache first
    if (!forceRefresh) {
      await _loadFromCache();
    }

    // Then try to fetch from network
    await _fetchFromNetwork();
  }

  Future<void> _loadFromCache() async {
    try {
      final cachedData = await _rateChartService.loadFromCache();
      final cacheTime = await _rateChartService.getCacheTimestamp();
      
      if (cachedData != null && cachedData['success'] == true && cachedData['data'] != null) {
        setState(() {
          _rateChartInfo = cachedData['data']['info'];
          _rateData = cachedData['data']['data'] ?? [];
          _filteredRateData = _rateData;
          _cacheTimestamp = cacheTime;
          _isLoading = false;
          _isOffline = true; // Show offline indicator until network sync
        });
      } else {
        setState(() {
          _isLoading = true;
        });
      }
    } catch (e) {
      // Cache load failed, continue with network fetch
      setState(() {
        _isLoading = true;
      });
    }
  }

  Future<void> _fetchFromNetwork() async {
    setState(() {
      _isLoadingFromNetwork = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.user?.token;

      if (token == null) {
        throw Exception('No authentication token');
      }

      final result = await _rateChartService.fetchRateChart(token);

      if (result['success'] == true && result['data'] != null) {
        final cacheTime = await _rateChartService.getCacheTimestamp();
        setState(() {
          _rateChartInfo = result['data']['info'];
          _rateData = result['data']['data'] ?? [];
          _filteredRateData = _rateData;
          _cacheTimestamp = cacheTime;
          _isLoading = false;
          _isLoadingFromNetwork = false;
          _isOffline = false;
        });
      } else {
        // Network fetch failed, keep showing cached data if available
        if (_rateData.isEmpty) {
          setState(() {
            _errorMessage = result['message'] ?? 'Failed to load rate chart';
            _isLoading = false;
            _isLoadingFromNetwork = false;
          });
        } else {
          setState(() {
            _isLoadingFromNetwork = false;
            // Keep showing cached data
          });
        }
      }
    } catch (e) {
      // Network error, keep showing cached data if available
      if (_rateData.isEmpty) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _isLoadingFromNetwork = false;
        });
      } else {
        setState(() {
          _isLoadingFromNetwork = false;
          _isOffline = true;
          // Keep showing cached data
        });
      }
    }
  }

  void _searchRate() {
    final fatQuery = _fatController.text.trim();
    final snfQuery = _snfController.text.trim();
    final clrQuery = _clrController.text.trim();

    if (fatQuery.isEmpty && snfQuery.isEmpty && clrQuery.isEmpty) {
      // Reset to show all data
      setState(() {
        _filteredRateData = _rateData;
        _highlightedIndex = null;
      });
      return;
    }

    setState(() {
      _filteredRateData = _rateData.where((row) {
        bool matches = true;

        if (fatQuery.isNotEmpty) {
          final fat = row['fat']?.toString() ?? '';
          matches = matches && fat.contains(fatQuery);
        }

        if (snfQuery.isNotEmpty) {
          final snf = row['snf']?.toString() ?? '';
          matches = matches && snf.contains(snfQuery);
        }

        if (clrQuery.isNotEmpty) {
          final clr = row['clr']?.toString() ?? '';
          matches = matches && clr.contains(clrQuery);
        }

        return matches;
      }).toList();

      // Highlight first match
      if (_filteredRateData.isNotEmpty) {
        final firstMatch = _filteredRateData.first;
        _highlightedIndex = _rateData.indexOf(firstMatch);
      } else {
        _highlightedIndex = null;
      }
    });
  }

  void _clearSearch() {
    _fatController.clear();
    _snfController.clear();
    _clrController.clear();
    setState(() {
      _filteredRateData = _rateData;
      _highlightedIndex = null;
      _showSearch = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations();
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(l10n.tr('rate_chart')),
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
          IconButton(
            icon: Icon(_showSearch ? Icons.search_off : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _clearSearch();
                }
              });
            },
            tooltip: _showSearch ? l10n.tr('hide_search') : l10n.tr('search_rate'),
          ),
          if (_isLoadingFromNetwork)
            const Padding(
              padding: EdgeInsets.all(16),
              child: FlowerSpinner(size: 20),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadRateChart(forceRefresh: true),
              tooltip: l10n.tr('refresh'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: FlowerSpinner(size: 48),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : _buildRateChartView(),
    );
  }

  Widget _buildErrorView() {
    final l10n = AppLocalizations();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppTheme.warningColor,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.tr('no_rate_chart'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadRateChart(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.tr('retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateChartView() {
    final l10n = AppLocalizations();
    
    return Column(
      children: [
        // Rate Chart Info Header
        if (_rateChartInfo != null) _buildInfoHeader(),
        
        // Search Bar
        if (_showSearch) _buildSearchBar(),
        
        // Rate Data Table
        Expanded(
          child: _filteredRateData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.table_chart_outlined,
                        size: 64,
                        color: context.textSecondaryColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _rateData.isEmpty ? l10n.tr('no_rate_data') : 'No matching rates found',
                        style: TextStyle(
                          fontSize: 16,
                          color: context.textSecondaryColor,
                        ),
                      ),
                      if (_rateData.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.clear),
                          label: Text(l10n.tr('clear_search')),
                        ),
                      ],
                    ],
                  ),
                )
              : _buildRateTable(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final isDark = context.isDarkMode;
    final l10n = AppLocalizations();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.primaryGreen.withOpacity(0.1)
            : AppTheme.primaryGreen.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: context.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.search,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.tr('search_rate'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
              const Spacer(),
              if (_fatController.text.isNotEmpty || 
                  _snfController.text.isNotEmpty || 
                  _clrController.text.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.clear, size: 16),
                  label: Text(l10n.tr('clear')),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSearchField(
                  controller: _fatController,
                  label: l10n.tr('fat'),
                  hint: 'e.g., 3.5',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSearchField(
                  controller: _snfController,
                  label: l10n.tr('snf'),
                  hint: 'e.g., 8.5',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSearchField(
                  controller: _clrController,
                  label: l10n.tr('clr'),
                  hint: 'e.g., 26',
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _searchRate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                child: Text(l10n.tr('find')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: context.surfaceColor,
      ),
      onSubmitted: (_) => _searchRate(),
    );
  }

  Widget _buildInfoHeader() {
    final l10n = AppLocalizations();
    final isDark = context.isDarkMode;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.primaryGreen.withOpacity(0.15)
            : AppTheme.primaryGreen.withOpacity(0.08),
        border: Border(
          bottom: BorderSide(
            color: context.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _rateChartInfo!['fileName'] ?? l10n.tr('rate_chart'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            l10n.tr('channel'),
            _rateChartInfo!['channel'] ?? 'N/A',
          ),
          _buildInfoRow(
            l10n.tr('uploaded_date'),
            _formatDate(_rateChartInfo!['uploadedAt']),
          ),
          _buildInfoRow(
            l10n.tr('total_records'),
            '${_rateData.length}',
          ),
          if (_filteredRateData.length != _rateData.length)
            _buildInfoRow(
              l10n.tr('showing'),
              '${_filteredRateData.length} of ${_rateData.length}',
            ),
          if (_cacheTimestamp != null && _isOffline)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 14,
                    color: AppTheme.warningColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Offline - Last synced: ${_formatDateTime(_cacheTimestamp!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.warningColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateTable() {
    final l10n = AppLocalizations();
    final isDark = context.isDarkMode;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: context.borderColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Table Header (Sticky)
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.primaryGreen.withOpacity(0.2)
                    : AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  topRight: Radius.circular(7),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildHeaderCell(l10n.tr('fat'))),
                  Expanded(child: _buildHeaderCell(l10n.tr('snf'))),
                  Expanded(child: _buildHeaderCell(l10n.tr('clr'))),
                  Expanded(child: _buildHeaderCell(l10n.tr('rate'))),
                ],
              ),
            ),
            
            // Divider
            Divider(
              height: 1,
              thickness: 1,
              color: context.borderColor,
            ),
            
            // Table Body with ListView.builder for performance
            Expanded(
              child: ListView.builder(
                itemCount: _filteredRateData.length,
                itemBuilder: (context, index) {
                  final row = _filteredRateData[index];
                  final originalIndex = _rateData.indexOf(row);
                  final isEven = index.isEven;
                  final isHighlighted = originalIndex == _highlightedIndex;
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? AppTheme.primaryGreen.withOpacity(0.2)
                          : (isEven
                              ? Colors.transparent
                              : (isDark
                                  ? AppTheme.primaryGreen.withOpacity(0.08)
                                  : AppTheme.primaryGreen.withOpacity(0.04))),
                      border: index < _filteredRateData.length - 1
                          ? Border(
                              bottom: BorderSide(
                                color: context.borderColor.withOpacity(0.5),
                                width: 1,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildDataCell(row['fat']?.toString() ?? '0.0')),
                        Expanded(child: _buildDataCell(row['snf']?.toString() ?? '0.0')),
                        Expanded(child: _buildDataCell(row['clr']?.toString() ?? '0')),
                        Expanded(child: _buildDataCell(row['rate']?.toString() ?? '0.00')),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryGreen,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: context.textPrimaryColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
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
}
