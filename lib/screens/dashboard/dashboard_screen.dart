import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';
import '../../l10n/l10n.dart';
import '../auth/login_screen.dart';
import '../reports/reports_screen.dart';
import 'machine_control_panel_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  final BluetoothService _bluetoothService = BluetoothService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final OfflineCacheService _cacheService = OfflineCacheService();

  List<dynamic> _machines = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String? _errorMessage;

  // Offline mode tracking
  bool _isOffline = false;
  bool _isFromCache = false;
  String _lastSyncTime = 'Never';
  StreamSubscription<bool>? _connectivitySubscription;

  // Settings state
  bool _isDarkMode = true;
  bool _isAutoConnectEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeTheme();
    _initConnectivityListener();
    _loadData();
    _initializeBluetooth();
  }

  void _initializeTheme() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    setState(() {
      _isDarkMode = themeProvider.isDarkMode;
    });
  }

  void _initConnectivityListener() {
    // Start periodic connectivity checking
    _connectivityService.startPeriodicCheck(
      interval: const Duration(seconds: 30),
    );

    // Listen to connectivity changes
    _connectivitySubscription = _connectivityService.connectivityStream.listen((
      isConnected,
    ) {
      if (mounted) {
        setState(() {
          _isOffline = !isConnected;
        });

        // If connection restored and we were showing cached data, refresh
        if (isConnected && _isFromCache) {
          print('🌐 [Dashboard] Connection restored - refreshing data...');
          _loadData();
        }
      }
    });

    // Load last sync time
    _loadLastSyncTime();
  }

  Future<void> _loadLastSyncTime() async {
    final lastSync = await _cacheService.getLastSyncTimeFormatted();
    if (mounted) {
      setState(() {
        _lastSyncTime = lastSync;
      });
    }
  }

  void _initializeBluetooth() async {
    // Load auto-connect preference
    await _bluetoothService.loadAutoConnectPreference();
    setState(() {
      _isAutoConnectEnabled = _bluetoothService.isAutoConnectEnabled;
    });

    // Start background scanning for Lactosure-BLE devices
    _bluetoothService.startScan();

    // Listen to device updates
    _bluetoothService.devicesStream.listen((devices) {
      if (mounted) {
        setState(() {});
      }
    });

    // Listen to connection status changes to show/hide control panel button
    _bluetoothService.connectedMachinesStream.listen((connectedMachines) {
      if (mounted) {
        setState(() {});
      }
    });

    // If auto-connect is enabled, trigger it after scan
    if (_isAutoConnectEnabled) {
      await _bluetoothService.triggerAutoConnect();
    }
  }

  @override
  void dispose() {
    _bluetoothService.stopScan();
    _connectivitySubscription?.cancel();
    _connectivityService.stopPeriodicCheck();
    super.dispose();
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

    bool fromCache = false;

    if (machinesResult['success']) {
      _machines = machinesResult['machines'];
      if (machinesResult['fromCache'] == true) fromCache = true;
    } else {
      _errorMessage = machinesResult['message'];
    }

    if (statsResult['success']) {
      _statistics = statsResult['statistics'];
      if (statsResult['fromCache'] == true) fromCache = true;
    }

    // Update last sync time
    await _loadLastSyncTime();

    setState(() {
      _isLoading = false;
      _isFromCache = fromCache;
      _isOffline = !_connectivityService.isConnected;
    });
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
      isAutoConnectEnabled: _isAutoConnectEnabled,
      onThemeChanged: (value) {
        setState(() => _isDarkMode = value);
        // Theme is persisted by ThemeProvider in profile_menu_screen
      },
      onLanguageChanged: (locale) {
        // Language is handled by AppLocalizations, just rebuild UI
        setState(() {});
      },
      onAutoConnectChanged: (value) async {
        setState(() => _isAutoConnectEnabled = value);
        await _bluetoothService.setAutoConnect(value);
      },
      onLogout: _logout,
      onProfileUpdated: () => setState(() {}),
    );
  }

  void _navigateToControlPanel() {
    final connectedMachines = _bluetoothService.connectedMachines;

    if (connectedMachines.isEmpty) {
      return;
    }

    // Get the first connected machine's ID
    final firstConnectedMachineId = connectedMachines.keys.first;

    // Find the corresponding machine from the machines list
    final machine = _machines.firstWhere(
      (m) =>
          m['machine_id'].toString().replaceAll(RegExp(r'[^0-9]'), '') ==
          firstConnectedMachineId,
      orElse: () => {
        'machine_id': firstConnectedMachineId,
        'name': 'Machine $firstConnectedMachineId',
        'machine_type': 'Lactosure',
      },
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MachineControlPanelScreen(
          machineId:
              machine['machine_id']?.toString() ?? firstConnectedMachineId,
          machineName:
              machine['name']?.toString() ?? 'Machine $firstConnectedMachineId',
          machineType: machine['machine_type']?.toString() ?? 'Lactosure',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final hasConnectedDevice = _bluetoothService.connectedMachines.isNotEmpty;
    final l10n = AppLocalizations();

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        final shouldExit = await ExitConfirmationDialog.show(context);
        if (shouldExit && context.mounted) {
          // Exit the app
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.tr('dashboard')),
          actions: [
            // Bluetooth dropdown menu
            _BluetoothDropdownButton(bluetoothService: _bluetoothService),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: l10n.tr('refresh'),
            ),
            IconButton(
              icon: const Icon(Icons.assessment_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ReportsScreen(defaultLocalMode: false),
                  ),
                );
              },
              tooltip: l10n.tr('reports'),
            ),
            // Offline/Sync Status Icon
            if (_isOffline || _isFromCache) _buildOfflineStatusIcon(),
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: _showProfileMenu,
              tooltip: l10n.tr('profile'),
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
        // Floating Control Panel Button (shown when Bluetooth device connected)
        floatingActionButton: hasConnectedDevice
            ? FloatingActionButton.extended(
                onPressed: _navigateToControlPanel,
                backgroundColor: AppTheme.primaryGreen,
                icon: const Icon(Icons.settings_remote, color: Colors.white),
                label: Text(
                  l10n.tr('control_panel'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
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

  /// Minimal offline status icon for AppBar
  Widget _buildOfflineStatusIcon() {
    final l10n = AppLocalizations();
    return IconButton(
      icon: Stack(
        children: [
          Icon(
            _isOffline ? Icons.cloud_off : Icons.cloud_done,
            color: _isOffline ? Colors.orange : AppTheme.primaryTeal,
          ),
          // Small indicator dot
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _isOffline ? Colors.orange : AppTheme.primaryTeal,
                shape: BoxShape.circle,
                border: Border.all(color: context.borderColor, width: 1),
              ),
            ),
          ),
        ],
      ),
      onPressed: _showOfflineStatusPopup,
      tooltip: _isOffline
          ? l10n.tr('offline_mode')
          : l10n.tr('using_cached_data'),
    );
  }

  /// Show offline status popup with details
  void _showOfflineStatusPopup() {
    final l10n = AppLocalizations();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _isOffline ? Icons.cloud_off : Icons.cloud_done,
              color: _isOffline ? Colors.orange : AppTheme.primaryTeal,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              _isOffline ? l10n.tr('offline_mode') : l10n.tr('cached_data'),
              style: TextStyle(color: context.textPrimaryColor, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isOffline
                  ? l10n.tr('offline_cached_msg')
                  : l10n.tr('cached_pull_refresh'),
              style: TextStyle(color: context.textSecondaryColor, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: context.textSecondaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '${l10n.tr('last_synced')}: $_lastSyncTime',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (!_isOffline)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _loadData();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.tr('sync_now')),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryTeal,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.tr('ok')),
            style: TextButton.styleFrom(
              foregroundColor: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations();
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
            text: l10n.tr('retry'),
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
                Text(
                  AppLocalizations().tr('machines'),
                  style: const TextStyle(
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
  }

  void _handleMachineEdit(Map<String, dynamic> machine) {
    // TODO: Navigate to machine edit screen
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
            AppLocalizations().tr('no_machines'),
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

/// Bluetooth dropdown button for app bar
class _BluetoothDropdownButton extends StatefulWidget {
  final BluetoothService bluetoothService;

  const _BluetoothDropdownButton({required this.bluetoothService});

  @override
  State<_BluetoothDropdownButton> createState() =>
      _BluetoothDropdownButtonState();
}

class _BluetoothDropdownButtonState extends State<_BluetoothDropdownButton> {
  BluetoothStatus _status = BluetoothStatus.offline;
  int _connectedCount = 0;
  int _availableCount = 0;
  bool _isConnectingAll = false;
  bool _isDisconnectingAll = false;

  @override
  void initState() {
    super.initState();
    _status = widget.bluetoothService.status;
    _availableCount = widget.bluetoothService.availableMachineIds.length;
    _connectedCount = widget.bluetoothService.connectedMachines.length;

    // Listen to status changes
    widget.bluetoothService.statusStream.listen((status) {
      if (mounted) setState(() => _status = status);
    });

    // Listen to available machine IDs
    widget.bluetoothService.availableMachineIdsStream.listen((ids) {
      if (mounted) setState(() => _availableCount = ids.length);
    });

    // Listen to connected machines
    widget.bluetoothService.connectedMachinesStream.listen((machines) {
      if (mounted)
        setState(
          () => _connectedCount = machines.values.where((v) => v).length,
        );
    });
  }

  Color _getStatusColor() {
    if (_connectedCount > 0) return Colors.green;
    if (_status == BluetoothStatus.scanning) return Colors.amber;
    if (_availableCount > 0) return Colors.blue;
    return Colors.grey;
  }

  IconData _getStatusIcon() {
    if (_connectedCount > 0) return Icons.bluetooth_connected;
    if (_status == BluetoothStatus.scanning) return Icons.bluetooth_searching;
    if (_availableCount > 0) return Icons.bluetooth;
    return Icons.bluetooth_disabled;
  }

  Future<void> _handleScan() async {
    await widget.bluetoothService.requestPermissions();
    widget.bluetoothService.startScan();
  }

  Future<void> _handleConnectAll() async {
    setState(() => _isConnectingAll = true);

    final results = await widget.bluetoothService.connectAll();

    if (mounted) {
      setState(() => _isConnectingAll = false);

      final successCount = results.values.where((v) => v).length;
      if (successCount > 0) {
        CustomSnackbar.showSuccess(
          context,
          message:
              '${AppLocalizations().tr('connected_to_devices')} $successCount/${results.length} ${AppLocalizations().tr('devices')}',
          submessage: successCount == results.length
              ? AppLocalizations().tr('all_devices_connected')
              : AppLocalizations().tr('some_devices_failed'),
        );
      } else {
        CustomSnackbar.showError(
          context,
          message: AppLocalizations().tr('connection_failed'),
          submessage: AppLocalizations().tr('could_not_connect'),
        );
      }
    }
  }

  Future<void> _handleDisconnectAll() async {
    setState(() => _isDisconnectingAll = true);

    await widget.bluetoothService.disconnectAll();

    if (mounted) {
      setState(() => _isDisconnectingAll = false);

      CustomSnackbar.showSuccess(
        context,
        message: AppLocalizations().tr('disconnected_from_all'),
        submessage: AppLocalizations().tr('all_ble_closed'),
      );
    }
  }

  void _handleStopScan() {
    widget.bluetoothService.stopScan();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: AppLocalizations().tr('bluetooth_options'),
      icon: Stack(
        children: [
          Icon(_getStatusIcon(), color: _getStatusColor()),
          // Available count badge (bottom-left, blue)
          if (_availableCount > 0 && _connectedCount == 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                child: Text(
                  '$_availableCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          // Connected count badge (top-right, green)
          if (_connectedCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                child: Text(
                  '$_connectedCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onSelected: (value) async {
        switch (value) {
          case 'scan':
            _handleScan();
            break;
          case 'stop_scan':
            _handleStopScan();
            break;
          case 'connect_all':
            _handleConnectAll();
            break;
          case 'disconnect_all':
            _handleDisconnectAll();
            break;
        }
      },
      itemBuilder: (context) => [
        // Status header
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _status == BluetoothStatus.scanning
                        ? AppLocalizations().tr('scanning')
                        : _connectedCount > 0
                        ? '$_connectedCount ${AppLocalizations().tr('connected_count')}'
                        : _availableCount > 0
                        ? '$_availableCount ${AppLocalizations().tr('available_count')}'
                        : AppLocalizations().tr('offline'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                  ),
                ],
              ),
              if (_availableCount > 0 && _connectedCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Text(
                    '$_availableCount ${AppLocalizations().tr('devices_found')}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),

        // Scan option
        if (_status == BluetoothStatus.scanning)
          PopupMenuItem<String>(
            value: 'stop_scan',
            child: Row(
              children: [
                Icon(Icons.stop, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(child: Text(AppLocalizations().tr('stop_scan'))),
              ],
            ),
          )
        else
          PopupMenuItem<String>(
            value: 'scan',
            child: Row(
              children: [
                Icon(Icons.bluetooth_searching, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(AppLocalizations().tr('scan_for_devices')),
                ),
              ],
            ),
          ),

        // Connect All option
        PopupMenuItem<String>(
          value: 'connect_all',
          enabled:
              _availableCount > 0 &&
              !_isConnectingAll &&
              _status != BluetoothStatus.scanning,
          child: Row(
            children: [
              _isConnectingAll
                  ? _FlowerSpinner(size: 24)
                  : Icon(
                      Icons.bluetooth_connected,
                      color: _availableCount > 0 ? Colors.green : Colors.grey,
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isConnectingAll
                      ? AppLocalizations().tr('connecting')
                      : AppLocalizations().tr('connect_all'),
                ),
              ),
            ],
          ),
        ),

        // Disconnect All option
        PopupMenuItem<String>(
          value: 'disconnect_all',
          enabled: _connectedCount > 0 && !_isDisconnectingAll,
          child: Row(
            children: [
              _isDisconnectingAll
                  ? _FlowerSpinner(size: 24)
                  : Icon(
                      Icons.bluetooth_disabled,
                      color: _connectedCount > 0 ? Colors.red : Colors.grey,
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isDisconnectingAll
                      ? AppLocalizations().tr('disconnecting')
                      : AppLocalizations().tr('disconnect_all'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Rotating flower spinner for loading
class _FlowerSpinner extends StatefulWidget {
  final double size;

  const _FlowerSpinner({required this.size});

  @override
  State<_FlowerSpinner> createState() => _FlowerSpinnerState();
}

class _FlowerSpinnerState extends State<_FlowerSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RotationTransition(
        turns: _controller,
        child: Image.asset(
          'assets/images/flower.png',
          width: widget.size,
          height: widget.size,
        ),
      ),
    );
  }
}
