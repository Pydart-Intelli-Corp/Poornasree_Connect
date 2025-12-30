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

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedReport = 'collections';
  bool _isLoading = false;
  List<dynamic> _records = [];
  List<dynamic> _allRecords = [];
  String? _errorMessage;
  
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
  
  // Column selection for reports
  static const List<Map<String, String>> availableColumns = [
    {'key': 'sl_no', 'label': 'Sl.No'},
    {'key': 'date_time', 'label': 'Date & Time'},
    {'key': 'farmer', 'label': 'Farmer'},
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
    // Initialize with current report defaults
    _selectedColumns = List.from(currentReportDefaultColumns);
    // Lock to landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _loadColumnPreferences();
    _fetchData();
  }

  @override
  void dispose() {
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.user?.token;
      if (token == null) return;
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/external/machines'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _machines = List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
      }
    } catch (e) {
      print('Error fetching machines: $e');
    }
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
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _allRecords = data['data']['records'] ?? [];
          _applyFilters();
          _isLoading = false;
        });
        
        // Extract farmers from records after loading
        _extractFarmersFromRecords();
      } else {
        throw Exception('Failed to load $_selectedReport');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Restore portrait orientation before going back
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports Management'),
          elevation: 0,
          actions: [
            _buildReportTypeChip(
              'Collections',
              'collections',
              Icons.water_drop_outlined,
            ),
            const SizedBox(width: 4),
            _buildReportTypeChip(
              'Dispatches',
              'dispatches',
              Icons.local_shipping_outlined,
            ),
            const SizedBox(width: 4),
            _buildReportTypeChip(
              'Sales',
              'sales',
              Icons.sell_outlined,
            ),
            const SizedBox(width: 12),
            // Email button
            Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: const Icon(Icons.email_outlined, size: 20),
                  onPressed: _records.isEmpty ? null : () => _showEmailDialog(),
                  tooltip: 'Email Report',
                  color: Colors.white,
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
              tooltip: 'Refresh Data',
              color: Colors.white,
            ),
            // Filter button with badge
            Builder(
              builder: (BuildContext context) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.filter_list, size: 20),
                      onPressed: () => _showFiltersDropdown(context),
                      tooltip: 'Filters',
                      color: Colors.white,
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
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading $_selectedReport',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _isLoading ? null : () {
                                  HapticFeedback.lightImpact();
                                  _fetchData();
                                },
                                icon: _isLoading 
                                    ? const FlowerSpinner(size: 16)
                                    : const Icon(Icons.refresh),
                                label: Text(_isLoading ? 'Loading...' : 'Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _records.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getReportIcon(_selectedReport),
                                  size: 64,
                                  color: AppTheme.textSecondary.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No ${_selectedReport} found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_getReportTitle(_selectedReport)} data will appear here',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
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
                : Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
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
    
    // Machine filter
    if (_machineFilter != null && _selectedReport == 'collections') {
      filtered = filtered.where((r) => r['machine_id']?.toString() == _machineFilter).toList();
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

  void _showEmailDialog() {
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
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.email_outlined, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 8),
              Text(
                'Email Report',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
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
                    'Send CSV and PDF reports to your email:',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBg2,
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
                              color: AppTheme.textPrimary,
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
                        'Report Columns:',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${tempSelectedColumns.length} selected',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
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
                          'Select Columns',
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
                      color: AppTheme.darkBg2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                    ),
                    child: Wrap(
                      spacing: 3,
                      runSpacing: 3,
                      children: tempSelectedColumns.take(15).map((columnKey) {
                        final column = currentReportAvailableColumns.firstWhere(
                          (col) => col['key'] == columnKey,
                          orElse: () => {'key': columnKey, 'label': columnKey},
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
                              color: AppTheme.textSecondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+${tempSelectedColumns.length - 15} more',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
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
                    'Report: ${_records.length} ${_selectedReport} records, ${tempSelectedColumns.length} columns',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
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
              label: Text(isLoading ? 'Sending...' : 'Send Report'),
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
      final column = availableColumns.firstWhere((col) => col['key'] == columnKey, orElse: () => {'key': columnKey, 'label': columnKey});
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
            String farmerId = record['farmer_id']?.toString() ?? '';
            String farmerName = record['farmer_name']?.toString() ?? '';
            if (farmerId.isNotEmpty && farmerName.isNotEmpty) {
              value = '$farmerId - $farmerName';
            } else if (farmerId.isNotEmpty) {
              value = farmerId;
            } else if (farmerName.isNotEmpty) {
              value = farmerName;
            } else {
              value = '';
            }
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
      color: AppTheme.cardDark,
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
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _clearFilters();
                  },
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
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
                    'Date Range',
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
                          colorScheme: ColorScheme.dark(
                            primary: AppTheme.primaryGreen,
                            onPrimary: Colors.white,
                            surface: AppTheme.cardDark,
                            onSurface: Colors.white,
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
                    color: AppTheme.darkBg2,
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
                              : 'Select date range',
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
            'Shift',
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
            (value) => value == 'all' ? 'All Shifts' : value == 'morning' ? 'Morning' : 'Evening',
          ),
        ),
        // Channel Filter
        PopupMenuItem(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: _buildDropdownFilter(
            'Channel',
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
            (value) => value == 'all' ? 'All Channels' : value,
          ),
        ),
        // Machine Filter (Collections only)
        if (_selectedReport == 'collections')
          PopupMenuItem(
            enabled: false,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _buildDropdownFilter(
              'Machine',
              Icons.precision_manufacturing,
              _machineFilter ?? 'all',
              ['all', ..._machines.map((m) => m['id']?.toString() ?? '')],
              (value) {
                Navigator.pop(context);
                setState(() {
                  _machineFilter = value == 'all' ? null : value;
                  _applyFilters();
                });
              },
              (value) {
                if (value == 'all') return 'All Machines';
                final machine = _machines.firstWhere(
                  (m) => m['id']?.toString() == value,
                  orElse: () => {},
                );
                final type = machine['machine_type']?.toString() ?? 'Machine';
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
              'Farmer',
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
                if (value == 'all') return 'All Farmers';
                final farmer = _farmers.firstWhere(
                  (f) => f['id']?.toString() == value,
                  orElse: () => {},
                );
                final name = farmer['name']?.toString() ?? 'Farmer';
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
                Text(
                  'Showing ${_records.length} of ${_allRecords.length} records',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w500,
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
            color: AppTheme.darkBg2,
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
              color: value != 'all' ? AppTheme.primaryGreen : Colors.white70,
            ),
            dropdownColor: AppTheme.cardDark,
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
        color: AppTheme.cardDark,
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
                AppTheme.cardDark,
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
                color: AppTheme.textPrimary,
              ),
              columns: _getTableColumns(),
              rows: _records.asMap().entries.map((entry) {
                final index = entry.key;
                final record = entry.value;
                return DataRow(
                  color: MaterialStateProperty.all(
                    index.isEven
                        ? AppTheme.cardDark
                        : AppTheme.cardDark.withOpacity(0.7),
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
          const DataColumn(label: Text('No.')),
          const DataColumn(label: Text('Date & Time')),
          const DataColumn(label: Text('Farmer')),
          const DataColumn(label: Text('Society')),
          const DataColumn(label: Text('Machine')),
          const DataColumn(label: Text('Shift')),
          const DataColumn(label: Text('Channel')),
          const DataColumn(label: Text('FAT %')),
          const DataColumn(label: Text('SNF %')),
          const DataColumn(label: Text('CLR')),
          const DataColumn(label: Text('Protein %')),
          const DataColumn(label: Text('Lactose %')),
          const DataColumn(label: Text('Salt %')),
          const DataColumn(label: Text('Water %')),
          const DataColumn(label: Text('Temp (°C)')),
          const DataColumn(label: Text('Rate/L')),
          const DataColumn(label: Text('Bonus')),
          const DataColumn(label: Text('Qty (L)')),
          const DataColumn(label: Text('Amount')),
        ];
      case 'dispatches':
        return [
          const DataColumn(label: Text('No.')),
          const DataColumn(label: Text('Date & Time')),
          const DataColumn(label: Text('Dispatch ID')),
          const DataColumn(label: Text('Society')),
          const DataColumn(label: Text('Machine')),
          const DataColumn(label: Text('Shift')),
          const DataColumn(label: Text('Channel')),
          const DataColumn(label: Text('Qty (L)')),
          const DataColumn(label: Text('FAT %')),
          const DataColumn(label: Text('SNF %')),
          const DataColumn(label: Text('CLR')),
          const DataColumn(label: Text('Rate/L')),
          const DataColumn(label: Text('Amount')),
        ];
      case 'sales':
        return [
          const DataColumn(label: Text('No.')),
          const DataColumn(label: Text('Date & Time')),
          const DataColumn(label: Text('Count')),
          const DataColumn(label: Text('Society')),
          const DataColumn(label: Text('Machine')),
          const DataColumn(label: Text('Shift')),
          const DataColumn(label: Text('Channel')),
          const DataColumn(label: Text('Qty (L)')),
          const DataColumn(label: Text('Rate/L')),
          const DataColumn(label: Text('Amount')),
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
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record['farmer_name'] ?? 'Unknown', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                Text('ID: ${record['farmer_id']?.toString() ?? "-"}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
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
    return AppTheme.textSecondary;
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
        return AppTheme.textSecondary;
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
      final machine = _machines.firstWhere(
        (m) => m['id']?.toString() == _machineFilter,
        orElse: () => {},
      );
      final machineName = machine['machine_type']?.toString() ?? 'Machine';
      filters.add('Machine: $machineName ($_machineFilter)');
    }
    
    if (_farmerFilter != null) {
      final farmer = _farmers.firstWhere(
        (f) => f['id']?.toString() == _farmerFilter,
        orElse: () => {},
      );
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
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
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
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
              ),
              const Spacer(),
              Text(
                '${tempSelection.length} selected',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
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
                                    : AppTheme.darkBg2,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected 
                                      ? AppTheme.primaryGreen.withOpacity(0.5)
                                      : AppTheme.textSecondary.withOpacity(0.2),
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
                                        ? AppTheme.textSecondary.withOpacity(0.8)
                                        : AppTheme.textPrimary,
                                    fontSize: 11,
                                    fontWeight: isDefaultColumn ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                                subtitle: isDefaultColumn 
                                    ? Text(
                                        'Required',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary.withOpacity(0.6),
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
              child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ),
            ElevatedButton(
              onPressed: () {
                onSelectionChanged(tempSelection);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Apply', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
