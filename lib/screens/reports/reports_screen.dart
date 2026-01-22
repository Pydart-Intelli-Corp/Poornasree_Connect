import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';
import '../../l10n/l10n.dart';

class ReportsScreen extends StatefulWidget {
  final bool defaultLocalMode;
  
  const ReportsScreen({super.key, this.defaultLocalMode = false});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedReport = 'collections';
  bool _isLoading = false;
  List<dynamic> _records = [];
  List<dynamic> _allRecords = [];
  String? _errorMessage;
  late bool _isLocalMode; // Toggle between local and cloud reports
  
  // Filter states
  DateTime? _fromDate;
  DateTime? _toDate;
  String _shiftFilter = 'all';
  String _channelFilter = 'all';
  String? _machineFilter;
  String? _farmerFilter;
  
  // Filter data
  List<Map<String, dynamic>> _machines = [];
  List<Map<String, dynamic>> _farmers = [];
  
  // Services
  final LocalReportsService _localReportsService = LocalReportsService();
  final ReadingsStorageService _storageService = ReadingsStorageService();
  
  // Stream subscription for auto-refresh
  StreamSubscription? _readingSubscription;
  
  // Column selection for reports
  static const List<Map<String, String>> availableColumns = [
    {'key': 'sl_no', 'label': 'Sl.No'},
    {'key': 'date_time', 'label': 'Date & Time'},
    {'key': 'farmer', 'label': 'Farmer ID'},
    {'key': 'society', 'label': 'Society'},
    {'key': 'machine', 'label': 'Machine'},
    {'key': 'shift', 'label': 'Shift'},
    {'key': 'channel', 'label': 'Channel'},
    {'key': 'fat', 'label': 'Fat %'},
    {'key': 'snf', 'label': 'SNF %'},
    {'key': 'clr', 'label': 'CLR'},
    {'key': 'protein', 'label': 'Protein %'},
    {'key': 'lactose', 'label': 'Lactose %'},
    {'key': 'salt', 'label': 'Salt %'},
    {'key': 'water', 'label': 'Water %'},
    {'key': 'temperature', 'label': 'Temp (°C)'},
    {'key': 'rate', 'label': 'Rate/L'},
    {'key': 'bonus', 'label': 'Bonus'},
    {'key': 'qty', 'label': 'Qty (L)'},
    {'key': 'amount', 'label': 'Amount'},
    // Report-specific columns
    {'key': 'dispatch_id', 'label': 'Dispatch ID'},
    {'key': 'count', 'label': 'Count'},
  ];
  
  // Default columns for email reports - report specific
  static const Map<String, List<String>> reportDefaultColumns = {
    'collections': ['sl_no', 'date_time', 'farmer', 'society', 'channel', 'fat', 'snf', 'clr', 'water', 'rate', 'bonus', 'qty', 'amount'],
    'dispatches': ['sl_no', 'date_time', 'dispatch_id', 'society', 'channel', 'fat', 'snf', 'clr', 'qty', 'rate', 'amount'],
    'sales': ['sl_no', 'date_time', 'society', 'channel', 'qty', 'rate', 'amount'],
  };
  
  // Get default columns for current report type
  List<String> get currentReportDefaultColumns => reportDefaultColumns[_selectedReport] ?? reportDefaultColumns['collections']!;
  
  // Get available columns for current report type
  List<Map<String, String>> get currentReportAvailableColumns {
    switch (_selectedReport) {
      case 'collections':
        return availableColumns.where((col) => [
          'sl_no', 'date_time', 'farmer', 'society', 'machine', 'shift', 'channel',
          'fat', 'snf', 'clr', 'protein', 'lactose', 'salt', 'water', 'temperature',
          'rate', 'bonus', 'qty', 'amount'
        ].contains(col['key'])).toList();
      case 'dispatches':
        return availableColumns.where((col) => [
          'sl_no', 'date_time', 'dispatch_id', 'society', 'machine', 'shift', 'channel',
          'fat', 'snf', 'clr', 'qty', 'rate', 'amount'
        ].contains(col['key'])).toList();
      case 'sales':
        return availableColumns.where((col) => [
          'sl_no', 'date_time', 'count', 'society', 'machine', 'shift', 'channel',
          'qty', 'rate', 'amount'
        ].contains(col['key'])).toList();
      default:
        return availableColumns;
    }
  }
  
  List<String> _selectedColumns = [];

  @override
  void initState() {
    super.initState();
    // Initialize local mode from parameter
    _isLocalMode = widget.defaultLocalMode;
    // Initialize with current report defaults
    _selectedColumns = List.from(currentReportDefaultColumns);
    // Lock to landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _loadColumnPreferences();
    
    // Initialize society/machine details then fetch data
    _initializeAndFetch();
    
    // Subscribe to new readings for auto-refresh in local mode
    _readingSubscription = _storageService.onNewReading.listen((_) {
      if (_isLocalMode && mounted) {
        // Auto-refresh when new data is received
        _fetchRecords();
      }
    });
  }
  
  /// Initialize society/machine details then fetch data
  Future<void> _initializeAndFetch() async {
    await _initSocietyDetails();
    _fetchData();
  }
  
  Future<void> _initSocietyDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      _localReportsService.setSocietyDetails(
        societyId: user.societyId ?? user.societyIdentifier,
        societyName: user.societyName ?? user.name,
      );
      
