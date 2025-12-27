import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  List<dynamic> _machines = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
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

    // Load machines list
    final machinesResult = await _dashboardService.getMachinesList(token);

    if (machinesResult['success']) {
      setState(() {
        _machines = machinesResult['machines'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = machinesResult['message'];
        _isLoading = false;
      });
    }
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
                // Additional Details Section
                if (user?.societyName != null || 
                    user?.bmcName != null || 
                    user?.dairyName != null || 
                    user?.location != null ||
                    user?.contactPhone != null ||
                    user?.phone != null) ...[
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
                      children: [
                        // Society Info (for farmers)
                        if (user?.societyName != null) 
                          _buildInfoRow(
                            Icons.home_outlined,
                            'Society',
                            user!.societyName!,
                          ),
                        
                        // BMC Info
                        if (user?.bmcName != null)
                          _buildInfoRow(
                            Icons.business_outlined,
                            'BMC',
                            user!.bmcName!,
                            showDivider: user.societyName != null,
                          ),
                        
                        // Dairy Info
                        if (user?.dairyName != null)
                          _buildInfoRow(
                            Icons.factory_outlined,
                            'Dairy',
                            user!.dairyName!,
                            showDivider: user.bmcName != null || user.societyName != null,
                          ),
                        
                        // Location
                        if (user?.location != null)
                          _buildInfoRow(
                            Icons.location_on_outlined,
                            'Location',
                            user!.location!,
                            showDivider: user.dairyName != null || user.bmcName != null || user.societyName != null,
                          ),
                        
                        // Contact Phone
                        if (user?.contactPhone != null || user?.phone != null)
                          _buildInfoRow(
                            Icons.phone_outlined,
                            'Phone',
                            user?.contactPhone ?? user!.phone!,
                            showDivider: user?.location != null || user?.dairyName != null || user?.bmcName != null || user?.societyName != null,
                          ),
                        
                        // President Name (for societies/dairies)
                        if (user?.presidentName != null)
                          _buildInfoRow(
                            Icons.person_outline,
                            'President',
                            user!.presidentName!,
                            showDivider: true,
                          ),
                      ],
                    ),
                  ),
                ],
                // Statistics Section (Last 30 Days)
                if (user?.totalRevenue30Days != null ||
                    user?.totalCollection30Days != null ||
                    user?.avgFat != null ||
                    user?.avgSnf != null) ...[
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
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (user?.totalRevenue30Days != null)
                              Expanded(
                                child: _buildStatChip(
                                  'Revenue',
                                  '₹${user!.totalRevenue30Days!.toStringAsFixed(2)}',
                                  Icons.currency_rupee,
                                ),
                              ),
                            if (user?.totalRevenue30Days != null && user?.totalCollection30Days != null)
                              const SizedBox(width: 8),
                            if (user?.totalCollection30Days != null)
                              Expanded(
                                child: _buildStatChip(
                                  'Collection',
                                  '${user!.totalCollection30Days!.toStringAsFixed(2)} L',
                                  Icons.water_drop_outlined,
                                ),
                              ),
                            if (user?.totalCollection30Days != null && user?.avgFat != null)
                              const SizedBox(width: 8),
                            if (user?.avgFat != null)
                              Expanded(
                                child: _buildStatChip(
                                  'Avg Fat',
                                  '${user!.avgFat!.toStringAsFixed(2)}%',
                                  Icons.opacity,
                                ),
                              ),
                            if (user?.avgFat != null && user?.avgSnf != null)
                              const SizedBox(width: 8),
                            if (user?.avgSnf != null)
                              Expanded(
                                child: _buildStatChip(
                                  'Avg SNF',
                                  '${user!.avgSnf!.toStringAsFixed(2)}%',
                                  Icons.water,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(context, 10),
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(context, 13),
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryGreen,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }}

