import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Bluetooth connection status enum
enum BluetoothStatus {
  offline,      // Not scanning, no devices
  scanning,     // Currently scanning for devices
  available,    // Lactosure-BLE devices found
  connected,    // Connected to a device
}

/// Professional BluetoothService with auto-scan and state management
class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal() {
    _initialize();
  }

  // Stream controllers
  final StreamController<List<BluetoothDevice>> _devicesController = StreamController.broadcast();
  final StreamController<BluetoothStatus> _statusController = StreamController.broadcast();
  final StreamController<BluetoothDevice?> _connectedDeviceController = StreamController.broadcast();
  
  // Subscriptions
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Timer? _autoScanTimer;
  
  // State
  final List<BluetoothDevice> _lactosureDevices = [];
  BluetoothStatus _status = BluetoothStatus.offline;
  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  bool _autoScanEnabled = true;

  // Constants
  static const String deviceNameFilter = 'Lactosure-BLE';
  static const Duration scanDuration = Duration(seconds: 8);
  static const Duration autoScanInterval = Duration(seconds: 15);

  // Public streams
  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;
  Stream<BluetoothStatus> get statusStream => _statusController.stream;
  Stream<BluetoothDevice?> get connectedDeviceStream => _connectedDeviceController.stream;

  // Public getters
  List<BluetoothDevice> get devices => List.unmodifiable(_lactosureDevices);
  BluetoothStatus get status => _status;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isScanning => _isScanning;
  bool get hasDevices => _lactosureDevices.isNotEmpty;

  /// Initialize the service with auto-scan
  void _initialize() {
    _updateStatus(BluetoothStatus.offline);
    // Auto-start scanning after a brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_autoScanEnabled) {
        startScan();
      }
    });
  }

  /// Start scanning for Lactosure-BLE devices
  Future<void> startScan() async {
    if (_isScanning) return;
    
    try {
      _isScanning = true;
      _updateStatus(BluetoothStatus.scanning);
      _lactosureDevices.clear();
      _devicesController.add([]);

      // Start BLE scan
      await FlutterBluePlus.startScan(timeout: scanDuration);
      
      // Listen to scan results
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        _handleScanResults,
        onError: (error) {
          _handleScanError(error);
        },
      );

      // Auto-stop after scan duration
      Future.delayed(scanDuration, () {
        stopScan();
        _scheduleNextScan();
      });
    } catch (e) {
      _handleScanError(e);
    }
  }

  /// Handle incoming scan results
  void _handleScanResults(List<ScanResult> results) {
    bool devicesUpdated = false;
    
    for (var result in results) {
      final device = result.device;
      final deviceName = device.platformName;
      
      // Filter for Lactosure-BLE devices only
      if (deviceName.contains(deviceNameFilter)) {
        // Check if device already exists
        final exists = _lactosureDevices.any((d) => d.remoteId == device.remoteId);
        
        if (!exists) {
          _lactosureDevices.add(device);
          devicesUpdated = true;
        }
      }
    }

    if (devicesUpdated) {
      _devicesController.add(List.from(_lactosureDevices));
      
      // Update status to available when devices are found
      if (_lactosureDevices.isNotEmpty && _status == BluetoothStatus.scanning) {
        _updateStatus(BluetoothStatus.available);
      }
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    if (!_isScanning) return;
    
    _isScanning = false;
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      // Ignore stop scan errors
    }

    // Update status based on devices found
    if (_lactosureDevices.isEmpty) {
      _updateStatus(BluetoothStatus.offline);
    } else {
      _updateStatus(BluetoothStatus.available);
    }
  }

  /// Schedule next auto-scan
  void _scheduleNextScan() {
    if (!_autoScanEnabled) return;
    
    _autoScanTimer?.cancel();
    _autoScanTimer = Timer(autoScanInterval, () {
      if (_autoScanEnabled && _status != BluetoothStatus.connected) {
        startScan();
      }
    });
  }

  /// Handle scan errors
  void _handleScanError(dynamic error) {
    _isScanning = false;
    _updateStatus(BluetoothStatus.offline);
    // You can add error logging here if needed
  }

  /// Update connection status
  void _updateStatus(BluetoothStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(_status);
    }
  }

  /// Connect to a device (placeholder for future implementation)
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      _connectedDevice = device;
      _updateStatus(BluetoothStatus.connected);
      _connectedDeviceController.add(_connectedDevice);
      
      // Stop auto-scanning when connected
      _autoScanTimer?.cancel();
      
      // Implement actual connection logic here
      // await device.connect();
    } catch (e) {
      _connectedDevice = null;
      _connectedDeviceController.add(null);
      _updateStatus(BluetoothStatus.available);
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      try {
        // await _connectedDevice!.disconnect();
      } catch (e) {
        // Handle disconnect error
      }
      
      _connectedDevice = null;
      _connectedDeviceController.add(null);
      _updateStatus(BluetoothStatus.available);
      
      // Resume auto-scanning
      if (_autoScanEnabled) {
        _scheduleNextScan();
      }
    }
  }

  /// Enable/disable auto-scan
  void setAutoScan(bool enabled) {
    _autoScanEnabled = enabled;
    if (enabled && !_isScanning && _status != BluetoothStatus.connected) {
      startScan();
    } else if (!enabled) {
      _autoScanTimer?.cancel();
    }
  }

  /// Clear all devices
  void clearDevices() {
    _lactosureDevices.clear();
    _devicesController.add([]);
    if (_status != BluetoothStatus.scanning && _status != BluetoothStatus.connected) {
      _updateStatus(BluetoothStatus.offline);
    }
  }

  /// Dispose service and clean up resources
  void dispose() {
    _autoScanTimer?.cancel();
    _scanSubscription?.cancel();
    _devicesController.close();
    _statusController.close();
    _connectedDeviceController.close();
  }
}
