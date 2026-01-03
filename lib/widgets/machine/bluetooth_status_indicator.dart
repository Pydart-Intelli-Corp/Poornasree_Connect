import 'package:flutter/material.dart';
import '../../services/bluetooth_service.dart';
import '../../utils/config/theme.dart';

/// Professional Bluetooth status indicator with real-time state updates
class BluetoothStatusIndicator extends StatefulWidget {
  final bool showLabel;
  final double iconSize;
  final double fontSize;
  final bool compact;

  const BluetoothStatusIndicator({
    super.key,
    this.showLabel = true,
    this.iconSize = 20,
    this.fontSize = 13,
    this.compact = false,
  });

  @override
  State<BluetoothStatusIndicator> createState() => _BluetoothStatusIndicatorState();
}

class _BluetoothStatusIndicatorState extends State<BluetoothStatusIndicator> {
  final BluetoothService _bluetoothService = BluetoothService();
  BluetoothStatus _currentStatus = BluetoothStatus.offline;
  int _deviceCount = 0;

  @override
  void initState() {
    super.initState();
    _currentStatus = _bluetoothService.status;
    _deviceCount = _bluetoothService.devices.length;
    
    // Listen to status changes
    _bluetoothService.statusStream.listen((status) {
      if (mounted) {
        setState(() => _currentStatus = status);
      }
    });
    
    // Listen to device changes
    _bluetoothService.devicesStream.listen((devices) {
      if (mounted) {
        setState(() => _deviceCount = devices.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo();

    if (widget.compact) {
      return _buildCompactIndicator(statusInfo);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusInfo.color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusIcon(statusInfo),
          if (widget.showLabel) ...[
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusInfo.label,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w600,
                    color: statusInfo.color,
                  ),
                ),
                if (_deviceCount > 0 && _currentStatus == BluetoothStatus.available)
                  Text(
                    '$_deviceCount device${_deviceCount > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: widget.fontSize - 2,
                      color: statusInfo.color.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build compact indicator for space-constrained layouts
  Widget _buildCompactIndicator(_StatusInfo statusInfo) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: statusInfo.color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Icon(
        statusInfo.icon,
        size: widget.iconSize,
        color: statusInfo.color,
      ),
    );
  }

  /// Build animated status icon
  Widget _buildStatusIcon(_StatusInfo statusInfo) {
    if (_currentStatus == BluetoothStatus.scanning) {
      return SizedBox(
        width: widget.iconSize,
        height: widget.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(statusInfo.color),
        ),
      );
    }

    return Icon(
      statusInfo.icon,
      size: widget.iconSize,
      color: statusInfo.color,
    );
  }

  /// Get status information based on current state
  _StatusInfo _getStatusInfo() {
    switch (_currentStatus) {
      case BluetoothStatus.offline:
        return _StatusInfo(
          icon: Icons.bluetooth_disabled,
          label: 'Offline',
          color: AppTheme.textSecondary,
        );
      case BluetoothStatus.scanning:
        return _StatusInfo(
          icon: Icons.bluetooth_searching,
          label: 'Scanning...',
          color: AppTheme.primaryBlue,
        );
      case BluetoothStatus.available:
        return _StatusInfo(
          icon: Icons.bluetooth,
          label: 'Available',
          color: AppTheme.primaryGreen,
        );
      case BluetoothStatus.connected:
        return _StatusInfo(
          icon: Icons.bluetooth_connected,
          label: 'Connected',
          color: AppTheme.primaryGreen,
        );
    }
  }
}

/// Status information holder
class _StatusInfo {
  final IconData icon;
  final String label;
  final Color color;

  _StatusInfo({
    required this.icon,
    required this.label,
    required this.color,
  });
}
