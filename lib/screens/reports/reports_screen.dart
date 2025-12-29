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
            // Download button with dropdown
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
    final emailController = TextEditingController();
    bool isLoading = false;

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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter email address to receive CSV and PDF reports:',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'example@company.com',
                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.darkBg2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primaryGreen),
                  ),
                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryGreen),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton.icon(
              onPressed: isLoading || emailController.text.isEmpty 
                  ? null 
                  : () async {
                      setState(() => isLoading = true);
                      try {
                        await _sendEmailReport(emailController.text.trim());
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Report sent successfully to ${emailController.text}'),
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                        );
                      } catch (e) {
                        setState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to send report: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              icon: isLoading 
                  ? SizedBox(
                      width: 16, 
                      height: 16, 
                      child: CircularProgressIndicator(
                        strokeWidth: 2, 
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
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

  Future<void> _sendEmailReport(String email) async {
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
      String csvContent = _generateCSVContent(stats, dateRange);
      
      // Generate PDF content (we'll send the data to server to create PDF)
      String pdfContent = await _generatePDFContent(stats, dateRange);

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

  String _generateCSVContent(Map<String, dynamic> stats, String dateRange) {
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
    
    // Table headers
    if (_selectedReport == 'collections') {
      csvData.add(['Date', 'Time', 'Channel', 'Shift', 'Machine', 'Society', 'Farmer ID', 'Farmer Name', 'Fat (%)', 'SNF (%)', 'CLR', 'Water (%)', 'Rate (₹/L)', 'Quantity (L)', 'Total Amount (₹)', 'Incentive']);
      for (var record in _records) {
        csvData.add([
          record['collection_date']?.toString() ?? '',
          record['collection_time']?.toString() ?? '',
          _formatChannel(record['channel']),
          _formatShift(record['shift_type']),
          '${record['machine_id']} (${record['machine_type']})',
          record['society_name']?.toString() ?? '',
          record['farmer_id']?.toString() ?? '',
          record['farmer_name']?.toString() ?? '',
          record['fat_percentage']?.toString() ?? '',
          record['snf_percentage']?.toString() ?? '',
          record['clr_value']?.toString() ?? '',
          record['water_percentage']?.toString() ?? '',
          record['rate_per_liter']?.toString() ?? '',
          record['quantity']?.toString() ?? '',
          record['total_amount']?.toString() ?? '',
          record['bonus']?.toString() ?? '',
        ]);
      }
    } else if (_selectedReport == 'dispatches') {
      csvData.add(['Date', 'Time', 'Dispatch ID', 'Shift', 'Channel', 'Society', 'Machine', 'Quantity (L)', 'Fat (%)', 'SNF (%)', 'CLR', 'Rate (₹/L)', 'Total Amount (₹)']);
      for (var record in _records) {
        csvData.add([
          record['dispatch_date']?.toString() ?? '',
          record['dispatch_time']?.toString() ?? '',
          record['dispatch_id']?.toString() ?? '',
          _formatShift(record['shift_type']),
          _formatChannel(record['channel']),
          record['society_name']?.toString() ?? '',
          record['machine_type']?.toString() ?? '',
          record['quantity']?.toString() ?? '',
          record['fat_percentage']?.toString() ?? '',
          record['snf_percentage']?.toString() ?? '',
          record['clr_value']?.toString() ?? '',
          record['rate_per_liter']?.toString() ?? '',
          record['total_amount']?.toString() ?? '',
        ]);
      }
    } else {
      csvData.add(['Date', 'Time', 'Count', 'Shift', 'Channel', 'Society', 'Machine', 'Quantity (L)', 'Rate (₹/L)', 'Total Amount (₹)']);
      for (var record in _records) {
        csvData.add([
          record['sales_date']?.toString() ?? '',
          record['sales_time']?.toString() ?? '',
          record['count']?.toString() ?? '',
          _formatShift(record['shift_type']),
          _formatChannel(record['channel']),
          record['society_name']?.toString() ?? '',
          record['machine_type']?.toString() ?? '',
          record['quantity']?.toString() ?? '',
          record['rate_per_liter']?.toString() ?? '',
          record['total_amount']?.toString() ?? '',
        ]);
      }
    }

    return csvData.map((row) => row.join(',')).join('\n');
  }

  Future<String> _generatePDFContent(Map<String, dynamic> stats, String dateRange) async {
    // For now, we'll send the data to the server to generate PDF
    // In the actual email API on the server, we'll generate the PDF with jsPDF
    // This is a placeholder - the actual PDF generation will happen on the server
    return 'PDF_PLACEHOLDER';
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
    final channelStr = channel.trim().toUpperCase();
    
    // Handle all possible channel variations
    if (['COW', 'CH1'].contains(channelStr)) {
      return 'COW';
    } else if (['BUFFALO', 'BUF', 'CH2'].contains(channelStr)) {
      return 'BUFFALO';
    } else if (['MIXED', 'MIX', 'CH3'].contains(channelStr)) {
      return 'MIXED';
    }
    
    // Return uppercase version if no match found
    return channelStr;
  }
}
