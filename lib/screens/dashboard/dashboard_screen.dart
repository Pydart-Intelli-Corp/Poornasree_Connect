import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  // Settings state
  bool _isDarkMode = true;
  String _selectedLanguage = 'English';

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

    // Load machines list and statistics in parallel
    final results = await Future.wait([
      _dashboardService.getMachinesList(token),
      _dashboardService.getStatistics(token),
    ]);

    final machinesResult = results[0];
    final statsResult = results[1];

    if (machinesResult['success']) {
      _machines = machinesResult['machines'];
    } else {
      _errorMessage = machinesResult['message'];
    }

    if (statsResult['success']) {
      _statistics = statsResult['statistics'];
    }

    setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        PageTransition(child: const LoginScreen(), type: TransitionType.fade),
        (route) => false,
      );
    }
  }

  void _showProfileMenu() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    ProfileMenuScreen.show(
      context,
      user: user,
      isDarkMode: _isDarkMode,
      selectedLanguage: _selectedLanguage,
      onThemeChanged: (value) {
        setState(() => _isDarkMode = value);
        // TODO: Implement actual theme switching
      },
      onLanguageChanged: (value) {
        setState(() => _selectedLanguage = value);
        // TODO: Implement actual language switching
      },
      onLogout: _logout,
      onProfileUpdated: () => setState(() {}),
    );
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
                MaterialPageRoute(builder: (context) => const ReportsScreen()),
              );
            },
            tooltip: 'Reports',
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _showProfileMenu,
            tooltip: 'Profile Menu',
          ),
        ],
      ),
      body: Column(
        children: [
          // Dashboard Header
          DashboardHeader(
            user: user,
            statistics: _statistics,
            onRefresh: _loadData,
          ),

          // Main Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: FlowerSpinner(size: 48));
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return _buildMachinesList();
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
    );
  }

  Widget _buildMachinesList() {
    return CustomScrollView(
      slivers: [
        // Section Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Machines',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            ? SliverFillRemaining(child: _buildEmptyState())
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final machine = _machines[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MachineCard(
                        machineData: machine,
                        showActions: true,
                        onView: () => _handleMachineView(machine),
                        onEdit: () => _handleMachineEdit(machine),
                        // Password and master functionality hidden
                        onPasswordSettings: null,
                        onMasterBadgeClick: null,
                      ),
                    );
                  }, childCount: _machines.length),
                ),
              ),
      ],
    );
  }

  void _handleMachineView(Map<String, dynamic> machine) {
    // TODO: Navigate to machine detail screen
    CustomSnackbar.show(
      context,
      message: 'Machine Details',
      submessage:
          'Viewing ${machine['machineId'] ?? machine['machine_id'] ?? 'Machine'}',
      duration: const Duration(seconds: 2),
    );
  }

  void _handleMachineEdit(Map<String, dynamic> machine) {
    // TODO: Navigate to machine edit screen
    CustomSnackbar.show(
      context,
      message: 'Edit Machine',
      submessage:
          'Editing ${machine['machineId'] ?? machine['machine_id'] ?? 'Machine'}',
      duration: const Duration(seconds: 2),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
