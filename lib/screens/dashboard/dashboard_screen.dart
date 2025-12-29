import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';
import '../auth/login_screen.dart';
import '../reports/reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  List<dynamic> _machines = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
    _logUserData();
  }

  void _logUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    print('🔍 Dashboard User Data:');
    print('  BMC Name: ${user?.bmcName}');
    print('  Dairy Name: ${user?.dairyName}');
    print('  Dairy ID: ${user?.dairyId}');
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.user?.token;

    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication token not found';
      });
      return;
    }

    // Load machines list and statistics in parallel
    final results = await Future.wait([
      _dashboardService.getMachinesList(token),
      _dashboardService.getStatistics(token),
    ]);

    final machinesResult = results[0];
    final statsResult = results[1];

    if (machinesResult['success']) {
      setState(() {
        _machines = machinesResult['machines'];
      });
    } else {
      setState(() {
        _errorMessage = machinesResult['message'];
      });
    }

    if (statsResult['success']) {
      setState(() {
        _statistics = statsResult['statistics'];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        PageTransition(
          child: const LoginScreen(),
          type: TransitionType.fade,
        ),
        (route) => false,
      );
    }
  }

  void _showEntityDetails(BuildContext context, String title, IconData icon, Map<String, dynamic> details) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.user?.token;
    
    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryGreen),
              const SizedBox(height: 16),
              Text(
                'Loading details...',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Fetch full details from API
    Map<String, dynamic> fullDetails = details;
    if (token != null) {
      try {
        final entityId = details['ID'];
        final entityType = title.toLowerCase().contains('bmc') ? 'bmc' : 'dairy';
        
        if (entityId != null) {
          final response = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/api/external/entity/$entityType/$entityId'),
            headers: {'Authorization': 'Bearer $token'},
          );
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['success'] == true && data['data'] != null) {
              final apiData = data['data'];
              fullDetails = {
                'Name': apiData['name'],
                if (entityType == 'bmc') 'BMC ID': apiData['bmc_id'],
                if (entityType == 'dairy') 'Dairy ID': apiData['dairy_id'],
                'Email': apiData['email'],
                'Location': apiData['location'],
                if (apiData['contact_phone'] != null) 'Contact Phone': apiData['contact_phone'],
                if (entityType == 'dairy' && apiData['president_name'] != null) 'President': apiData['president_name'],
                'Status': apiData['status']?.toString().toUpperCase(),
                if (entityType == 'bmc' && apiData['dairy_name'] != null) ...{
                  'Dairy Name': apiData['dairy_name'],
                  if (apiData['dairy_location'] != null) 'Dairy Location': apiData['dairy_location'],
                  if (apiData['dairy_contact'] != null) 'Dairy Contact': apiData['dairy_contact'],
                },
              };
            }
          }
        }
      } catch (e) {
        print('Error fetching entity details: $e');
      }
    }

    // Close loading dialog
    if (context.mounted) Navigator.pop(context);

    // Show details dialog
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 28,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBg2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: fullDetails.entries.where((e) => e.value != null && e.value.toString().isNotEmpty).map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: Text(
                                entry.value.toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.assessment_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportsScreen(),
                ),
              );
            },
            tooltip: 'Reports',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // User Info Header - Container under AppBar
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              ResponsiveHelper.getSpacing(context, 16),
              ResponsiveHelper.getSpacing(context, 12),
              ResponsiveHelper.getSpacing(context, 16),
              ResponsiveHelper.getSpacing(context, 16),
            ),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: ResponsiveHelper.getIconSize(context, 56),
                      height: ResponsiveHelper.getIconSize(context, 56),
                      decoration: BoxDecoration(
                        color: AppTheme.darkBg2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          (user?.name != null && user!.name.isNotEmpty) 
                              ? user.name.substring(0, 1).toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getFontSize(context, 24),
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // User Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'User',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getFontSize(context, 18),
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppTheme.primaryGreen.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  (user?.role ?? 'user').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.getFontSize(context, 11),
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryGreen,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  user?.email ?? '',
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.getFontSize(context, 13),
                                    color: AppTheme.textSecondary,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (user?.presidentName != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: AppTheme.primaryGreen.withOpacity(0.7),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'President: ${user!.presidentName}',
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getFontSize(context, 12),
                                      color: AppTheme.textSecondary.withOpacity(0.9),
                                      letterSpacing: 0.2,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (user?.location != null) ...[
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: AppTheme.primaryGreen.withOpacity(0.7),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    user!.location!,
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getFontSize(context, 12),
                                      color: AppTheme.textSecondary.withOpacity(0.9),
                                      letterSpacing: 0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              if (user?.location != null && (user?.contactPhone != null || user?.phone != null)) ...[
                                const SizedBox(width: 12),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: AppTheme.textSecondary.withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (user?.contactPhone != null || user?.phone != null) ...[
                                Icon(
                                  Icons.phone_outlined,
                                  size: 14,
                                  color: AppTheme.primaryGreen.withOpacity(0.7),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    user?.contactPhone ?? user!.phone!,
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getFontSize(context, 12),
                                      color: AppTheme.textSecondary.withOpacity(0.9),
                                      letterSpacing: 0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status Indicator
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Organizational Hierarchy Section
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (user?.societyName != null)
                      _buildInfoCard(
                        Icons.home_outlined,
                        'Society',
                        user!.societyName!,
                      ),
                    if (user?.bmcName != null || user?.dairyName != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (user?.bmcName != null)
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  // Extract numeric ID from bmcId (assumes format like "2")
                                  final id = user.bmcId ?? user.id;
                                  _showEntityDetails(
                                    context,
                                    'BMC Details',
                                    Icons.business_outlined,
                                    {
                                      'ID': id,
                                      'Name': user.bmcName,
                                    },
                                  );
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: _buildSmallHierarchyCard(
                                  Icons.business_outlined,
                                  'BMC',
                                  user!.bmcName!,
                                ),
                              ),
                            ),
                          if (user?.bmcName != null && user?.dairyName != null)
                            const SizedBox(width: 8),
                          if (user?.dairyName != null)
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  // Extract numeric ID from dairyId
                                  final id = user.dairyId ?? user.id;
                                  _showEntityDetails(
                                    context,
                                    'Dairy Details',
                                    Icons.factory_outlined,
                                    {
                                      'ID': id,
                                      'Name': user.dairyName,
                                    },
                                  );
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: _buildSmallHierarchyCard(
                                  Icons.factory_outlined,
                                  'Dairy',
                                  user!.dairyName!,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
                // Statistics Section (Last 30 Days) - Always show
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBg2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            size: 16,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Last 30 Days Statistics',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getFontSize(context, 13),
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryGreen,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              Icons.refresh,
                              size: 18,
                              color: AppTheme.primaryGreen,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            onPressed: _loadData,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatChip(
                              'Revenue',
                              '₹${(_statistics?['totalRevenue30Days'] ?? 0).toStringAsFixed(2)}',
                              Icons.currency_rupee,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatChip(
                              'Collection',
                              '${(_statistics?['totalCollection30Days'] ?? 0).toStringAsFixed(2)} L',
                              Icons.water_drop_outlined,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatChip(
                              'Avg Fat',
                              '${(_statistics?['avgFat'] ?? 0).toStringAsFixed(2)}%',
                              Icons.opacity,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatChip(
                              'Avg SNF',
                              '${(_statistics?['avgSnf'] ?? 0).toStringAsFixed(2)}%',
                              Icons.water,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: _isLoading
                  ? const Center(
                      child: FlowerSpinner(
                        size: 48,
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 24),
                              CustomButton(
                                text: 'Retry',
                                onPressed: _loadData,
                                icon: Icons.refresh,
                              ),
                            ],
                          ),
                        )
                      : CustomScrollView(
                          slivers: [
                            // Section Header
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              const Text(
                                'Machines',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_machines.length}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Machines List
                      _machines.isEmpty
                          ? SliverFillRemaining(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.agriculture_outlined,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No machines found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final machine = _machines[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: MachineCard(machine: machine),
                                    );
                                  },
                                  childCount: _machines.length,
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallHierarchyCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkBg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 14,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(context, 11),
              color: AppTheme.textSecondary.withOpacity(0.8),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(context, 12),
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen.withOpacity(0.08),
            AppTheme.primaryGreen.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(context, 11),
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(context, 13),
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                letterSpacing: 0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool showDivider = false}) {
    return Column(
      children: [
        if (showDivider) ...[
          const SizedBox(height: 8),
          Divider(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            height: 1,
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 16,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
  Widget _buildStatChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(context, 9),
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(context, 11),
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                    letterSpacing: 0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }}

