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
  Map<String, dynamic> _allChannelsData = {}; // Stores data for all channels
  Map<String, dynamic>? _rateChartInfo;
  List<dynamic> _rateData = [];
  List<dynamic> _filteredRateData = [];
  DateTime? _cacheTimestamp;
  int? _highlightedIndex;
  String _selectedChannel = 'CH1'; // Default to Cow channel

  // Get current channel data
  Map<String, dynamic>? get _currentChannelData {
    return _allChannelsData[_selectedChannel];
  }

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
        final channels = cachedData['data']['channels'] ?? {};
        setState(() {
          _allChannelsData = Map<String, dynamic>.from(channels);
          _cacheTimestamp = cacheTime;
          _isLoading = false;
          _isOffline = true; // Show offline indicator until network sync
          // Update current channel data
          final channelData = _currentChannelData;
          if (channelData != null) {
            _rateChartInfo = channelData['info'];
            _rateData = channelData['data'] ?? [];
            _filteredRateData = _rateData;
          } else {
            _rateChartInfo = null;
            _rateData = [];
            _filteredRateData = [];
          }
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

      if (result['success'] == true && result['channels'] != null) {
        final cacheTime = await _rateChartService.getCacheTimestamp();
        final channels = result['channels'] ?? {};
        setState(() {
          _allChannelsData = Map<String, dynamic>.from(channels);
          _cacheTimestamp = cacheTime;
          _isLoading = false;
          _isLoadingFromNetwork = false;
          _isOffline = false;
          // Update current channel data
          final channelData = _currentChannelData;
          if (channelData != null) {
            _rateChartInfo = channelData['info'];
            _rateData = channelData['data'] ?? [];
            _filteredRateData = _rateData;
          } else {
            _rateChartInfo = null;
            _rateData = [];
            _filteredRateData = [];
          }
        });
      } else {
        // Network fetch failed, keep showing cached data if available
        if (_allChannelsData.isEmpty) {
          setState(() {
            _errorMessage = result['message'] ?? 'Failed to load rate chart';
            _isLoading = false;
            _isLoadingFromNetwork = false;
          });
        } else {
          setState(() {
            _isLoadingFromNetwork = false;
            _isOffline = true;
          });
        }
      }
    } catch (e) {
      // Network error, keep showing cached data if available
      if (_allChannelsData.isEmpty) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _isLoadingFromNetwork = false;
        });
      } else {
        setState(() {
          _isLoadingFromNetwork = false;
          _isOffline = true;
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

  String _getEmptyStateMessage() {
    final l10n = AppLocalizations();
    
    if (_rateData.isEmpty) {
      // No data for current channel
      if (_currentChannelData == null) {
        return l10n.tr('no_rate_chart_for_channel');
      }
      return l10n.tr('no_rate_data');
    } else {
      // Has data but no search results
      return 'No matching rates found';
    }
  }

  String _getAvailableChannelsMessage() {
    final l10n = AppLocalizations();
    final availableChannels = <String>[];
    
    if (_allChannelsData.containsKey('CH1')) availableChannels.add(l10n.tr('cow'));
    if (_allChannelsData.containsKey('CH2')) availableChannels.add(l10n.tr('buffalo'));
    if (_allChannelsData.containsKey('CH3')) availableChannels.add(l10n.tr('mixed'));
    
    if (availableChannels.isEmpty) return '';
    
    return 'Available: ${availableChannels.join(', ')}';
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
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.tr('rate_chart'),
                  style: TextStyle(
                    fontSize: SizeConfig.fontSizeXLarge,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (_isOffline) ...[
              SizedBox(width: SizeConfig.spaceSmall),
              Icon(
                Icons.cloud_off,
                size: SizeConfig.iconSizeSmall,
                color: AppTheme.warningColor,
              ),
            ],
          ],
        ),
        elevation: 0,
        actions: [
          // Channel Dropdown
          ChannelDropdownButton(
            selectedChannel: _selectedChannel,
            onChannelChanged: (channel) {
              setState(() {
                _selectedChannel = channel;
                // Update current channel data
                final channelData = _currentChannelData;
                if (channelData != null) {
                  _rateChartInfo = channelData['info'];
                  _rateData = channelData['data'] ?? [];
                  _filteredRateData = _rateData;
                } else {
                  _rateChartInfo = null;
                  _rateData = [];
                  _filteredRateData = [];
                }
                // Clear search when switching channels
                _fatController.clear();
                _snfController.clear();
                _clrController.clear();
                _highlightedIndex = null;
              });
            },
            compact: true,
          ),
          SizedBox(width: SizeConfig.spaceSmall),
          // Search Toggle
          IconButton(
            icon: Icon(
              _showSearch ? Icons.search_off : Icons.search,
              size: SizeConfig.iconSizeLarge,
            ),
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
            Padding(
              padding: EdgeInsets.all(SizeConfig.spaceRegular),
              child: FlowerSpinner(size: SizeConfig.iconSizeMedium),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: FlowerSpinner(size: SizeConfig.iconSizeHuge),
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
        padding: EdgeInsets.all(SizeConfig.spaceXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: SizeConfig.iconSizeHuge,
              color: AppTheme.warningColor,
            ),
            SizedBox(height: SizeConfig.spaceRegular),
            Text(
              l10n.tr('no_rate_chart'),
              style: TextStyle(
                fontSize: SizeConfig.fontSizeLarge,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.spaceSmall),
            Text(
              'No cached data available. Please connect to internet to download rate chart.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: SizeConfig.fontSizeRegular,
                color: context.textSecondaryColor,
              ),
              softWrap: true,
              maxLines: 3,
            ),
            SizedBox(height: SizeConfig.spaceXLarge),
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
    
    return RefreshIndicator(
      onRefresh: () async {
        await _loadRateChart(forceRefresh: true);
      },
      color: AppTheme.primaryGreen,
      child: Column(
        children: [
          // Rate Chart Info Header
          if (_rateChartInfo != null) _buildInfoHeader(),
          
          // Search Bar
          if (_showSearch) _buildSearchBar(),
          
          // Rate Data Table
          Expanded(
            child: _filteredRateData.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.table_chart_outlined,
                              size: SizeConfig.iconSizeHuge,
                              color: context.textSecondaryColor.withOpacity(0.5),
                            ),
                            SizedBox(height: SizeConfig.spaceRegular),
                            Text(
                              _getEmptyStateMessage(),
                              style: TextStyle(
                                fontSize: SizeConfig.fontSizeMedium,
                                color: context.textSecondaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_rateData.isNotEmpty) ...[
                              SizedBox(height: SizeConfig.spaceRegular),
                              TextButton.icon(
                                onPressed: _clearSearch,
                                icon: Icon(Icons.clear, size: SizeConfig.iconSizeSmall),
                                label: Text(l10n.tr('clear_search')),
                              ),
                            ],
                            if (_rateData.isEmpty && _currentChannelData == null && _allChannelsData.isNotEmpty) ...[
                              SizedBox(height: SizeConfig.spaceRegular),
                              Text(
                                _getAvailableChannelsMessage(),
                                style: TextStyle(
                                  fontSize: SizeConfig.fontSizeSmall,
                                  color: context.textSecondaryColor.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                : _buildRateTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = context.isDarkMode;
    final l10n = AppLocalizations();
    
    return Container(
      padding: EdgeInsets.all(SizeConfig.spaceRegular),
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
                size: SizeConfig.iconSizeLarge,
              ),
              SizedBox(width: SizeConfig.spaceSmall),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.tr('search_rate'),
                    style: TextStyle(
                      fontSize: SizeConfig.fontSizeRegular,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (_fatController.text.isNotEmpty || 
                  _snfController.text.isNotEmpty || 
                  _clrController.text.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearSearch,
                  icon: Icon(Icons.clear, size: SizeConfig.iconSizeSmall),
                  label: Text(l10n.tr('clear')),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: SizeConfig.spaceSmall),
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
              SizedBox(width: SizeConfig.spaceMedium),
              Expanded(
                child: _buildSearchField(
                  controller: _snfController,
                  label: l10n.tr('snf'),
                  hint: 'e.g., 8.5',
                ),
              ),
              SizedBox(width: SizeConfig.spaceMedium),
              Expanded(
                child: _buildSearchField(
                  controller: _clrController,
                  label: l10n.tr('clr'),
                  hint: 'e.g., 26',
                ),
              ),
              SizedBox(width: SizeConfig.spaceMedium),
              ElevatedButton(
                onPressed: _searchRate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.spaceXLarge,
                    vertical: SizeConfig.spaceRegular,
                  ),
                ),
                child: Text(
                  l10n.tr('find'),
                  style: TextStyle(
                    fontSize: SizeConfig.fontSizeMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
      style: TextStyle(
        fontSize: SizeConfig.fontSizeLarge,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          fontSize: SizeConfig.fontSizeRegular,
        ),
        hintStyle: TextStyle(
          fontSize: SizeConfig.fontSizeRegular,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeConfig.radiusMedium),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: SizeConfig.spaceMedium,
          vertical: SizeConfig.spaceMedium,
        ),
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
      padding: EdgeInsets.all(SizeConfig.spaceRegular),
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
                size: SizeConfig.iconSizeMedium,
              ),
              SizedBox(width: SizeConfig.spaceSmall),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _rateChartInfo!['fileName'] ?? l10n.tr('rate_chart'),
                    style: TextStyle(
                      fontSize: SizeConfig.fontSizeMedium,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.spaceSmall),
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
              padding: EdgeInsets.only(top: SizeConfig.spaceXSmall),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: SizeConfig.iconSizeSmall,
                    color: AppTheme.warningColor,
                  ),
                  SizedBox(width: SizeConfig.spaceXSmall),
                  Flexible(
                    child: Text(
                      'Offline - Last synced: ${_formatDateTime(_cacheTimestamp!)}',
                      style: TextStyle(
                        fontSize: SizeConfig.fontSizeXSmall,
                        color: AppTheme.warningColor,
                        fontStyle: FontStyle.italic,
                      ),
                      softWrap: true,
                      maxLines: 2,
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
      padding: EdgeInsets.only(top: SizeConfig.spaceXSmall),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: SizeConfig.fontSizeSmall,
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: SizeConfig.fontSizeSmall,
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
      padding: EdgeInsets.all(SizeConfig.spaceRegular),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: context.borderColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(SizeConfig.radiusMedium),
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
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.spaceSmall,
        vertical: SizeConfig.spaceMedium,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: TextStyle(
            fontSize: SizeConfig.fontSizeSmall,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryGreen,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.spaceSmall,
        vertical: SizeConfig.spaceSmall,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: TextStyle(
            fontSize: SizeConfig.fontSizeSmall,
            color: context.textPrimaryColor,
          ),
          textAlign: TextAlign.center,
        ),
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
