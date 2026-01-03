import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bluetooth connection status enum
enum BluetoothStatus {
  offline, // Not scanning, no devices
  scanning, // Currently scanning for devices
  available, // Lactosure-BLE devices found
  connected, // Connected to a device
}

/// Professional BluetoothService with auto-scan and state management
class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal() {
    _initialize();
  }

  // Stream controllers
  final StreamController<List<BluetoothDevice>> _devicesController =
      StreamController.broadcast();
  final StreamController<BluetoothStatus> _statusController =
      StreamController.broadcast();
  final StreamController<BluetoothDevice?> _connectedDeviceController =
      StreamController.broadcast();
  final StreamController<Set<String>> _availableMachineIdsController =
      StreamController.broadcast();
  final StreamController<Map<String, bool>> _connectedMachinesController =
      StreamController.broadcast();

  // Subscriptions
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Timer? _autoScanTimer;

  // State
  final List<BluetoothDevice> _lactosureDevices = [];
  final Set<String> _availableMachineIds =
      {}; // Store discovered machine serial numbers
  final Map<String, BluetoothDevice> _machineDeviceMap =
      {}; // Map machine serial to device
  final Map<String, bool> _connectedMachines =
      {}; // Track connected machines by serial
  BluetoothStatus _status = BluetoothStatus.offline;
  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  bool _autoScanEnabled = true;
  bool _permissionsGranted = false;
  bool _autoConnectEnabled = false; // Auto-connect toggle state

  // SharedPreferences key for auto-connect
  static const String _autoConnectKey = 'bluetooth_auto_connect';

  // Constants - Updated to match ESP32 BLE name format
  static const String deviceNamePrefix = 'Lactosure - Sl.No - ';
  static const Duration scanDuration = Duration(seconds: 8);
  static const Duration autoScanInterval = Duration(seconds: 15);

  // Public streams
  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;
  Stream<BluetoothStatus> get statusStream => _statusController.stream;
  Stream<BluetoothDevice?> get connectedDeviceStream =>
      _connectedDeviceController.stream;
  Stream<Set<String>> get availableMachineIdsStream =>
      _availableMachineIdsController.stream;
  Stream<Map<String, bool>> get connectedMachinesStream =>
      _connectedMachinesController.stream;

  // Public getters
  List<BluetoothDevice> get devices => List.unmodifiable(_lactosureDevices);
  BluetoothStatus get status => _status;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isScanning => _isScanning;
  bool get hasDevices => _lactosureDevices.isNotEmpty;
  Set<String> get availableMachineIds => Set.unmodifiable(_availableMachineIds);
  Map<String, bool> get connectedMachines =>
      Map.unmodifiable(_connectedMachines);
  bool get isAutoConnectEnabled => _autoConnectEnabled;

  /// Check if a machine ID is available via BLE
  /// machineId can be like "M201", "S201", etc. - extracts numeric part
  bool isMachineAvailable(String machineId) {
    // Extract numeric part from machine ID (e.g., "M201" -> "201")
    final numericId = machineId.replaceAll(RegExp(r'[^0-9]'), '');
    return _availableMachineIds.contains(numericId);
  }

  /// Check if a machine is connected via BLE
  bool isMachineConnected(String machineId) {
    final numericId = machineId.replaceAll(RegExp(r'[^0-9]'), '');
    return _connectedMachines[numericId] == true;
  }

  /// Initialize the service (permissions must be requested separately)
  void _initialize() {
    _updateStatus(BluetoothStatus.offline);
  }

  /// Request Bluetooth and Location permissions
  Future<bool> requestPermissions() async {
    try {
      print('📍 BluetoothService: Requesting permissions...');

      // Request multiple permissions at once
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      // Check if all permissions are granted
      bool allGranted = statuses.values.every((status) => status.isGranted);

      _permissionsGranted = allGranted;

      if (allGranted) {
        print('✅ BluetoothService: All permissions granted');
      } else {
        print('❌ BluetoothService: Some permissions denied');
        statuses.forEach((permission, status) {
          print('   ${permission.toString()}: ${status.toString()}');
        });
      }

      return allGranted;
    } catch (e) {
      print('❌ BluetoothService: Error requesting permissions: $e');
      _permissionsGranted = false;
      return false;
    }
  }

  /// Check if permissions are already granted
  Future<bool> checkPermissions() async {
    try {
      final bluetoothScan = await Permission.bluetoothScan.status;
      final bluetoothConnect = await Permission.bluetoothConnect.status;
      final location = await Permission.location.status;

      _permissionsGranted =
          bluetoothScan.isGranted &&
          bluetoothConnect.isGranted &&
          location.isGranted;

      return _permissionsGranted;
    } catch (e) {
      print('❌ BluetoothService: Error checking permissions: $e');
      _permissionsGranted = false;
      return false;
    }
  }

  /// Start scanning for Lactosure-BLE devices (background scan)
  Future<void> startScan() async {
    if (_isScanning) return;

    // Check permissions before scanning
    if (!_permissionsGranted) {
      final hasPermissions = await checkPermissions();
      if (!hasPermissions) {
        print('🔴 [BLE] Permissions not granted, skipping scan');
        return;
      }
    }

    try {
      _isScanning = true;
      _updateStatus(BluetoothStatus.scanning);
      _lactosureDevices.clear();
      _devicesController.add([]);

      print('🔵 [BLE] Starting background scan...');

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
      print('🔴 [BLE] Scan error: $e');
      _handleScanError(e);
    }
  }

  /// Extract serial number from BLE device name
  /// e.g., "Lactosure - Sl.No - 201" -> "201"
  String? _extractSerialNumber(String deviceName) {
    if (deviceName.startsWith(deviceNamePrefix)) {
      final serialPart = deviceName.substring(deviceNamePrefix.length).trim();
      // Return only numeric part
      final numericSerial = serialPart.replaceAll(RegExp(r'[^0-9]'), '');
      return numericSerial.isNotEmpty ? numericSerial : null;
    }
    return null;
  }

  /// Handle incoming scan results - Background scan, log to debug console only
  void _handleScanResults(List<ScanResult> results) {
    bool devicesUpdated = false;
    bool machineIdsUpdated = false;

    for (var result in results) {
      final device = result.device;
      final deviceName = device.platformName;
      final rssi = result.rssi;

      // Filter for Lactosure devices only (matching "Lactosure - Sl.No - XXX" pattern)
      if (deviceName.startsWith(deviceNamePrefix)) {
        // Check if device already exists
        final exists = _lactosureDevices.any(
          (d) => d.remoteId == device.remoteId,
        );

        if (!exists) {
          _lactosureDevices.add(device);
          devicesUpdated = true;

          // Extract serial number and add to available machine IDs
          final serialNumber = _extractSerialNumber(deviceName);
          if (serialNumber != null) {
            // Store device-to-serial mapping
            _machineDeviceMap[serialNumber] = device;

            if (!_availableMachineIds.contains(serialNumber)) {
              _availableMachineIds.add(serialNumber);
              machineIdsUpdated = true;
              print(
                '🟢 [BLE] Machine Available: Serial $serialNumber from "$deviceName"',
              );
            }
          }

          // Log to debug console
          print('🔵 [BLE] Found: $deviceName (${device.remoteId}) RSSI: $rssi');
        }
      }
    }

    if (devicesUpdated) {
      _devicesController.add(List.from(_lactosureDevices));

      // Log device count
      print('🔵 [BLE] Total Lactosure devices: ${_lactosureDevices.length}');

      // Update status to available when devices are found
      if (_lactosureDevices.isNotEmpty && _status == BluetoothStatus.scanning) {
        _updateStatus(BluetoothStatus.available);
      }
    }

    if (machineIdsUpdated) {
      _availableMachineIdsController.add(Set.from(_availableMachineIds));
      print('🟢 [BLE] Available Machine IDs: $_availableMachineIds');
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
      print(
        '🔵 [BLE] Scan stopped. Found ${_lactosureDevices.length} device(s)',
      );
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

  /// Connect to a machine by machine ID (e.g., "M201")
  Future<bool> connectToMachine(String machineId) async {
    final numericId = machineId.replaceAll(RegExp(r'[^0-9]'), '');
    final device = _machineDeviceMap[numericId];

    if (device == null) {
      print('❌ [BLE] No device found for machine $machineId');
      return false;
    }

    // Check if already connected
    if (_connectedMachines[numericId] == true) {
      print('⚡ [BLE] Machine $machineId already connected');
      return true;
    }

    try {
      print('🔵 [BLE] Connecting to $machineId (${device.platformName})...');

      // Stop scanning before connecting for stability
      final wasScanning = _isScanning;
      if (wasScanning) {
        await stopScan();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Connect to the device
      // License.free is for individuals, nonprofits, educational institutions, and small organizations (<15 employees)
      await device.connect(
        timeout: const Duration(seconds: 15),
        license: License.free,
        autoConnect: false,
      );

      // Mark as connected
      _connectedMachines[numericId] = true;
      _connectedDevice = device;
      _connectedMachinesController.add(Map.from(_connectedMachines));
      _connectedDeviceController.add(_connectedDevice);
      _updateStatus(BluetoothStatus.connected);

      // Stop auto-scanning when connected
      _autoScanTimer?.cancel();

      print('✅ [BLE] Connected to $machineId');
      return true;
    } catch (e) {
      print('❌ [BLE] Connection failed for $machineId: $e');
      _connectedMachines.remove(numericId);
      _connectedMachinesController.add(Map.from(_connectedMachines));

      // Try to clean up failed connection
      try {
        await device.disconnect();
      } catch (_) {}

      return false;
    }
  }

  /// Disconnect from a machine by machine ID
  Future<void> disconnectFromMachine(String machineId) async {
    final numericId = machineId.replaceAll(RegExp(r'[^0-9]'), '');
    final device = _machineDeviceMap[numericId];

    if (device == null) {
      print('❌ [BLE] No device found for machine $machineId');
      return;
    }

    try {
      print('🔵 [BLE] Disconnecting from $machineId...');
      await device.disconnect();

      // Mark as disconnected
      _connectedMachines.remove(numericId);
      _connectedMachinesController.add(Map.from(_connectedMachines));

      // If no more connected machines, update status
      if (_connectedMachines.isEmpty) {
        _connectedDevice = null;
        _connectedDeviceController.add(null);
        _updateStatus(BluetoothStatus.available);

        // Resume auto-scanning
        if (_autoScanEnabled) {
          _scheduleNextScan();
        }
      }

      print('✅ [BLE] Disconnected from $machineId');
    } catch (e) {
      print('❌ [BLE] Disconnect failed for $machineId: $e');
      // Still mark as disconnected locally
      _connectedMachines.remove(numericId);
      _connectedMachinesController.add(Map.from(_connectedMachines));
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

  /// Connect to all available machines
  Future<Map<String, bool>> connectAll() async {
    final results = <String, bool>{};

    if (_machineDeviceMap.isEmpty) {
      print('⚠️ [BLE] No devices available to connect');
      return results;
    }

    print('🔵 [BLE] Connecting to all ${_machineDeviceMap.length} devices...');

    // Stop scanning before connecting (important for BLE stability)
    _autoScanTimer?.cancel();
    await stopScan();

    // Small delay after stopping scan
    await Future.delayed(const Duration(milliseconds: 500));

    for (final entry in _machineDeviceMap.entries) {
      final serialNumber = entry.key;
      final device = entry.value;

      if (_connectedMachines[serialNumber] == true) {
        print('⚡ [BLE] Device $serialNumber already connected');
        results[serialNumber] = true;
        continue;
      }

      try {
        print('🔵 [BLE] Connecting to ${device.platformName}...');
        await device.connect(
          timeout: const Duration(seconds: 15),
          license: License.free,
          autoConnect: false,
        );

        _connectedMachines[serialNumber] = true;
        results[serialNumber] = true;

        // Update stream immediately after each connection
        _connectedMachinesController.add(Map.from(_connectedMachines));

        print('✅ [BLE] Connected to $serialNumber');

        // Small delay between connections for BLE stability
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        print('❌ [BLE] Failed to connect to $serialNumber: $e');
        results[serialNumber] = false;

        // Try to clean up failed connection
        try {
          await device.disconnect();
        } catch (_) {}

        // Small delay before trying next device
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    // Update status if any connected
    if (_connectedMachines.isNotEmpty) {
      _updateStatus(BluetoothStatus.connected);
    }

    print(
      '✅ [BLE] Connect all completed: ${results.values.where((v) => v).length}/${results.length} successful',
    );
    return results;
  }

  /// Disconnect from all connected machines
  Future<void> disconnectAll() async {
    if (_connectedMachines.isEmpty) {
      print('⚠️ [BLE] No devices connected');
      return;
    }

    print(
      '🔵 [BLE] Disconnecting from all ${_connectedMachines.length} devices...',
    );

    final connectedSerials = _connectedMachines.keys.toList();

    for (final serialNumber in connectedSerials) {
      final device = _machineDeviceMap[serialNumber];

      if (device != null) {
        try {
          print('🔵 [BLE] Disconnecting from $serialNumber...');
          await device.disconnect();
          print('✅ [BLE] Disconnected from $serialNumber');
        } catch (e) {
          print('❌ [BLE] Disconnect error for $serialNumber: $e');
        }
      }

      _connectedMachines.remove(serialNumber);
    }

    // Update streams
    _connectedMachinesController.add(Map.from(_connectedMachines));
    _connectedDevice = null;
    _connectedDeviceController.add(null);

    // Update status
    if (_lactosureDevices.isNotEmpty) {
      _updateStatus(BluetoothStatus.available);
    } else {
      _updateStatus(BluetoothStatus.offline);
    }

    // Resume auto-scanning
    if (_autoScanEnabled) {
      _scheduleNextScan();
    }

    print('✅ [BLE] Disconnect all completed');
  }

  /// Clear all devices and available machine IDs
  void clearDevices() {
    _lactosureDevices.clear();
    _availableMachineIds.clear();
    _devicesController.add([]);
    _availableMachineIdsController.add({});
    if (_status != BluetoothStatus.scanning &&
        _status != BluetoothStatus.connected) {
      _updateStatus(BluetoothStatus.offline);
    }
  }

  /// Load auto-connect preference from SharedPreferences
  Future<void> loadAutoConnectPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoConnectEnabled = prefs.getBool(_autoConnectKey) ?? false;
      print('🔵 [BLE] Auto-connect loaded: $_autoConnectEnabled');
    } catch (e) {
      print('❌ [BLE] Error loading auto-connect preference: $e');
      _autoConnectEnabled = false;
    }
  }

  /// Set auto-connect preference and save to SharedPreferences
  Future<void> setAutoConnect(bool enabled) async {
    _autoConnectEnabled = enabled;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoConnectKey, enabled);
      print('🔵 [BLE] Auto-connect saved: $enabled');

      // If enabled, trigger auto-connect flow
      if (enabled) {
        await triggerAutoConnect();
      }
    } catch (e) {
      print('❌ [BLE] Error saving auto-connect preference: $e');
    }
  }

  /// Trigger auto-connect flow: scan for devices and connect to all available
  Future<void> triggerAutoConnect() async {
    if (!_autoConnectEnabled) {
      print('⚠️ [BLE] Auto-connect is disabled, skipping');
      return;
    }

    print('🔵 [BLE] Triggering auto-connect...');

    // Check permissions first
    if (!_permissionsGranted) {
      final hasPermissions = await checkPermissions();
      if (!hasPermissions) {
        print('❌ [BLE] Permissions not granted, cannot auto-connect');
        return;
      }
    }

    // Start a scan and wait for it to complete
    await startScan();

    // Wait for scan to finish (scan duration + buffer)
    await Future.delayed(scanDuration + const Duration(seconds: 1));

    // If devices found, connect to all
    if (_lactosureDevices.isNotEmpty) {
      print(
        '🔵 [BLE] Auto-connecting to ${_lactosureDevices.length} devices...',
      );
      await connectAll();
      print('✅ [BLE] Auto-connect completed');
    } else {
      print('⚠️ [BLE] No devices found for auto-connect');
    }
  }

  /// Dispose service and clean up resources
  void dispose() {
    _autoScanTimer?.cancel();
    _scanSubscription?.cancel();
    _devicesController.close();
    _statusController.close();
    _connectedDeviceController.close();
    _availableMachineIdsController.close();
    _connectedMachinesController.close();
  }
}
