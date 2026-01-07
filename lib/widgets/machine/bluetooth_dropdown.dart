import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothService;
import '../../services/bluetooth_service.dart';
import '../../utils/config/theme.dart';
import '../../l10n/app_localizations.dart';

/// Professional Bluetooth device dropdown with Lactosure-BLE filtering
class BluetoothDropdown extends StatefulWidget {
  final void Function(BluetoothDevice)? onDeviceSelected;
  final BluetoothDevice? selectedDevice;
  final bool showLabel;
  final bool compact;

  const BluetoothDropdown({
    super.key,
    this.onDeviceSelected,
    this.selectedDevice,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  State<BluetoothDropdown> createState() => _BluetoothDropdownState();
}

class _BluetoothDropdownState extends State<BluetoothDropdown> {
  final BluetoothService _bluetoothService = BluetoothService();
  List<BluetoothDevice> _devices = [];
  BluetoothStatus _status = BluetoothStatus.offline;
  BluetoothDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _selectedDevice = widget.selectedDevice;
    _devices = _bluetoothService.devices;
    _status = _bluetoothService.status;

    // Listen to device updates
    _bluetoothService.devicesStream.listen((devices) {
      if (mounted) {
        setState(() => _devices = devices);
      }
    });

    // Listen to status updates
    _bluetoothService.statusStream.listen((status) {
      if (mounted) {
        setState(() => _status = status);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactDropdown();
    }

    return _buildFullDropdown();
  }

  /// Build full-featured dropdown
  Widget _buildFullDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: PopupMenuButton<BluetoothDevice>(
        enabled: _devices.isNotEmpty,
        offset: const Offset(0, 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppTheme.cardDark,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bluetooth,
                size: 20,
                color: _devices.isNotEmpty ? AppTheme.primaryBlue : AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              if (widget.showLabel)
                Text(
                  _getDropdownLabel(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _devices.isNotEmpty ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: _devices.isNotEmpty ? AppTheme.primaryBlue : AppTheme.textSecondary,
              ),
            ],
          ),
        ),
        itemBuilder: (context) => _buildMenuItems(),
        onSelected: (device) {
          setState(() => _selectedDevice = device);
          widget.onDeviceSelected?.call(device);
        },
      ),
    );
  }

  /// Build compact dropdown for space-constrained layouts
  Widget _buildCompactDropdown() {
    return PopupMenuButton<BluetoothDevice>(
      enabled: _devices.isNotEmpty,
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: AppTheme.cardDark,
      icon: Icon(
        Icons.arrow_drop_down,
        color: _devices.isNotEmpty ? AppTheme.primaryBlue : AppTheme.textSecondary,
        size: 24,
      ),
      tooltip: _getDropdownLabel(),
      itemBuilder: (context) => _buildMenuItems(),
      onSelected: (device) {
        setState(() => _selectedDevice = device);
        widget.onDeviceSelected?.call(device);
      },
    );
  }

  /// Build dropdown menu items
  List<PopupMenuEntry<BluetoothDevice>> _buildMenuItems() {
    // Show scanning state
    if (_status == BluetoothStatus.scanning && _devices.isEmpty) {
      return [
        PopupMenuItem(
          enabled: false,
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppTheme.primaryBlue),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations().tr('scanning_for_devices'),
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ];
    }

    // Show no devices found
    if (_devices.isEmpty) {
      return [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.bluetooth_disabled, color: AppTheme.textSecondary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations().tr('no_lactosure_ble_devices'),
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations().tr('make_sure_devices_powered'),
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    // Show device list with header
    final items = <PopupMenuEntry<BluetoothDevice>>[
      PopupMenuItem(
        enabled: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '${AppLocalizations().tr('available_devices_count')} (${_devices.length})',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      const PopupMenuDivider(height: 1),
    ];

    // Add device items
    for (var i = 0; i < _devices.length; i++) {
      final device = _devices[i];
      final isSelected = _selectedDevice?.remoteId == device.remoteId;

      items.add(
        PopupMenuItem<BluetoothDevice>(
          value: device,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.bluetooth_connected : Icons.bluetooth,
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        device.platformName.isNotEmpty
                            ? device.platformName
                            : AppLocalizations().tr('unknown_device'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        device.remoteId.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryBlue,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      );

      // Add divider between items (except last)
      if (i < _devices.length - 1) {
        items.add(const PopupMenuDivider(height: 1));
      }
    }

    return items;
  }

  /// Get dropdown label text
  String _getDropdownLabel() {
    if (_selectedDevice != null) {
      return _selectedDevice!.platformName.isNotEmpty
          ? _selectedDevice!.platformName
          : AppLocalizations().tr('device_selected');
    }

    switch (_status) {
      case BluetoothStatus.offline:
        return AppLocalizations().tr('no_devices');
      case BluetoothStatus.scanning:
        return AppLocalizations().tr('scanning');
      case BluetoothStatus.available:
        return '${_devices.length} ${AppLocalizations().tr('devices')}';
      case BluetoothStatus.connected:
        return AppLocalizations().tr('connected');
    }
  }
}