      // Fetch machine type from API if in local mode
      if (_isLocalMode && user.token != null) {
        try {
          final response = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/api/external/machines'),
            headers: {
              'Authorization': 'Bearer ${user.token}',
              'Content-Type': 'application/json',
            },
          ).timeout(const Duration(seconds: 5));
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final machines = List<Map<String, dynamic>>.from(data['data'] ?? []);
            if (machines.isNotEmpty) {
              // Use the first machine's type as default
              final machineType = machines.first['machine_type']?.toString();
              if (machineType != null && machineType.isNotEmpty) {
                _localReportsService.setMachineType(machineType);
              }
            }
          }
        } catch (e) {
          print('Error fetching machine type: $e - trying cached data');
          // Try to load from cache
          await _localReportsService.loadCachedMachineType();
        }
      }
    } else {
      // No user - try to load from cache for offline mode
      await _localReportsService.loadCachedSocietyDetails();
      await _localReportsService.loadCachedMachineType();
    }
  }

  @override
  void dispose() {
    // Cancel stream subscription
    _readingSubscription?.cancel();
    // Restore all orientations when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }
  
  Future<void> _loadColumnPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedColumns = prefs.getStringList('report_columns');
      if (savedColumns != null && savedColumns.isNotEmpty) {
        setState(() {
          _selectedColumns = savedColumns;
          // Ensure current report's default columns are always included
          for (String defaultCol in currentReportDefaultColumns) {
            if (!_selectedColumns.contains(defaultCol)) {
              _selectedColumns.add(defaultCol);
            }
          }
        });
      } else {
        // Use current report's default columns
        setState(() {
          _selectedColumns = List.from(currentReportDefaultColumns);
        });
      }
    } catch (e) {
      print('Error loading column preferences: $e');
    }
  }
  
  Future<void> _saveColumnPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('report_columns', _selectedColumns);
    } catch (e) {
      print('Error saving column preferences: $e');
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    await Future.wait([
      _fetchRecords(),
      _fetchMachines(),
    ]);
    
    // Extract farmers from records after fetching
    _extractFarmersFromRecords();
  }
  
  Future<void> _fetchMachines() async {
    try {
      if (_isLocalMode) {
        // Load machines from local storage
        final machines = await _localReportsService.getLocalMachines();
        setState(() {
          _machines = machines;
        });
        print('Fetched local machines: ${_machines.map((m) => {'id': m['id'], 'machine_id': m['machine_id']}).toList()}');
      } else {
        // Fetch from cloud API
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.user?.token;
        if (token == null) return;
        
        try {
          final response = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/api/external/machines'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ).timeout(const Duration(seconds: 10));
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            setState(() {
              _machines = List<Map<String, dynamic>>.from(data['data'] ?? []);
            });
            print('Fetched machines: ${_machines.map((m) => {'id': m['id'], 'machine_id': m['machine_id'], 'machine_type': m['machine_type']}).toList()}');
          } else {
            // API error - try cache
            await _loadCachedMachines();
          }
        } catch (e) {
          // Network error - try cache
          print('Error fetching machines from API: $e - trying cache');
          await _loadCachedMachines();
        }
      }
    } catch (e) {
      print('Error fetching machines: $e');
    }
  }
  
  Future<void> _loadCachedMachines() async {
    final cacheService = OfflineCacheService();
    final cachedMachines = await cacheService.getCachedMachines();
    if (cachedMachines.isNotEmpty) {
      setState(() {
        _machines = List<Map<String, dynamic>>.from(cachedMachines);
      });
      print('Loaded cached machines: ${_machines.length}');
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
    String buttonText;
    
    if (isNoInternet) {
      icon = Icons.cloud_off_rounded;
      iconColor = Colors.orange;
      title = 'No Internet Connection';
      message = 'Cloud reports require an internet connection.\nPlease check your network and try again,\nor switch to Local Mode to view offline reports.';
      buttonText = 'Retry';
    } else if (isTimeout) {
      icon = Icons.timer_off_rounded;
      iconColor = Colors.amber;
      title = 'Connection Timeout';
      message = 'The server took too long to respond.\nPlease check your connection and try again.';
      buttonText = 'Retry';
    } else {
      icon = Icons.error_outline_rounded;
      iconColor = Colors.red.shade300;
      title = 'Error loading $_selectedReport';
      message = _errorMessage ?? AppLocalizations().tr('unknown_error');
      buttonText = 'Retry';
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with background
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondaryColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () {
                    HapticFeedback.lightImpact();
                    _fetchData();
                  },
                  icon: _isLoading 
                      ? const FlowerSpinner(size: 16)
                      : const Icon(Icons.refresh, size: 20),
                  label: Text(buttonText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                if (isNoInternet && !_isLocalMode) ...[
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _isLocalMode = true;
                        _errorMessage = null;
                      });
                      _fetchData();
                    },
                    icon: const Icon(Icons.smartphone, size: 20),
                    label: Text(AppLocalizations().tr('local_mode')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryTeal,
                      side: BorderSide(color: AppTheme.primaryTeal, width: 2),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show a reusable no internet dialog
  void _showNoInternetDialog(BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: context.textSecondaryColor),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              // Retry connectivity check
              final isOnline = await ConnectivityService().checkConnectivity();
              if (isOnline) {
                CustomSnackbar.showSuccess(
                  context,
                  message: AppLocalizations().tr('connected'),
                  submessage: AppLocalizations().tr('try_again'),
                );
              } else {
                CustomSnackbar.showError(
                  context,
                  message: AppLocalizations().tr('offline_status'),
                  submessage: AppLocalizations().tr('no_internet_message'),
                );
              }
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(AppLocalizations().tr('retry')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  void _extractFarmersFromRecords() {
    if (_selectedReport != 'collections' || _allRecords.isEmpty) {
      setState(() {
        _farmers = [];
      });
      return;
    }

    // Extract unique farmers from records
    final Map<String, Map<String, dynamic>> uniqueFarmers = {};
    
    for (var record in _allRecords) {
      final farmerId = record['farmer_id']?.toString();
      final farmerName = record['farmer_name']?.toString();
      
      if (farmerId != null && farmerName != null && !uniqueFarmers.containsKey(farmerId)) {
        uniqueFarmers[farmerId] = {
          'id': farmerId,
          'name': farmerName,
        };
      }
    }
    
    setState(() {
      _farmers = uniqueFarmers.values.toList()..sort((a, b) => a['name'].compareTo(b['name']));
      print('Extracted ${_farmers.length} unique farmers from records');
    });
  }

  Future<void> _fetchRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLocalMode) {
        // Fetch from local storage
        final records = await _localReportsService.getCollectionRecords(
          fromDate: _fromDate,
          toDate: _toDate,
          machineFilter: _machineFilter,
          farmerFilter: _farmerFilter,
          shiftFilter: _shiftFilter,
          channelFilter: _channelFilter,
        );
        
        setState(() {
          _allRecords = records;
          _applyFilters();
          _isLoading = false;
        });
        
        _extractFarmersFromRecords();
      } else {
        // Check connectivity first for cloud reports
        final connectivityService = ConnectivityService();
        final isOnline = await connectivityService.checkConnectivity();
        
        if (!isOnline) {
          setState(() {
            _errorMessage = 'NO_INTERNET';
            _isLoading = false;
          });
          return;
        }
        
        // Fetch from cloud API
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.user?.token;

        if (token == null) {
          throw Exception('No authentication token');
        }

        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/external/reports/$_selectedReport?limit=50&offset=0'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final records = data['data']['records'] ?? [];
          print('DEBUG: Loaded ${records.length} records');
          if (records.isNotEmpty) {
            print('DEBUG: First record keys: ${(records[0] as Map).keys.toList()}');
            print('DEBUG: First record machine_id: ${records[0]['machine_id']}');
            print('DEBUG: Sample machine_ids in records: ${records.take(5).map((r) => r['machine_id']).toList()}');
          }
          setState(() {
            _allRecords = records;
            _applyFilters();
            _isLoading = false;
          });
          
          // Extract farmers from records after loading
          _extractFarmersFromRecords();
        } else {
          throw Exception('Failed to load $_selectedReport');
        }
      }
    } on TimeoutException {
      setState(() {
        _errorMessage = 'CONNECTION_TIMEOUT';
        _isLoading = false;
      });
    } catch (e) {
      // Check if it's a network error
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          // Restore portrait orientation after going back
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations().tr('reports_management')),
          elevation: 0,
          actions: [
            // Local/Cloud toggle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.borderColor,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggleOption(AppLocalizations().tr('cloud'), Icons.cloud_outlined, !_isLocalMode, false),
                  const SizedBox(width: 4),
                  _buildToggleOption(AppLocalizations().tr('local'), Icons.storage_outlined, _isLocalMode, true),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildReportTypeChip(
              AppLocalizations().tr('collections'),
              'collections',
              Icons.water_drop_outlined,
            ),
            // Hide Dispatches and Sales buttons in local mode
            if (!_isLocalMode) ...[
              const SizedBox(width: 4),
              _buildReportTypeChip(
                AppLocalizations().tr('dispatches'),
                'dispatches',
                Icons.local_shipping_outlined,
              ),
              const SizedBox(width: 4),
              _buildReportTypeChip(
                AppLocalizations().tr('sales'),
                'sales',
                Icons.sell_outlined,
              ),
            ],
            const SizedBox(width: 12),
            // Email button
            Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: const Icon(Icons.email_outlined, size: 20),
                  onPressed: _records.isEmpty ? null : () => _showEmailDialog(),
                  tooltip: AppLocalizations().tr('email_report'),
                  color: context.textPrimaryColor,
                );
              }
            ),
            // Refresh button
            IconButton(
              icon: _isLoading 
                  ? const FlowerSpinner(size: 16) 
                  : const Icon(Icons.refresh_outlined, size: 20),
              onPressed: _isLoading ? null : () {
                HapticFeedback.lightImpact();
                _fetchData();
              },
              tooltip: AppLocalizations().tr('refresh_data'),
              color: context.textPrimaryColor,
            ),
            // Sync button (only show in local mode)
            if (_isLocalMode)
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.cloud_upload_outlined, size: 20),
                  onPressed: () => _showSyncDialog(context),
                  tooltip: AppLocalizations().tr('sync_to_cloud'),
                  color: context.textPrimaryColor,
                ),
              ),
            // Clear local data button (only show in local mode)
            if (_isLocalMode)
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _showClearLocalDataDialog(context),
                  tooltip: AppLocalizations().tr('clear_local_data'),
                  color: context.textPrimaryColor,
                ),
              ),
            // Filter button with badge
            Builder(
              builder: (BuildContext context) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.filter_list, size: 20),
                      onPressed: () => _showFiltersDropdown(context),
                      tooltip: AppLocalizations().tr('filters'),
                      color: context.textPrimaryColor,
                    ),
                    if (_fromDate != null || _toDate != null || _shiftFilter != 'all' || _channelFilter != 'all' || _machineFilter != null || _farmerFilter != null)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              }
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
        children: [
          // Report Content - Table View
          Expanded(
            child: _isLoading
                ? const Center(
                    child: FlowerSpinner(
                      size: 50,
                    ),
                  )
                : _errorMessage != null
                    ? _buildErrorWidget()
                    : _records.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getReportIcon(_selectedReport),
                                  size: 64,
                                  color: context.textSecondaryColor.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No ${_selectedReport} found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_getReportTitle(_selectedReport)} data will appear here',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildDataTable(),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildToggleOption(String label, IconData icon, bool isSelected, bool isLocalMode) {
    return InkWell(
      onTap: () {
        setState(() {
          _isLocalMode = isLocalMode;
        });
        HapticFeedback.lightImpact();
        _fetchData();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? context.cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppTheme.primaryGreen : context.textSecondaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primaryGreen : context.textSecondaryColor,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeChip(String label, String value, IconData icon) {
    final isSelected = _selectedReport == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedReport = value;
          // Reset column selection to new report's defaults when switching report types
          _selectedColumns = List.from(currentReportDefaultColumns);
        });
        // Save the new column preferences
        _saveColumnPreferences();
        _fetchData();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryGreen
                : context.borderColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : context.textPrimaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : context.textPrimaryColor,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getReportIcon(String reportType) {
    switch (reportType) {
      case 'collections':
        return Icons.water_drop_outlined;
      case 'dispatches':
        return Icons.local_shipping_outlined;
      case 'sales':
        return Icons.sell_outlined;
      default:
        return Icons.assessment_outlined;
    }
  }
  void _applyFilters() {
    List<dynamic> filtered = List.from(_allRecords);
    
    // Date from filter
    if (_fromDate != null) {
      final fromDateStr = '${_fromDate!.year}-${_fromDate!.month.toString().padLeft(2, '0')}-${_fromDate!.day.toString().padLeft(2, '0')}';
      if (_selectedReport == 'collections') {
        filtered = filtered.where((r) => (r['collection_date'] ?? '').toString().compareTo(fromDateStr) >= 0).toList();
      } else if (_selectedReport == 'dispatches') {
        filtered = filtered.where((r) => (r['dispatch_date'] ?? '').toString().compareTo(fromDateStr) >= 0).toList();
      } else if (_selectedReport == 'sales') {
        filtered = filtered.where((r) => (r['sales_date'] ?? '').toString().compareTo(fromDateStr) >= 0).toList();
      }
    }
    
    // Date to filter
    if (_toDate != null) {
      final toDateStr = '${_toDate!.year}-${_toDate!.month.toString().padLeft(2, '0')}-${_toDate!.day.toString().padLeft(2, '0')}';
      if (_selectedReport == 'collections') {
        filtered = filtered.where((r) => (r['collection_date'] ?? '').toString().compareTo(toDateStr) <= 0).toList();
      } else if (_selectedReport == 'dispatches') {
        filtered = filtered.where((r) => (r['dispatch_date'] ?? '').toString().compareTo(toDateStr) <= 0).toList();
      } else if (_selectedReport == 'sales') {
        filtered = filtered.where((r) => (r['sales_date'] ?? '').toString().compareTo(toDateStr) <= 0).toList();
      }
    }
    
    // Shift filter
    if (_shiftFilter != 'all') {
      if (_selectedReport == 'sales') {
        // For sales report, check multiple possible shift field names
        filtered = filtered.where((r) {
          final shiftValue = r['shift_type'] ?? r['shift'] ?? r['shift_name'] ?? '';
          final formattedShift = _formatShift(shiftValue.toString()).toLowerCase();
          return formattedShift.contains(_shiftFilter);
        }).toList();
      } else {
        // For collections and dispatches
        filtered = filtered.where((r) {
          final formattedShift = _formatShift(r['shift_type']).toLowerCase();
          return formattedShift.contains(_shiftFilter);
        }).toList();
      }
    }
    
    // Channel filter
    if (_channelFilter != 'all') {
      filtered = filtered.where((r) => _formatChannel(r['channel']) == _channelFilter).toList();
    }
    
    // Machine filter (works for collections, dispatches, and sales)
    if (_machineFilter != null) {
      filtered = filtered.where((r) {
        String recordMachineId = r['machine_id']?.toString() ?? '';
        return recordMachineId == _machineFilter;
      }).toList();
    }
    
    // Farmer filter
    if (_farmerFilter != null && _selectedReport == 'collections') {
      filtered = filtered.where((r) => r['farmer_id']?.toString() == _farmerFilter).toList();
    }
    
    setState(() {
      _records = filtered;
    });
  }
  
  void _clearFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _shiftFilter = 'all';
      _channelFilter = 'all';
      _machineFilter = null;
      _farmerFilter = null;
      _applyFilters();
    });
  }

  void _showSyncDialog(BuildContext context) async {
    // Check internet connection first
    final connectivityService = ConnectivityService();
    final isOnline = await connectivityService.checkConnectivity();
    
    if (!isOnline) {
      _showNoInternetDialog(
        context,
        title: AppLocalizations().tr('cannot_sync'),
        message: AppLocalizations().tr('sync_requires_internet_msg'),
        icon: Icons.cloud_sync,
      );
      return;
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final LocalSyncService syncService = LocalSyncService();
    
    bool isSyncing = false;
    int syncedCount = 0;
    int totalCount = 0;
    Map<String, int>? syncSummary;
    String? syncMessage;
    bool syncComplete = false;
    bool isLoadingSummary = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setState) {
          // Load sync summary with cloud check on first build
          if (syncSummary == null && !isSyncing && !syncComplete && isLoadingSummary) {
            isLoadingSummary = false;
            syncService.getSyncSummary(
              token: user?.token,
              checkCloud: true, // Enable smart pending count
            ).then((summary) {
              setState(() {
                syncSummary = summary;
              });
            }).catchError((e) {
              // Fallback to local count if cloud check fails
              print('⚠️ Cloud check failed, using local count: $e');
              syncService.getSyncSummary(checkCloud: false).then((summary) {
                setState(() {
                  syncSummary = summary;
                });
              });
            });
          }

          return AlertDialog(
            backgroundColor: context.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.cloud_sync, color: AppTheme.primaryGreen, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations().tr('sync_to_cloud'),
                  style: TextStyle(color: context.textPrimaryColor, fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: SizedBox(
              width: 350,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (syncSummary == null && !syncComplete) ...[
                      // Loading summary with cloud check
                      Center(
                        child: Column(
                          children: [
                            const FlowerSpinner(size: 32),
                            const SizedBox(height: 12),
                            Text(
                              'Checking cloud for duplicates...',
                              style: TextStyle(color: context.textSecondaryColor, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (syncSummary != null && !syncComplete) ...[
                      // Sync summary before syncing
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Column(
                          children: [
                            _buildSyncStatRow(AppLocalizations().tr('total_local'), syncSummary!['total'] ?? 0, Icons.storage),
                            const SizedBox(height: 6),
                            _buildSyncStatRow(AppLocalizations().tr('pending'), syncSummary!['pending'] ?? 0, Icons.hourglass_empty, color: Colors.orange),
                            const SizedBox(height: 6),
                            _buildSyncStatRow(AppLocalizations().tr('synced'), syncSummary!['synced'] ?? 0, Icons.check_circle, color: AppTheme.primaryGreen),
                            const SizedBox(height: 6),
                            _buildSyncStatRow(AppLocalizations().tr('duplicates'), syncSummary!['duplicates'] ?? 0, Icons.content_copy, color: Colors.blue),
                            if ((syncSummary!['errors'] ?? 0) > 0) ...[
                              const SizedBox(height: 6),
                              _buildSyncStatRow(AppLocalizations().tr('errors'), syncSummary!['errors'] ?? 0, Icons.error_outline, color: Colors.red),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if ((syncSummary!['pending'] ?? 0) == 0)
                        Container(
                          padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppLocalizations().tr('all_records_synced'),
                                style: TextStyle(color: AppTheme.primaryGreen, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Text(
                        '${syncSummary!['pending']} ${AppLocalizations().tr('records_will_upload')}',
                        style: TextStyle(color: context.textSecondaryColor, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      // Info note about duplicate detection
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Sync compares Farmer ID, Date & all quality parameters (2 decimal precision) to prevent duplicates',
                                style: TextStyle(color: Colors.blue.shade700, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  if (isSyncing) ...[
                    // Sync in progress
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: totalCount > 0 ? syncedCount / totalCount : null,
                      backgroundColor: context.surfaceColor,
                      valueColor: AlwaysStoppedAnimation(AppTheme.primaryGreen),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        '${AppLocalizations().tr('syncing_progress')} $syncedCount / $totalCount',
                        style: TextStyle(color: context.textSecondaryColor, fontSize: 13),
                      ),
                    ),
                  ],
                  if (syncComplete && syncMessage != null) ...[
                    // Sync complete
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.cloud_done, color: AppTheme.primaryGreen, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations().tr('sync_complete_title'),
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            syncMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.textSecondaryColor, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                ),
              ),
            ),
            actions: [
              if (!isSyncing && !syncComplete)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations().tr('cancel'), style: TextStyle(color: context.textSecondaryColor)),
                ),
              if (!isSyncing && !syncComplete && (syncSummary?['pending'] ?? 0) > 0)
                ElevatedButton.icon(
                  onPressed: () async {
                    if (user?.token == null) {
                      CustomSnackbar.showError(
                        context,
                        message: AppLocalizations().tr('please_login_sync'),
                      );
                      return;
                    }

                    setState(() {
                      isSyncing = true;
                      totalCount = syncSummary?['pending'] ?? 0;
                      syncedCount = 0;
                    });

                    final result = await syncService.syncToCloud(
                      token: user!.token!,
                      societyId: user.societyId ?? user.id,
                      onProgress: (synced, total) {
                        setState(() {
                          syncedCount = synced;
                          totalCount = total;
                        });
                      },
                    );

                    setState(() {
                      isSyncing = false;
                      syncComplete = true;
                      syncMessage = '${result['synced']} synced, ${result['duplicates']} duplicates, ${result['errors']} errors';
                    });

                    // Refresh the local reports after sync
                    _fetchData();
                  },
                  icon: const Icon(Icons.cloud_upload, size: 18),
                  label: Text(AppLocalizations().tr('start_sync')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              if (syncComplete)
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(AppLocalizations().tr('done')),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSyncStatRow(String label, int value, IconData icon, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color ?? context.textSecondaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: context.textSecondaryColor, fontSize: 13),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (color ?? context.textSecondaryColor).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value.toString(),
            style: TextStyle(
              color: color ?? context.textPrimaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _showClearLocalDataDialog(BuildContext context) {
    final LocalSyncService syncService = LocalSyncService();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_forever, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations().tr('clear_local_data'),
              style: TextStyle(color: context.textPrimaryColor, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations().tr('delete_local_warning'),
              style: TextStyle(color: context.textSecondaryColor, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations().tr('unsynced_data_warning'),
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations().tr('cancel'), style: TextStyle(color: context.textSecondaryColor)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              
              // Clear all local readings
              await _storageService.clearAllReadings();
              
              // Also clear sync status
              await syncService.resetAllSyncStatus();
              
              // Refresh the view
              _fetchData();
              
              if (mounted) {
                CustomSnackbar.showSuccess(
                  context,
                  message: AppLocalizations().tr('data_cleared'),
                );
              }
            },
            icon: const Icon(Icons.delete_forever, size: 18),
            label: Text(AppLocalizations().tr('clear_all')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showEmailDialog() async {
    // Check internet connection first
    final connectivityService = ConnectivityService();
    final isOnline = await connectivityService.checkConnectivity();
    
    if (!isOnline) {
      _showNoInternetDialog(
        context,
        title: AppLocalizations().tr('cannot_send_email'),
        message: AppLocalizations().tr('no_internet_message'),
        icon: Icons.email_outlined,
      );
      return;
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEmail = authProvider.user?.email ?? '';
    
    bool isLoading = false;
    // Use current report's default columns
    List<String> tempSelectedColumns = List.from(currentReportDefaultColumns);
    // Add any additional selected columns that are not in defaults
    for (String col in _selectedColumns) {
      if (!tempSelectedColumns.contains(col)) {
        tempSelectedColumns.add(col);
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.email_outlined, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 8),
              Text(
                AppLocalizations().tr('email_report'),
                style: TextStyle(color: context.textPrimaryColor, fontSize: 18),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            height: MediaQuery.of(context).size.height * 0.7, // Constrain height
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations().tr('send_email_description'),
                    style: TextStyle(color: context.textSecondaryColor, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.email_outlined, color: AppTheme.primaryGreen, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            userEmail,
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Column Selection Section
                  Row(
                    children: [
                      Text(
                        AppLocalizations().tr('report_columns'),
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${tempSelectedColumns.length} ${AppLocalizations().tr('selected')}',
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          _showColumnSelectionDialog(context, tempSelectedColumns, (newColumns) {
                            setState(() {
                              tempSelectedColumns = newColumns;
                            });
                          });
                        },
                        icon: Icon(
                          Icons.tune,
                          size: 16,
                          color: AppTheme.primaryGreen,
                        ),
                        label: Text(
                          AppLocalizations().tr('select_columns'),
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Selected columns preview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                    ),
                    child: Wrap(
                      spacing: 3,
                      runSpacing: 3,
                      children: tempSelectedColumns.take(15).map((columnKey) {
                        final column = currentReportAvailableColumns.firstWhere(
                          (col) => col['key'] == columnKey,
                          orElse: () => <String, String>{'key': columnKey, 'label': columnKey},
                        );
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3), width: 0.5),
                          ),
                          child: Text(
                            column['label']!,
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList()..addAll(
                        tempSelectedColumns.length > 15 ? [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.textSecondaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+${tempSelectedColumns.length - 15} ${AppLocalizations().tr('more')}',
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ] : [],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  Text(
                    '${AppLocalizations().tr('reports')}: ${_records.length} ${_selectedReport} ${AppLocalizations().tr('records')}, ${tempSelectedColumns.length} ${AppLocalizations().tr('columns')}',
                    style: TextStyle(color: context.textSecondaryColor, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(AppLocalizations().tr('cancel'), style: TextStyle(color: context.textSecondaryColor)),
            ),
            ElevatedButton.icon(
              onPressed: isLoading || userEmail.isEmpty || tempSelectedColumns.isEmpty
                  ? null 
                  : () async {
                      setState(() => isLoading = true);
                      try {
                        // Save column preferences
                        this.setState(() {
                          _selectedColumns = List.from(tempSelectedColumns);
                        });
                        await _saveColumnPreferences();
                        
                        // Send email with selected columns
                        await _sendEmailReport(userEmail, tempSelectedColumns);
                        Navigator.pop(context);
                        CustomSnackbar.showSuccess(
                          context,
                          message: 'Report sent successfully',
                          submessage: 'Report has been sent to $userEmail',
                        );
                      } catch (e) {
                        setState(() => isLoading = false);
                        CustomSnackbar.showError(
                          context,
                          message: 'Failed to send report',
                          submessage: e.toString(),
                        );
                      }
                    },
              icon: isLoading 
                  ? const FlowerSpinner(
                      size: 16,
                    )
                  : const Icon(Icons.send, size: 16),
              label: Text(isLoading ? AppLocalizations().tr('sending') : AppLocalizations().tr('send_report')),
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

  Future<void> _sendEmailReport(String email, List<String> selectedColumns) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.user?.token;
      
      if (token == null) {
        throw Exception('No authentication token');
      }

      // Generate report stats (same calculation as web version)
      Map<String, dynamic> stats = _calculateReportStats();
      
      // Generate date range string
      final dateRange = _fromDate != null && _toDate != null
          ? '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year} To ${_toDate!.day}/${_toDate!.month}/${_toDate!.year}'
          : 'All Dates';

      // Generate CSV content (matching web version exactly)
      String csvContent = _generateCSVContent(stats, dateRange, selectedColumns);
      
      // Generate PDF content (we'll send the data to server to create PDF)
      String pdfContent = await _generatePDFContent(stats, dateRange, selectedColumns);

      // Call the email API
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/user/reports/send-email'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'csvContent': csvContent,
          'pdfContent': pdfContent,
          'reportType': _getReportTitle(_selectedReport),
          'dateRange': dateRange,
          'stats': stats,
        }),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to send email');
      }

    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Map<String, dynamic> _calculateReportStats() {
    if (_records.isEmpty) {
      return {
        'totalCollections': 0,
        'totalDispatches': 0,
        'totalSales': 0,
        'totalQuantity': 0.0,
        'totalAmount': 0.0,
        'averageRate': 0.0,
        'weightedFat': 0.0,
        'weightedSnf': 0.0,
        'weightedClr': 0.0,
      };
    }

    double totalQuantity = 0.0;
    double totalAmount = 0.0;
    double weightedFat = 0.0;
    double weightedSnf = 0.0;
    double weightedClr = 0.0;

    for (var record in _records) {
      double quantity = double.tryParse(record['quantity']?.toString() ?? '0') ?? 0;
      double amount = double.tryParse(record['total_amount']?.toString() ?? '0') ?? 0;
      
      totalQuantity += quantity;
      totalAmount += amount;
      
      if (_selectedReport != 'sales') {
        double fat = double.tryParse(record['fat_percentage']?.toString() ?? '0') ?? 0;
        double snf = double.tryParse(record['snf_percentage']?.toString() ?? '0') ?? 0;
        double clr = double.tryParse(record['clr_value']?.toString() ?? '0') ?? 0;
        
        weightedFat += fat * quantity;
        weightedSnf += snf * quantity;
        weightedClr += clr * quantity;
      }
    }

    if (totalQuantity > 0) {
      weightedFat /= totalQuantity;
      weightedSnf /= totalQuantity;
      weightedClr /= totalQuantity;
    }

    return {
      'totalCollections': _selectedReport == 'collections' ? _records.length : 0,
      'totalDispatches': _selectedReport == 'dispatches' ? _records.length : 0,
      'totalSales': _selectedReport == 'sales' ? _records.length : 0,
      'totalQuantity': totalQuantity,
      'totalAmount': totalAmount,
      'averageRate': totalQuantity > 0 ? totalAmount / totalQuantity : 0.0,
      'weightedFat': weightedFat,
      'weightedSnf': weightedSnf,
      'weightedClr': weightedClr,
    };
  }

  String _generateCSVContent(Map<String, dynamic> stats, String dateRange, List<String> selectedColumns) {
    List<List<String>> csvData = [];
    
    // Header information (matching web version)
    csvData.add(['POORNASREE EQUIPMENTS MILK ${_selectedReport.toUpperCase()} REPORT']);
    csvData.add(['Admin Report with Weighted Averages']);
    csvData.add([]);
    csvData.add(['Report Generated:', DateTime.now().toString().substring(0, 19)]);
    csvData.add(['Date Range:', dateRange]);
    
    if (_selectedReport == 'collections') {
      csvData.add(['Total Collections:', stats['totalCollections'].toString()]);
    } else if (_selectedReport == 'dispatches') {
      csvData.add(['Total Dispatches:', stats['totalDispatches'].toString()]);
    } else {
      csvData.add(['Total Sales:', stats['totalSales'].toString()]);
    }
    
    csvData.add(['Total Quantity (L):', stats['totalQuantity'].toStringAsFixed(2)]);
    csvData.add(['Total Amount (₹):', stats['totalAmount'].toStringAsFixed(2)]);
    csvData.add(['Average Rate (₹/L):', stats['averageRate'].toStringAsFixed(2)]);
    
    if (_selectedReport != 'sales') {
      csvData.add(['Weighted FAT (%):', stats['weightedFat'].toStringAsFixed(2)]);
      csvData.add(['Weighted SNF (%):', stats['weightedSnf'].toStringAsFixed(2)]);
      csvData.add(['Weighted CLR:', stats['weightedClr'].toStringAsFixed(2)]);
    }
    
    csvData.add([]);
    
    // Generate dynamic headers based on selected columns
    List<String> headers = [];
    
    for (String columnKey in selectedColumns) {
      final column = availableColumns.firstWhere((col) => col['key'] == columnKey, orElse: () => <String, String>{'key': columnKey, 'label': columnKey});
      headers.add(column['label']!);
    }
    csvData.add(headers);
    
    // Generate data rows with selected columns
    for (int i = 0; i < _records.length; i++) {
      var record = _records[i];
      List<String> row = [];
      
      for (String columnKey in selectedColumns) {
        String value = '';
        
        switch (columnKey) {
          case 'sl_no':
            value = (i + 1).toString();
            break;
          case 'date_time':
            String date = '';
            String time = '';
            
            if (_selectedReport == 'collections') {
              date = record['collection_date']?.toString() ?? '';
              time = record['collection_time']?.toString() ?? '';
            } else if (_selectedReport == 'dispatches') {
              date = record['dispatch_date']?.toString() ?? '';
              time = record['dispatch_time']?.toString() ?? '';
            } else {
              date = record['sales_date']?.toString() ?? '';
              time = record['sales_time']?.toString() ?? '';
            }
            
            if (date.isNotEmpty && time.isNotEmpty) {
              value = '$date $time';
            } else if (date.isNotEmpty) {
              value = date;
            } else if (time.isNotEmpty) {
              value = time;
            } else {
              value = '';
            }
            break;
          case 'farmer':
            // Show only farmer ID
            value = record['farmer_id']?.toString() ?? '';
            break;
          case 'society':
            String societyId = record['society_id']?.toString() ?? '';
            String societyName = record['society_name']?.toString() ?? '';
            if (societyId.isNotEmpty && societyName.isNotEmpty) {
              value = '$societyId - $societyName';
            } else if (societyId.isNotEmpty) {
              value = societyId;
            } else if (societyName.isNotEmpty) {
              value = societyName;
            } else {
              value = '';
            }
            break;
          case 'machine':
            // Handle different field names across report types
            String machineId = record['machine_id']?.toString() ?? record['machine']?.toString() ?? '';
            String machineType = record['machine_type']?.toString() ?? record['machine_name']?.toString() ?? '';
            if (machineId.isNotEmpty && machineType.isNotEmpty) {
              value = '$machineId ($machineType)';
            } else if (machineId.isNotEmpty) {
              value = machineId;
            } else if (machineType.isNotEmpty) {
              value = machineType;
            } else {
              value = '';
            }
            break;
          case 'shift':
            if (_selectedReport == 'sales') {
              // For sales report, check multiple possible shift field names
              final shiftValue = record['shift_type'] ?? record['shift'] ?? record['shift_name'] ?? '';
              value = _formatShift(shiftValue.toString());
            } else {
              // For collections and dispatches
              final shiftValue = record['shift_type'] ?? '';
              value = _formatShift(shiftValue.toString());
            }
            break;
          case 'channel':
            final channelValue = record['channel'] ?? '';
            value = _formatChannel(channelValue.toString());
            break;
          case 'fat':
            value = record['fat_percentage']?.toString() ?? '';
            break;
          case 'snf':
            value = record['snf_percentage']?.toString() ?? '';
            break;
          case 'clr':
            value = record['clr_value']?.toString() ?? '';
            break;
          case 'protein':
            value = record['protein_percentage']?.toString() ?? '';
            break;
          case 'lactose':
            value = record['lactose_percentage']?.toString() ?? '';
            break;
          case 'salt':
            value = record['salt_percentage']?.toString() ?? '';
            break;
          case 'water':
            value = record['water_percentage']?.toString() ?? '';
            break;
          case 'temperature':
            value = record['temperature']?.toString() ?? '';
            break;
          case 'rate':
            value = record['rate_per_liter']?.toString() ?? '';
            break;
          case 'bonus':
            value = record['bonus']?.toString() ?? '';
            break;
          case 'qty':
            value = record['quantity']?.toString() ?? '';
            break;
          case 'amount':
            value = record['total_amount']?.toString() ?? '';
            break;
          case 'dispatch_id':
            value = record['dispatch_id']?.toString() ?? '';
            break;
          case 'count':
            value = record['count']?.toString() ?? '';
            break;
        }
        
        row.add(value);
      }
      
      csvData.add(row);
    }

    // Add bottom summary details (like web app)
    csvData.add([]);
    csvData.add(['=== REPORT SUMMARY ===']);
    csvData.add([]);
    
    // Column summaries for applicable columns
    if (selectedColumns.contains('qty')) {
      double totalQty = _records.fold(0.0, (sum, record) => sum + (double.tryParse(record['quantity']?.toString() ?? '0') ?? 0));
      csvData.add(['Total Quantity (Liters):', totalQty.toStringAsFixed(2)]);
    }
    
    if (selectedColumns.contains('amount')) {
      double totalAmt = _records.fold(0.0, (sum, record) => sum + (double.tryParse(record['total_amount']?.toString() ?? '0') ?? 0));
      csvData.add(['Total Amount (₹):', totalAmt.toStringAsFixed(2)]);
    }
    
    if (selectedColumns.contains('fat') && _selectedReport != 'sales') {
      csvData.add(['Weighted Average FAT (%):', stats['weightedFat'].toStringAsFixed(2)]);
    }
    
    if (selectedColumns.contains('snf') && _selectedReport != 'sales') {
      csvData.add(['Weighted Average SNF (%):', stats['weightedSnf'].toStringAsFixed(2)]);
    }
    
    if (selectedColumns.contains('clr') && _selectedReport != 'sales') {
      csvData.add(['Weighted Average CLR:', stats['weightedClr'].toStringAsFixed(2)]);
    }
    
    if (selectedColumns.contains('rate')) {
      csvData.add(['Average Rate per Liter (₹):', stats['averageRate'].toStringAsFixed(2)]);
    }
    
    // Record counts by category
    csvData.add([]);
    csvData.add(['=== RECORD BREAKDOWN ===']);
    
    if (_selectedReport == 'collections') {
      // Morning vs Evening breakdown
      int morningCount = _records.where((r) => _formatShift(r['shift_type']).contains('Morning')).length;
      int eveningCount = _records.where((r) => _formatShift(r['shift_type']).contains('Evening')).length;
      csvData.add(['Morning Collections:', morningCount.toString()]);
      csvData.add(['Evening Collections:', eveningCount.toString()]);
      
      // Channel breakdown
      int cowCount = _records.where((r) => _formatChannel(r['channel']) == 'COW').length;
      int buffaloCount = _records.where((r) => _formatChannel(r['channel']) == 'BUFFALO').length;
      int mixedCount = _records.where((r) => _formatChannel(r['channel']) == 'MIXED').length;
      csvData.add(['COW Milk Collections:', cowCount.toString()]);
      csvData.add(['BUFFALO Milk Collections:', buffaloCount.toString()]);
      csvData.add(['MIXED Milk Collections:', mixedCount.toString()]);
      
      // Unique farmers count
      Set<String> uniqueFarmers = _records.map((r) => r['farmer_id']?.toString() ?? '').where((id) => id.isNotEmpty).toSet();
      csvData.add(['Unique Farmers:', uniqueFarmers.length.toString()]);
      
      // Unique societies count
      Set<String> uniqueSocieties = _records.map((r) => r['society_name']?.toString() ?? '').where((name) => name.isNotEmpty).toSet();
      csvData.add(['Unique Societies:', uniqueSocieties.length.toString()]);
    } else if (_selectedReport == 'sales') {
      // Morning vs Evening breakdown for sales
      int morningCount = _records.where((r) {
        final shiftValue = r['shift_type'] ?? r['shift'] ?? r['shift_name'] ?? '';
        return _formatShift(shiftValue.toString()).contains('Morning');
      }).length;
      int eveningCount = _records.where((r) {
        final shiftValue = r['shift_type'] ?? r['shift'] ?? r['shift_name'] ?? '';
        return _formatShift(shiftValue.toString()).contains('Evening');
      }).length;
      csvData.add(['Morning Sales:', morningCount.toString()]);
      csvData.add(['Evening Sales:', eveningCount.toString()]);
      
      // Channel breakdown
      int cowCount = _records.where((r) => _formatChannel(r['channel']) == 'COW').length;
      int buffaloCount = _records.where((r) => _formatChannel(r['channel']) == 'BUFFALO').length;
      int mixedCount = _records.where((r) => _formatChannel(r['channel']) == 'MIXED').length;
      csvData.add(['COW Milk Sales:', cowCount.toString()]);
      csvData.add(['BUFFALO Milk Sales:', buffaloCount.toString()]);
      csvData.add(['MIXED Milk Sales:', mixedCount.toString()]);
      
      // Unique societies count
      Set<String> uniqueSocieties = _records.map((r) => r['society_name']?.toString() ?? '').where((name) => name.isNotEmpty).toSet();
      csvData.add(['Unique Societies:', uniqueSocieties.length.toString()]);
    } else if (_selectedReport == 'dispatches') {
      // Morning vs Evening breakdown for dispatches
      int morningCount = _records.where((r) => _formatShift(r['shift_type']).contains('Morning')).length;
      int eveningCount = _records.where((r) => _formatShift(r['shift_type']).contains('Evening')).length;
      csvData.add(['Morning Dispatches:', morningCount.toString()]);
      csvData.add(['Evening Dispatches:', eveningCount.toString()]);
      
      // Channel breakdown
      int cowCount = _records.where((r) => _formatChannel(r['channel']) == 'COW').length;
      int buffaloCount = _records.where((r) => _formatChannel(r['channel']) == 'BUFFALO').length;
      int mixedCount = _records.where((r) => _formatChannel(r['channel']) == 'MIXED').length;
      csvData.add(['COW Milk Dispatches:', cowCount.toString()]);
      csvData.add(['BUFFALO Milk Dispatches:', buffaloCount.toString()]);
      csvData.add(['MIXED Milk Dispatches:', mixedCount.toString()]);
      
      // Unique societies count
      Set<String> uniqueSocieties = _records.map((r) => r['society_name']?.toString() ?? '').where((name) => name.isNotEmpty).toSet();
      csvData.add(['Unique Societies:', uniqueSocieties.length.toString()]);
    }
    
    // Quality metrics (for collections and dispatches)
    if (_selectedReport != 'sales' && _records.isNotEmpty) {
      csvData.add([]);
      csvData.add(['=== QUALITY METRICS ===']);
      
      List<double> fatValues = _records.map((r) => double.tryParse(r['fat_percentage']?.toString() ?? '0') ?? 0).where((v) => v > 0).toList();
      List<double> snfValues = _records.map((r) => double.tryParse(r['snf_percentage']?.toString() ?? '0') ?? 0).where((v) => v > 0).toList();
      
      if (fatValues.isNotEmpty) {
        fatValues.sort();
        csvData.add(['Minimum FAT (%):', fatValues.first.toStringAsFixed(2)]);
        csvData.add(['Maximum FAT (%):', fatValues.last.toStringAsFixed(2)]);
        csvData.add(['Median FAT (%):', fatValues[fatValues.length ~/ 2].toStringAsFixed(2)]);
      }
      
      if (snfValues.isNotEmpty) {
        snfValues.sort();
        csvData.add(['Minimum SNF (%):', snfValues.first.toStringAsFixed(2)]);
        csvData.add(['Maximum SNF (%):', snfValues.last.toStringAsFixed(2)]);
        csvData.add(['Median SNF (%):', snfValues[snfValues.length ~/ 2].toStringAsFixed(2)]);
      }
    }
    
    // Footer information
    csvData.add([]);
    csvData.add(['=== REPORT FOOTER ===']);
    csvData.add(['Report Generated By:', 'Poornasree Equipments Cloud System']);
    csvData.add(['Export Date:', DateTime.now().toString().substring(0, 19)]);
    csvData.add(['Data Columns:', selectedColumns.length.toString()]);
    csvData.add(['Records Exported:', _records.length.toString()]);
    csvData.add(['Filters Applied:', _getAppliedFiltersString()]);
    csvData.add([]);
    csvData.add(['© 2025 Poornasree Equipments - All Rights Reserved']);

    return csvData.map((row) => row.map((cell) => _escapeCsvValue(cell)).join(',')).join('\n');
  }

  // Helper method to escape CSV values and handle edge cases
  String _escapeCsvValue(String value) {
    if (value.isEmpty) return '';
    
    // Remove any existing quotes and escape internal quotes
    String cleanValue = value.replaceAll('"', '""');
    
    // Wrap in quotes if contains comma, quote, newline, or other special chars
    if (cleanValue.contains(',') || cleanValue.contains('"') || cleanValue.contains('\n') || cleanValue.contains('\r')) {
      return '"$cleanValue"';
    }
    
    return cleanValue;
  }

  Future<String> _generatePDFContent(Map<String, dynamic> stats, String dateRange, List<String> selectedColumns) async {
    try {
      print('🔧 Generating PDF content for ${_selectedReport} report...');
      
      // Convert records to the format expected by PdfService with normalized field names
      final List<Map<String, dynamic>> pdfRecords = _records.map((record) {
        final normalizedRecord = Map<String, dynamic>.from(record);
        
        // Normalize date/time field names based on report type
        if (_selectedReport == 'dispatches') {
          // Rename dispatch fields to standard names for PDF service
          if (record.containsKey('dispatch_date')) {
            normalizedRecord['collection_date'] = record['dispatch_date'];
          }
          if (record.containsKey('dispatch_time')) {
            normalizedRecord['collection_time'] = record['dispatch_time'];
          }
        } else if (_selectedReport == 'sales') {
          // Rename sales fields to standard names for PDF service
          if (record.containsKey('sales_date')) {
            normalizedRecord['collection_date'] = record['sales_date'];
          }
          if (record.containsKey('sales_time')) {
            normalizedRecord['collection_time'] = record['sales_time'];
          }
        }
        
        // Format society field to include ID and name (matching CSV format)
        if (record.containsKey('society_id') && record.containsKey('society_name')) {
          normalizedRecord['society_name'] = '${record['society_id']?.toString() ?? ''} - ${record['society_name']?.toString() ?? ''}';
        }
        
        // Format farmer field to include ID and name (matching CSV format)
        if (record.containsKey('farmer_id') && record.containsKey('farmer_name')) {
          normalizedRecord['farmer_name'] = '${record['farmer_id']?.toString() ?? ''} - ${record['farmer_name']?.toString() ?? ''}';
        }
        
        return normalizedRecord;
      }).toList();

      print('🔧 PDF Records count: ${pdfRecords.length}');
      print('🔧 PDF Stats: $stats');
      print('🔧 PDF Date Range: $dateRange');
      print('🔧 Selected Columns: $selectedColumns');

      // Generate PDF using our PdfService (similar to web app's jsPDF)
      final Uint8List pdfBytes = await PdfService.generateCollectionReportPDF(
        records: pdfRecords,
        stats: stats,
        dateRange: dateRange,
        selectedColumns: selectedColumns,
        logoPath: 'assets/images/fulllogo.png', // Logo path in assets
      );

      // Convert PDF bytes to base64 string (same format as web app)
      final String pdfBase64 = base64Encode(pdfBytes);
      
      print('✅ PDF generated successfully, size: ${pdfBytes.length} bytes');
      return pdfBase64;
    } catch (e, stackTrace) {
      print('❌ Error generating PDF: $e');
      print('❌ Stack trace: $stackTrace');
      // Return empty base64 as fallback
      return '';
    }
  }

  
  void _showFiltersDropdown(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      color: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      items: [
        // Header
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list, color: AppTheme.primaryGreen, size: 18),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations().tr('filters'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.pop(context);
                    _clearFilters();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      AppLocalizations().tr('clear'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Date Range
        PopupMenuItem(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: AppTheme.primaryGreen),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations().tr('date_range'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  final DateTimeRange? picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: _fromDate != null && _toDate != null
                        ? DateTimeRange(start: _fromDate!, end: _toDate!)
                        : null,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: context.isDarkMode ? ColorScheme.dark(
                            primary: AppTheme.primaryGreen,
                            onPrimary: Colors.white,
                            surface: context.cardColor,
                            onSurface: Colors.white,
                          ) : ColorScheme.light(
                            primary: AppTheme.primaryGreen,
                            onPrimary: Colors.white,
                            surface: context.cardColor,
                            onSurface: Colors.black87,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _fromDate = picked.start;
                      _toDate = picked.end;
                      _applyFilters();
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _fromDate != null || _toDate != null
                          ? AppTheme.primaryGreen
                          : Colors.white24,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _fromDate != null && _toDate != null
                              ? '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year} - ${_toDate!.day}/${_toDate!.month}/${_toDate!.year}'
                              : AppLocalizations().tr('select_date_range'),
                          style: TextStyle(
                            fontSize: 11,
                            color: _fromDate != null ? AppTheme.primaryGreen : Colors.white54,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.date_range,
                        size: 16,
                        color: _fromDate != null ? AppTheme.primaryGreen : Colors.white54,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Shift Filter
        PopupMenuItem(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: _buildDropdownFilter(
            AppLocalizations().tr('shift'),
            Icons.wb_sunny_outlined,
            _shiftFilter,
            ['all', 'morning', 'evening'],
            (value) {
              Navigator.pop(context);
              setState(() {
                _shiftFilter = value!;
                _applyFilters();
              });
            },
            (value) => value == 'all' ? AppLocalizations().tr('all_shifts') : value == 'morning' ? AppLocalizations().tr('morning') : AppLocalizations().tr('evening'),
          ),
        ),
        // Channel Filter
        PopupMenuItem(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: _buildDropdownFilter(
            AppLocalizations().tr('channel'),
            Icons.waves,
            _channelFilter,
            ['all', 'COW', 'BUFFALO', 'MIXED'],
            (value) {
              Navigator.pop(context);
              setState(() {
                _channelFilter = value!;
                _applyFilters();
              });
            },
            (value) => value == 'all' ? AppLocalizations().tr('all_channels') : value,
          ),
        ),
        // Machine Filter (All report types)
        PopupMenuItem(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: _buildDropdownFilter(
            AppLocalizations().tr('machine'),
            Icons.precision_manufacturing,
            _machineFilter ?? 'all',
            ['all', ..._machines.where((m) => m['machine_id'] != null && m['machine_id'].toString().isNotEmpty).map((m) => m['machine_id'].toString())],
            (value) {
              Navigator.pop(context);
              setState(() {
                _machineFilter = value == 'all' ? null : value;
                _applyFilters();
              });
            },
            (value) {
              if (value == 'all') return AppLocalizations().tr('all_machines');
              Map<String, dynamic> machine = <String, dynamic>{};
              try {
                machine = _machines.firstWhere(
                  (m) => m['machine_id']?.toString() == value,
                );
              } catch (_) {
                // Not found, use empty map
              }
              final type = machine['machine_type']?.toString() ?? AppLocalizations().tr('machine');
              final machineId = machine['machine_id']?.toString() ?? value;
              return '$type - $machineId';
            },
          ),
        ),
        // Farmer Filter (Collections only)
        if (_selectedReport == 'collections')
          PopupMenuItem(
            enabled: false,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _buildDropdownFilter(
              AppLocalizations().tr('farmer'),
              Icons.person_outline,
              _farmerFilter ?? 'all',
              ['all', ..._farmers.map((f) => f['id']?.toString() ?? '')],
              (value) {
                Navigator.pop(context);
                setState(() {
                  _farmerFilter = value == 'all' ? null : value;
                  _applyFilters();
                });
              },
              (value) {
                if (value == 'all') return AppLocalizations().tr('all_farmers');
                Map<String, dynamic> farmer = <String, dynamic>{};
                try {
                  farmer = _farmers.firstWhere(
                    (f) => f['id']?.toString() == value,
                  );
                } catch (_) {
                  // Not found, use empty map
                }
                final name = farmer['name']?.toString() ?? AppLocalizations().tr('farmer');
                return '$name - ID: $value';
              },
            ),
          ),
        // Results Info
        PopupMenuItem(
          enabled: false,
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: AppTheme.primaryGreen),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${AppLocalizations().tr('showing_records_of')} ${_records.length} ${AppLocalizations().tr('of')} ${_allRecords.length} ${AppLocalizations().tr('records')}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownFilter(
    String label,
    IconData icon,
    String value,
    List<String> options,
    Function(String?) onChanged,
    String Function(String) displayText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.primaryGreen),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: value != 'all' ? AppTheme.primaryGreen : Colors.white24,
            ),
          ),
          child: DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            underline: Container(),
            isDense: true,
            isExpanded: true,
            icon: Icon(
              Icons.arrow_drop_down,
              color: value != 'all' ? AppTheme.primaryGreen : Colors.white54,
            ),
            style: TextStyle(
              fontSize: 11,
              color: value != 'all' ? AppTheme.primaryGreen : context.textSecondaryColor,
            ),
            dropdownColor: context.cardColor,
            items: options.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(displayText(item)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 16,
            ),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                AppTheme.primaryGreen.withOpacity(0.15),
              ),
              dataRowColor: MaterialStateProperty.all(
                context.cardColor,
              ),
              border: TableBorder.all(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                width: 1,
              ),
              columnSpacing: 16,
              horizontalMargin: 12,
              headingTextStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryGreen,
                letterSpacing: 0.5,
              ),
              dataTextStyle: TextStyle(
                fontSize: 11,
                color: context.textPrimaryColor,
              ),
              columns: _getTableColumns(),
              rows: _records.asMap().entries.map((entry) {
                final index = entry.key;
                final record = entry.value;
                return DataRow(
                  color: MaterialStateProperty.all(
                    index.isEven
                        ? context.cardColor
                        : context.surfaceColor,
                  ),
                  cells: _getTableCells(record, index + 1),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  List<DataColumn> _getTableColumns() {
    switch (_selectedReport) {
      case 'collections':
        return [
          DataColumn(label: Text(AppLocalizations().tr('sl_no'))),
          DataColumn(label: Text(AppLocalizations().tr('date_time'))),
          DataColumn(label: Text(AppLocalizations().tr('farmer_id'))),
          DataColumn(label: Text(AppLocalizations().tr('society'))),
          DataColumn(label: Text(AppLocalizations().tr('machine'))),
          DataColumn(label: Text(AppLocalizations().tr('shift'))),
          DataColumn(label: Text(AppLocalizations().tr('channel'))),
          DataColumn(label: Text(AppLocalizations().tr('fat_percent'))),
          DataColumn(label: Text(AppLocalizations().tr('snf_percent'))),
          DataColumn(label: Text(AppLocalizations().tr('clr'))),
          DataColumn(label: Text(AppLocalizations().tr('protein_percent'))),
          DataColumn(label: Text(AppLocalizations().tr('lactose_percent'))),
          DataColumn(label: Text(AppLocalizations().tr('salt_percent'))),
          DataColumn(label: Text(AppLocalizations().tr('water_percent'))),
          DataColumn(label: Text(AppLocalizations().tr('temp_c'))),
          DataColumn(label: Text(AppLocalizations().tr('rate_per_liter'))),
          DataColumn(label: Text(AppLocalizations().tr('bonus'))),
          DataColumn(label: Text(AppLocalizations().tr('qty_liter'))),
          DataColumn(label: Text(AppLocalizations().tr('amount'))),
        ];
      case 'dispatches':
        return [
          DataColumn(label: Text(AppLocalizations().tr('sl_no'))),
          DataColumn(label: Text(AppLocalizations().tr('date_time'))),
          DataColumn(label: Text(AppLocalizations().tr('dispatch_id'))),
          DataColumn(label: Text(AppLocalizations().tr('society'))),
          DataColumn(label: Text(AppLocalizations().tr('machine'))),
          DataColumn(label: Text(AppLocalizations().tr('shift'))),
          DataColumn(label: Text(AppLocalizations().tr('channel'))),
          DataColumn(label: Text(AppLocalizations().tr('qty_liter'))),
          DataColumn(label: Text(AppLocalizations().tr('fat_percent'))),
          DataColumn(label: Text(AppLocalizations().tr('snf_percent'))),
          DataColumn(label: Text(AppLocalizations().tr('clr'))),
          DataColumn(label: Text(AppLocalizations().tr('rate_per_liter'))),
          DataColumn(label: Text(AppLocalizations().tr('amount'))),
        ];
      case 'sales':
        return [
          DataColumn(label: Text(AppLocalizations().tr('sl_no'))),
          DataColumn(label: Text(AppLocalizations().tr('date_time'))),
          DataColumn(label: Text(AppLocalizations().tr('count'))),
          DataColumn(label: Text(AppLocalizations().tr('society'))),
          DataColumn(label: Text(AppLocalizations().tr('machine'))),
          DataColumn(label: Text(AppLocalizations().tr('shift'))),
          DataColumn(label: Text(AppLocalizations().tr('channel'))),
          DataColumn(label: Text(AppLocalizations().tr('qty_liter'))),
          DataColumn(label: Text(AppLocalizations().tr('rate_per_liter'))),
          DataColumn(label: Text(AppLocalizations().tr('amount'))),
        ];
      default:
        return [];
    }
  }

  List<DataCell> _getTableCells(Map<String, dynamic> record, int index) {
    switch (_selectedReport) {
      case 'collections':
        return [
          DataCell(Text('$index')),
          DataCell(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record['collection_date']?.toString() ?? '-', style: const TextStyle(fontSize: 10)),
                Text(record['collection_time']?.toString() ?? '-', style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
          DataCell(
            Center(
              child: Text(
                _formatFarmerId(record['farmer_id']?.toString() ?? '-'),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          DataCell(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record['society_name'] ?? '-', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                Text('ID: ${record['society_id']?.toString() ?? "-"}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
          DataCell(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${record['machine_id']?.toString() ?? '-'}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                Text('${record['machine_type']?.toString() ?? AppLocalizations().tr('unknown')}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _getShiftColor(record['shift_type']).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatShift(record['shift_type']),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _getShiftColor(record['shift_type']),
                ),
              ),
            ),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _getChannelColor(record['channel']).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatChannel(record['channel']),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _getChannelColor(record['channel']),
                ),
              ),
            ),
          ),
          DataCell(Text((record['fat_percentage'] ?? 0).toString(), style: const TextStyle(fontSize: 10))),
          DataCell(Text((record['snf_percentage'] ?? 0).toString(), style: const TextStyle(fontSize: 10))),
          DataCell(Text((record['clr_value'] ?? 0).toString(), style: const TextStyle(fontSize: 10))),
          DataCell(Text((record['protein_percentage'] ?? 0).toString(), style: const TextStyle(fontSize: 10))),
          DataCell(Text((record['lactose_percentage'] ?? 0).toString(), style: const TextStyle(fontSize: 10))),
          DataCell(Text((record['salt_percentage'] ?? 0).toString(), style: const TextStyle(fontSize: 10))),
          DataCell(Text((record['water_percentage'] ?? 0).toString(), style: const TextStyle(fontSize: 10))),
          DataCell(Text((record['temperature'] ?? 0).toString(), style: const TextStyle(fontSize: 10))),
          DataCell(Text('₹${record['rate_per_liter'] ?? 0}', style: const TextStyle(fontSize: 10))),
          DataCell(Text('₹${record['bonus'] ?? 0}', style: const TextStyle(fontSize: 10))),
          DataCell(Text((record['quantity'] ?? 0).toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
          DataCell(Text(
            '₹${record['total_amount'] ?? 0}',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          )),
        ];
      case 'dispatches':
        return [
          DataCell(Text('$index')),
          DataCell(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record['dispatch_date']?.toString() ?? '-', style: const TextStyle(fontSize: 10)),
                Text(record['dispatch_time']?.toString() ?? '-', style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
          DataCell(Text(record['dispatch_id']?.toString() ?? '-', style: const TextStyle(fontSize: 10))),
          DataCell(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record['society_name'] ?? '-', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                Text('ID: ${record['society_id']?.toString() ?? "-"}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
          DataCell(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${record['machine_number']?.toString() ?? record['machine_id']?.toString() ?? '-'}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                Text('${record['machine_type']?.toString() ?? 'Unknown'}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _getShiftColor(record['shift_type']).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatShift(record['shift_type']),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _getShiftColor(record['shift_type']),
                ),
              ),
            ),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _getChannelColor(record['channel']).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatChannel(record['channel']),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _getChannelColor(record['channel']),
                ),
              ),
            ),
          ),
          DataCell(Text((record['quantity'] ?? 0).toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
          DataCell(Text((record['fat_percentage'] ?? 0).toString(), style: const TextStyle(fontSize: 10))),
          DataCell(Text((record['snf_percentage'] ?? 0).toString(), style: const TextStyle(fontSize: 10))),
          DataCell(Text((record['clr_value'] ?? 0).toString(), style: const TextStyle(fontSize: 10))),
          DataCell(Text('₹${record['rate_per_liter'] ?? 0}', style: const TextStyle(fontSize: 10))),
          DataCell(Text(
            '₹${record['total_amount'] ?? 0}',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          )),
        ];
      case 'sales':
        return [
          DataCell(Text('$index')),
          DataCell(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record['sales_date']?.toString() ?? '-', style: const TextStyle(fontSize: 10)),
                Text(record['sales_time']?.toString() ?? '-', style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
          DataCell(Text(record['count']?.toString() ?? '-', style: const TextStyle(fontSize: 10))),
          DataCell(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record['society_name'] ?? '-', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                Text('ID: ${record['society_id']?.toString() ?? "-"}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
          DataCell(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${record['machine_number']?.toString() ?? record['machine_id']?.toString() ?? '-'}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                Text('${record['machine_type']?.toString() ?? 'Unknown'}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _getShiftColor(record['shift_type']).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatShift(record['shift_type']),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _getShiftColor(record['shift_type']),
                ),
              ),
            ),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _getChannelColor(record['channel']).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatChannel(record['channel']),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _getChannelColor(record['channel']),
                ),
              ),
            ),
          ),
          DataCell(Text((record['quantity'] ?? 0).toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
          DataCell(Text('₹${record['rate_per_liter'] ?? 0}', style: const TextStyle(fontSize: 10))),
          DataCell(Text(
            '₹${record['total_amount'] ?? 0}',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          )),
        ];
      default:
        return [];
    }
  }

  Color _getShiftColor(String? shift) {
    final shiftStr = shift?.toUpperCase() ?? '';
    if (['MR', 'MX', 'MORNING'].contains(shiftStr)) {
      return Colors.orange;
    } else if (['EV', 'EX', 'EVENING'].contains(shiftStr)) {
      return Colors.purple;
    }
    return Colors.grey;
  }

  // Format farmer ID: "00310" → "310", "00000" → "0"
  String _formatFarmerId(String? id) {
    if (id == null || id.isEmpty || id == '-') return '-';
    final result = id.replaceFirst(RegExp(r'^0+'), '');
    return result.isEmpty ? '0' : result;
  }

  String _formatShift(String? shift) {
    if (shift == null || shift.isEmpty) return '-';
    final shiftStr = shift.trim().toUpperCase();
    if (['MR', 'MX', 'MORNING'].contains(shiftStr)) {
      return 'Morning';
    } else if (['EV', 'EX', 'EVENING'].contains(shiftStr)) {
      return 'Evening';
    }
    return shift.trim().isNotEmpty ? shift.trim() : '-';
  }

  Color _getChannelColor(String? channel) {
    final channelStr = _formatChannel(channel);
    switch (channelStr) {
      case 'COW':
        return Colors.blue;
      case 'BUFFALO':
        return Colors.green;
      case 'MIXED':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatChannel(String? channel) {
    if (channel == null || channel.isEmpty) return '-';
    final channelStr = channel.trim().toUpperCase();
    
    // Handle all possible channel variations
    if (['COW', 'CH1'].contains(channelStr)) {
      return 'COW';
    } else if (['BUFFALO', 'BUF', 'CH2'].contains(channelStr)) {
      return 'BUFFALO';
    } else if (['MIXED', 'MIX', 'CH3'].contains(channelStr)) {
      return 'MIXED';
    }
    
    // Return trimmed version if no match found, or '-' if empty
    return channel.trim().isNotEmpty ? channel.trim().toUpperCase() : '-';
  }
  
  String _getAppliedFiltersString() {
    List<String> filters = [];
    
    if (_fromDate != null || _toDate != null) {
      if (_fromDate != null && _toDate != null) {
        filters.add('Date: ${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year} to ${_toDate!.day}/${_toDate!.month}/${_toDate!.year}');
      } else if (_fromDate != null) {
        filters.add('From: ${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}');
      } else {
        filters.add('Until: ${_toDate!.day}/${_toDate!.month}/${_toDate!.year}');
      }
    }
    
    if (_shiftFilter != 'all') {
      filters.add('Shift: ${_shiftFilter == 'morning' ? 'Morning' : 'Evening'}');
    }
    
    if (_channelFilter != 'all') {
      filters.add('Channel: $_channelFilter');
    }
    
    if (_machineFilter != null) {
      Map<String, dynamic> machine = <String, dynamic>{};
      try {
        machine = _machines.firstWhere(
          (m) => m['machine_id']?.toString() == _machineFilter,
        );
      } catch (_) {
        // Not found, use empty map
      }
      final machineName = machine['machine_type']?.toString() ?? 'Machine';
      filters.add('Machine: $machineName ($_machineFilter)');
    }
    
    if (_farmerFilter != null) {
      Map<String, dynamic> farmer = <String, dynamic>{};
      try {
        farmer = _farmers.firstWhere(
          (f) => f['id']?.toString() == _farmerFilter,
        );
      } catch (_) {
        // Not found, use empty map
      }
      final farmerName = farmer['name']?.toString() ?? 'Farmer';
      filters.add('Farmer: $farmerName ($_farmerFilter)');
    }
    
    return filters.isEmpty ? 'No filters applied' : filters.join('; ');
  }
  
  String _getReportTitle(String reportType) {
    switch (reportType) {
      case 'collections':
        return 'Collection Report';
      case 'dispatches':
        return 'Dispatch Report';
      case 'sales':
        return 'Sales Report';
      default:
        return 'Report';
    }
  }

  void _showColumnSelectionDialog(BuildContext context, List<String> currentSelection, Function(List<String>) onSelectionChanged) {
    List<String> tempSelection = List.from(currentSelection);
    final l10n = AppLocalizations();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          titlePadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          title: Row(
            children: [
              Icon(Icons.view_column, color: AppTheme.primaryGreen, size: 18),
              const SizedBox(width: 6),
              Text(
                'Select Columns',
                style: TextStyle(color: context.textPrimaryColor, fontSize: 15),
              ),
              const Spacer(),
              Text(
                '${tempSelection.length} selected',
                style: TextStyle(color: context.textSecondaryColor, fontSize: 10),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            tempSelection = currentReportAvailableColumns.map((col) => col['key']!).toList();
                          });
                        },
                        icon: Icon(Icons.select_all, size: 12, color: AppTheme.primaryGreen),
                        label: Text(
                          'All',
                          style: TextStyle(color: AppTheme.primaryGreen, fontSize: 10),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            tempSelection = List.from(currentReportDefaultColumns);
                          });
                        },
                        icon: Icon(Icons.restore, size: 12, color: AppTheme.primaryGreen),
                        label: Text(
                          'Default',
                          style: TextStyle(color: AppTheme.primaryGreen, fontSize: 10),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Column grid for landscape mode
                Expanded(
                  child: SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate number of columns based on screen width
                        int crossAxisCount = constraints.maxWidth > 800 ? 3 : 
                                           constraints.maxWidth > 500 ? 2 : 1;
                        
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: 5.5,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 3,
                          ),
                          itemCount: currentReportAvailableColumns.length,
                          itemBuilder: (context, index) {
                            final column = currentReportAvailableColumns[index];
                            final isSelected = tempSelection.contains(column['key']);
                            final isDefaultColumn = currentReportDefaultColumns.contains(column['key']);
                            
                            return Container(
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? AppTheme.primaryGreen.withOpacity(0.1)
                                    : context.surfaceColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected 
                                      ? AppTheme.primaryGreen.withOpacity(0.5)
                                      : context.borderColor.withOpacity(0.5),
                                ),
                              ),
                              child: CheckboxListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                value: isSelected,
                                onChanged: isDefaultColumn ? null : (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if (!tempSelection.contains(column['key'])) {
                                        // Insert column in correct position to maintain order
                                        final columnIndex = currentReportAvailableColumns.indexWhere((col) => col['key'] == column['key']);
                                        int insertIndex = tempSelection.length;
                                        
                                        for (int i = 0; i < tempSelection.length; i++) {
                                          final currentColumnIndex = currentReportAvailableColumns.indexWhere((col) => col['key'] == tempSelection[i]);
                                          if (currentColumnIndex > columnIndex) {
                                            insertIndex = i;
                                            break;
                                          }
                                        }
                                        
                                        tempSelection.insert(insertIndex, column['key']!);
                                      }
                                    } else {
                                      tempSelection.remove(column['key']);
                                    }
                                  });
                                },
                                title: Text(
                                  column['label']!,
                                  style: TextStyle(
                                    color: isDefaultColumn 
                                        ? context.textSecondaryColor.withOpacity(0.8)
                                        : context.textPrimaryColor,
                                    fontSize: 11,
                                    fontWeight: isDefaultColumn ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                                subtitle: isDefaultColumn 
                                    ? Text(
                                        'Required',
                                        style: TextStyle(
                                          color: context.textSecondaryColor.withOpacity(0.6),
                                          fontSize: 9,
                                        ),
                                      )
                                    : null,
                                activeColor: AppTheme.primaryGreen,
                                checkColor: Colors.white,
                                controlAffinity: ListTileControlAffinity.leading,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l10n.tr('cancel'), style: TextStyle(color: context.textSecondaryColor, fontSize: 11)),
            ),
            ElevatedButton(
              onPressed: () {
                onSelectionChanged(tempSelection);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(AppLocalizations().tr('apply'), style: const TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
