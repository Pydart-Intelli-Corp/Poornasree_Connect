import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/providers.dart';
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
  bool _showFilters = false;
  DateTime? _fromDate;
  DateTime? _toDate;
  String _shiftFilter = 'all';
  String _channelFilter = 'all';
  String? _machineFilter;
  String? _farmerFilter;
  
  // Filter data
  List<Map<String, dynamic>> _machines = [];
  List<Map<String, dynamic>> _farmers = [];

  @override
  void initState() {
    super.initState();
    // Lock to landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    await Future.wait([
      _fetchRecords(),
      _fetchMachines(),
      _fetchFarmers(),
    ]);
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
  
  Future<void> _fetchFarmers() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.user?.token;
      if (token == null) return;
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/external/farmers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _farmers = List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
      }
    } catch (e) {
      print('Error fetching farmers: $e');
    }
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
            // Filter button with badge
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list, size: 20),
                  onPressed: _showFiltersModal,
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
                                onPressed: _fetchData,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
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
        setState(() => _selectedReport = value);
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
      filtered = filtered.where((r) => (r['shift_type'] ?? '').toString().toLowerCase() == _shiftFilter).toList();
    }
    
    // Channel filter
    if (_channelFilter != 'all') {
      filtered = filtered.where((r) => _formatChannel(r['channel']).toUpperCase() == _channelFilter).toList();
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
  
  void _showFiltersModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.primaryGreen.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_list, color: AppTheme.primaryGreen, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      _clearFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
            // Filter Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Range Section
                    _buildFilterSection(
                      'Date Range',
                      Icons.calendar_today,
                      [
                        _buildDateFilterTile('From Date', _fromDate, (date) {
                          setState(() {
                            _fromDate = date;
                            _applyFilters();
                          });
                          Navigator.pop(context);
                          _showFiltersModal();
                        }),
                        _buildDateFilterTile('To Date', _toDate, (date) {
                          setState(() {
                            _toDate = date;
                            _applyFilters();
                          });
                          Navigator.pop(context);
                          _showFiltersModal();
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Shift Filter
                    _buildFilterSection(
                      'Shift',
                      Icons.wb_sunny_outlined,
                      [
                        _buildDropdownTile(
                          'Shift Type',
                          _shiftFilter,
                          ['all', 'morning', 'evening'],
                          (value) {
                            setState(() {
                              _shiftFilter = value!;
                              _applyFilters();
                            });
                          },
                          (value) => value == 'all' ? 'All Shifts' : value == 'morning' ? 'Morning' : 'Evening',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Channel Filter
                    _buildFilterSection(
                      'Channel',
                      Icons.waves,
                      [
                        _buildDropdownTile(
                          'Channel Type',
                          _channelFilter,
                          ['all', 'COW', 'BUFFALO', 'MIXED'],
                          (value) {
                            setState(() {
                              _channelFilter = value!;
                              _applyFilters();
                            });
                          },
                          (value) => value == 'all' ? 'All Channels' : value,
                        ),
                      ],
                    ),
                    // Collections-specific filters
                    if (_selectedReport == 'collections') ...[
                      const SizedBox(height: 16),
                      _buildFilterSection(
                        'Machine',
                        Icons.precision_manufacturing,
                        [
                          _buildDropdownTile(
                            'Select Machine',
                            _machineFilter ?? 'all',
                            ['all', ..._machines.map((m) => m['machine_id']?.toString() ?? '')],
                            (value) {
                              setState(() {
                                _machineFilter = value == 'all' ? null : value;
                                _applyFilters();
                              });
                            },
                            (value) => value == 'all' ? 'All Machines' : 'Machine $value',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFilterSection(
                        'Farmer',
                        Icons.person_outline,
                        [
                          _buildDropdownTile(
                            'Select Farmer',
                            _farmerFilter ?? 'all',
                            ['all', ..._farmers.map((f) => f['id']?.toString() ?? '')],
                            (value) {
                              setState(() {
                                _farmerFilter = value == 'all' ? null : value;
                                _applyFilters();
                              });
                            },
                            (value) {
                              if (value == 'all') return 'All Farmers';
                              final farmer = _farmers.firstWhere((f) => f['id']?.toString() == value, orElse: () => {});
                              return farmer['name']?.toString() ?? value;
                            },
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Results count
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: AppTheme.primaryGreen),
                          const SizedBox(width: 8),
                          Text(
                            'Showing ${_records.length} of ${_allRecords.length} records',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Apply Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppTheme.primaryGreen.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.darkBg2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primaryGreen.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDateFilterTile(String label, DateTime? date, Function(DateTime?) onChanged) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
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
          onChanged(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppTheme.primaryGreen.withOpacity(0.1),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ),
            Text(
              date != null ? '${date.day}/${date.month}/${date.year}' : 'Select date',
              style: TextStyle(
                fontSize: 13,
                color: date != null ? AppTheme.primaryGreen : Colors.white54,
                fontWeight: date != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.calendar_today,
              size: 16,
              color: date != null ? AppTheme.primaryGreen : Colors.white54,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDropdownTile(
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged,
    String Function(String) displayText,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ),
          DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            underline: Container(),
            isDense: true,
            icon: Icon(
              Icons.arrow_drop_down,
              color: AppTheme.primaryGreen,
            ),
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
            dropdownColor: AppTheme.cardDark,
            items: options.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(displayText(item)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
    String _getReportTitle(String reportType) {
    switch (reportType) {
      case 'collections':
        return 'Milk Collections Report';
      case 'dispatches':
        return 'Dispatches Report';
      case 'sales':
        return 'Sales Report';
      default:
        return 'Report';
    }
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
                Text(record['machine_id']?.toString() ?? '-', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                Text(record['machine_type']?.toString() ?? '-', style: const TextStyle(fontSize: 9, color: Colors.grey)),
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
          DataCell(Text(record['society_name'] ?? '-', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
          DataCell(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record['machine_number']?.toString() ?? '-', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                Text(record['machine_type'] ?? '-', style: const TextStyle(fontSize: 9, color: Colors.grey)),
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
          DataCell(Text(record['society_name'] ?? '-', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
          DataCell(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record['machine_number']?.toString() ?? '-', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                Text(record['machine_type'] ?? '-', style: const TextStyle(fontSize: 9, color: Colors.grey)),
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

  Color _getPaymentStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return AppTheme.textSecondary;
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
    if (shift == null) return '-';
    final shiftStr = shift.toUpperCase();
    if (['MR', 'MX', 'MORNING'].contains(shiftStr)) {
      return 'Morning';
    } else if (['EV', 'EX', 'EVENING'].contains(shiftStr)) {
      return 'Evening';
    }
    return shift;
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
    if (channel == null) return '-';
    final channelMap = {
      'ch1': 'COW',
      'ch2': 'BUFFALO',
      'ch3': 'MIXED',
      'CH1': 'COW',
      'CH2': 'BUFFALO',
      'CH3': 'MIXED',
      'COW': 'COW',
      'BUFFALO': 'BUFFALO',
      'MIXED': 'MIXED',
      'cow': 'COW',
      'buffalo': 'BUFFALO',
      'mixed': 'MIXED',
      'BUF': 'BUFFALO',
      'MIX': 'MIXED',
    };
    return channelMap[channel] ?? channel.toUpperCase();
  }
}
