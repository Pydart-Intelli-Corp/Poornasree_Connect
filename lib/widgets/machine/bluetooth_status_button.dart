import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/bluetooth_service.dart';
import '../../l10n/l10n.dart';

/// Machine-specific Bluetooth status button
/// Shows "Offline" initially, changes to "Connect" when BLE device is discovered
/// Shows "Disconnect" when connected
class BluetoothStatusButton extends StatefulWidget {
  final String? machineId; // Machine ID to match against BLE devices (e.g., "M201")
  final bool showLabel;
  final double iconSize;
  final double fontSize;
  final VoidCallback? onTap;
  final bool showDeviceCount;

  const BluetoothStatusButton({
    super.key,
    this.machineId,
    this.showLabel = true,
    this.iconSize = 20,
    this.fontSize = 13,
    this.onTap,
    this.showDeviceCount = false,
  });

  @override
  State<BluetoothStatusButton> createState() => _BluetoothStatusButtonState();
}

class _BluetoothStatusButtonState extends State<BluetoothStatusButton> {
  final BluetoothService _bluetoothService = BluetoothService();
  StreamSubscription<Set<String>>? _machineIdsSubscription;
  StreamSubscription<Map<String, bool>>? _connectedMachinesSubscription;
  bool _isBleAvailable = false;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _checkInitialAvailability();
    _checkInitialConnectionState();
    _listenToMachineIds();
    _listenToConnectedMachines();
    _listenToScanStatus();
    _startBackgroundScan();
  }

  @override
  void dispose() {
    _machineIdsSubscription?.cancel();
    _connectedMachinesSubscription?.cancel();
    super.dispose();
  }

  /// Check if this machine is already available via BLE
  void _checkInitialAvailability() {
    if (widget.machineId != null) {
      _isBleAvailable = _bluetoothService.isMachineAvailable(widget.machineId!);
    }
  }

  /// Check if this machine is already connected
  void _checkInitialConnectionState() {
    if (widget.machineId != null) {
      _isConnected = _bluetoothService.isMachineConnected(widget.machineId!);
    }
  }

  /// Listen for available machine IDs updates
  void _listenToMachineIds() {
    _machineIdsSubscription = _bluetoothService.availableMachineIdsStream.listen((machineIds) {
      if (widget.machineId != null && mounted) {
        final numericId = widget.machineId!.replaceAll(RegExp(r'[^0-9]'), '');
        final isAvailable = machineIds.contains(numericId);
        
        if (isAvailable != _isBleAvailable) {
          setState(() {
            _isBleAvailable = isAvailable;
          });
          if (isAvailable) {
            print('🟢 [BLE Button] ${widget.machineId} is now available for connection');
          }
        }
      }
    });
  }

  /// Listen for connected machines updates
  void _listenToConnectedMachines() {
    _connectedMachinesSubscription = _bluetoothService.connectedMachinesStream.listen((connectedMachines) {
      if (widget.machineId != null && mounted) {
        final numericId = widget.machineId!.replaceAll(RegExp(r'[^0-9]'), '');
        final isConnected = connectedMachines[numericId] == true;
        
        if (isConnected != _isConnected) {
          setState(() {
            _isConnected = isConnected;
            _isConnecting = false;
          });
          print('🔵 [BLE Button] ${widget.machineId} connection state: $isConnected');
        }
      }
    });
  }

  /// Listen to scan status changes
  void _listenToScanStatus() {
    _bluetoothService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _isScanning = status == BluetoothStatus.scanning;
        });
      }
    });
  }

  /// Start background scanning
  Future<void> _startBackgroundScan() async {
    await _bluetoothService.requestPermissions();
    _bluetoothService.startScan();
  }

  /// Handle button tap - connect or disconnect
  Future<void> _handleTap() async {
    if (widget.machineId == null) return;
    
    if (_isConnected) {
      // Disconnect
      await _bluetoothService.disconnectFromMachine(widget.machineId!);
    } else if (_isBleAvailable && !_isConnecting) {
      // Connect
      setState(() {
        _isConnecting = true;
      });
      
      final success = await _bluetoothService.connectToMachine(widget.machineId!);
      
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isConnected = success;
        });
      }
    }
    
    // Call optional callback
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (_isBleAvailable || _isConnected) ? _handleTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statusInfo.bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: statusInfo.borderColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusIcon(statusInfo),
              if (widget.showLabel) ...[
                const SizedBox(width: 6),
                Text(
                  statusInfo.label,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w600,
                    color: statusInfo.textColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build status icon
  Widget _buildStatusIcon(_StatusInfo statusInfo) {
    // Show rotating flower spinner when connecting
    if (_isConnecting) {
      return _FlowerSpinner(size: widget.iconSize);
    }
    
    return Icon(
      statusInfo.icon,
      size: widget.iconSize,
      color: statusInfo.iconColor,
    );
  }

  /// Get status information based on BLE availability and connection state
  _StatusInfo _getStatusInfo() {
    final l10n = AppLocalizations();
    if (_isConnected) {
      // Machine is connected - show "Disconnect" in red
      return _StatusInfo(
        icon: Icons.bluetooth_connected,
        label: l10n.tr('disconnect'),
        iconColor: Colors.red,
        textColor: Colors.red,
        bgColor: Colors.red.withOpacity(0.15),
        borderColor: Colors.red.withOpacity(0.5),
      );
    } else if (_isConnecting) {
      // Connecting - show "Connecting..." in amber
      return _StatusInfo(
        icon: Icons.bluetooth_searching,
        label: l10n.tr('connecting'),
        iconColor: Colors.amber,
        textColor: Colors.amber,
        bgColor: Colors.amber.withOpacity(0.15),
        borderColor: Colors.amber.withOpacity(0.5),
      );
    } else if (_isBleAvailable) {
      // Machine is available via BLE - show "Connect" in blue
      return _StatusInfo(
        icon: Icons.bluetooth,
        label: l10n.tr('connect'),
        iconColor: Colors.blue,
        textColor: Colors.blue,
        bgColor: Colors.blue.withOpacity(0.15),
        borderColor: Colors.blue.withOpacity(0.5),
      );
    } else if (_isScanning) {
      // Currently scanning - show subtle scanning indicator
      return _StatusInfo(
        icon: Icons.bluetooth_searching,
        label: l10n.tr('offline_status'),
        iconColor: Colors.grey.shade400,
        textColor: Colors.grey.shade300,
        bgColor: Colors.grey.withOpacity(0.1),
        borderColor: Colors.grey.withOpacity(0.3),
      );
    } else {
      // Machine not available - show "Offline" in grey
      return _StatusInfo(
        icon: Icons.bluetooth_disabled,
        label: l10n.tr('offline_status'),
        iconColor: Colors.grey.shade400,
        textColor: Colors.grey.shade300,
        bgColor: Colors.grey.withOpacity(0.1),
        borderColor: Colors.grey.withOpacity(0.3),
      );
    }
  }
}

/// Status information holder
class _StatusInfo {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;
  final Color bgColor;
  final Color borderColor;

  _StatusInfo({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
    required this.bgColor,
    required this.borderColor,
  });
}

/// Rotating flower spinner for connection loading
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