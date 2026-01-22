import 'dart:async';
import 'dart:math' as dart_math;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lactosure_reading.dart';

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
  final StreamController<LactosureReading> _readingsController =
      StreamController.broadcast();
  final StreamController<String> _rawDataController =
      StreamController.broadcast(); // Broadcasts ANY incoming BLE data
  final StreamController<Map<String, double>> _rssiDistanceController =
      StreamController.broadcast(); // Broadcasts RSSI-based distance for each machine

  // Global readings storage - stores latest reading for each machine
  final Map<String, LactosureReading> _machineReadings = {};
  // History of readings per machine (for graphs)
  final Map<String, List<LactosureReading>> _machineReadingHistory = {};
  static const int _maxHistoryPoints = 20;

  // RSSI and distance storage
  final Map<String, int> _machineRssi =
      {}; // Stores latest RSSI for each machine
  final Map<String, double> _machineDistance =
      {}; // Stores calculated distance for each machine
  Timer? _rssiMonitorTimer;

  // BLE data subscriptions
  final List<StreamSubscription> _dataSubscriptions = [];

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
  final Map<String, StreamSubscription<BluetoothConnectionState>> _connectionStateSubscriptions =
      {}; // Monitor connection state for each device
  BluetoothStatus _status = BluetoothStatus.offline;
  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  bool _autoScanEnabled = true;
  bool _permissionsGranted = false;
  bool _autoConnectEnabled = false; // Auto-connect toggle state
  bool _hasCompletedInitialScan = false; // Track if initial scan has completed

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
  Stream<LactosureReading> get readingsStream => _readingsController.stream;
  Stream<String> get rawDataStream => _rawDataController.stream;
  Stream<Map<String, double>> get rssiDistanceStream =>
      _rssiDistanceController.stream;

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

  // Readings getters
  Map<String, LactosureReading> get machineReadings =>
      Map.unmodifiable(_machineReadings);
  Map<String, int> get machineRssi => Map.unmodifiable(_machineRssi);
  Map<String, double> get machineDistance => Map.unmodifiable(_machineDistance);
  Map<String, List<LactosureReading>> get machineReadingHistory =>
      Map.unmodifiable(_machineReadingHistory);

  /// Get reading for a specific machine (normalized ID lookup)
  LactosureReading? getReadingForMachine(String machineId) {
    final normalizedId = machineId.replaceFirst(RegExp(r'^0+'), '');

    // Try exact match first
    if (_machineReadings.containsKey(machineId)) {
      return _machineReadings[machineId];
    }

    // Try normalized match
    for (final entry in _machineReadings.entries) {
      final normalizedKey = entry.key.replaceFirst(RegExp(r'^0+'), '');
      if (normalizedKey == normalizedId) {
        return entry.value;
      }
    }

    // No data for this machine
    return null;
  }

  /// Get history for a specific machine
  List<LactosureReading> getHistoryForMachine(String machineId) {
    final normalizedId = machineId.replaceFirst(RegExp(r'^0+'), '');

    // Try exact match first
    if (_machineReadingHistory.containsKey(machineId)) {
      return List.unmodifiable(_machineReadingHistory[machineId]!);
    }

    // Try normalized match
    for (final entry in _machineReadingHistory.entries) {
      final normalizedKey = entry.key.replaceFirst(RegExp(r'^0+'), '');
      if (normalizedKey == normalizedId) {
        return List.unmodifiable(entry.value);
      }
    }

    // No history for this machine
    return [];
  }

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

  /// Calculate distance from RSSI value
  /// Returns distance in meters using path loss formula
  /// Formula: distance = 10 ^ ((measuredPower - RSSI) / (10 * pathLossExponent))
  /// measuredPower: RSSI at 1 meter (typically -59 to -69)
  /// pathLossExponent: 2.0 for free space, 3-4 for indoor environments
  double _calculateDistance(int rssi) {
    const double measuredPower = -59.0; // RSSI at 1 meter
    const double pathLossExponent = 2.5; // Indoor environment

    if (rssi == 0) return -1.0; // Unknown distance

    final double ratio = (measuredPower - rssi) / (10 * pathLossExponent);
    final double distance = dart_math.pow(10, ratio).toDouble();

    return distance;
  }

  /// Get distance for a specific machine
  double? getMachineDistance(String machineId) {
    final numericId = machineId.replaceAll(RegExp(r'[^0-9]'), '');
    return _machineDistance[numericId];
  }

  /// Get RSSI for a specific machine
  int? getMachineRssi(String machineId) {
    final numericId = machineId.replaceAll(RegExp(r'[^0-9]'), '');
    return _machineRssi[numericId];
  }

  /// Start RSSI monitoring for connected devices
  void _startRssiMonitoring() {
    _rssiMonitorTimer?.cancel();

    _rssiMonitorTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      for (final entry in _machineDeviceMap.entries) {
        final machineId = entry.key;
        final device = entry.value;

        // Only monitor connected devices
        if (_connectedMachines[machineId] != true) continue;

        try {
          // Read RSSI from connected device
          final rssi = await device.readRssi();
          _machineRssi[machineId] = rssi;

          // Calculate distance
          final distance = _calculateDistance(rssi);
          _machineDistance[machineId] = distance;

          print(
            '📡 [BLE $machineId] RSSI: $rssi dBm, Distance: ${distance.toStringAsFixed(2)}m',
          );
        } catch (e) {
          print('⚠️ [BLE $machineId] Failed to read RSSI: $e');
        }
      }

      // Broadcast updated distances
      if (_machineDistance.isNotEmpty) {
        _rssiDistanceController.add(Map.from(_machineDistance));
      }
    });
  }

  /// Stop RSSI monitoring
  void _stopRssiMonitoring() {
    _rssiMonitorTimer?.cancel();
    _rssiMonitorTimer = null;
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

  /// Check if Bluetooth adapter is turned on
  Future<bool> isBluetoothEnabled() async {
    try {
      // Check if platform supports Bluetooth
      if (await FlutterBluePlus.isSupported == false) {
        print('❌ BluetoothService: Bluetooth not supported on this device');
        return false;
      }

      // Get current adapter state
      final adapterState = await FlutterBluePlus.adapterState.first;
      final isEnabled = adapterState == BluetoothAdapterState.on;

      print('🔵 BluetoothService: Adapter state = $adapterState');
      print('🔵 BluetoothService: Bluetooth enabled = $isEnabled');

      return isEnabled;
    } catch (e) {
      print('❌ BluetoothService: Error checking Bluetooth state: $e');
      return false;
    }
  }

  /// Listen to Bluetooth adapter state changes
  Stream<bool> get bluetoothStateStream {
    return FlutterBluePlus.adapterState.map(
      (state) => state == BluetoothAdapterState.on,
    );
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
        // Only schedule next scan if initial scan hasn't completed yet
        if (!_hasCompletedInitialScan) {
          _hasCompletedInitialScan = true;
          print('✅ [BLE] Initial scan completed. Auto-scan disabled - use manual scan from now on.');
        }
        // Don't schedule auto-scan after first scan
        // _scheduleNextScan(); // Removed - only manual scans after initial
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

              // Auto-connect immediately when device found
              _connectToDeviceImmediately(device, serialNumber);
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

    // Clean up devices that are no longer visible and not connected
    _cleanupStaleDevices();

    // Update status based on devices found
    if (_lactosureDevices.isEmpty) {
      _updateStatus(BluetoothStatus.offline);
    } else {
      _updateStatus(BluetoothStatus.available);
    }
  }

  /// Clean up devices that are no longer visible during scanning
  /// Only removes devices that are NOT currently connected
  void _cleanupStaleDevices() {
    final currentScanDeviceIds = _lactosureDevices
        .map((d) => d.remoteId.toString())
        .toSet();

    // Check each available machine ID
    final staleIds = <String>[];
    for (final machineId in _availableMachineIds) {
      // Skip if currently connected - don't remove connected devices
      if (_connectedMachines[machineId] == true) {
        continue;
      }

      // Check if the device is still in the current scan results
      final device = _machineDeviceMap[machineId];
      if (device != null && !currentScanDeviceIds.contains(device.remoteId.toString())) {
        // Device not seen in recent scan and not connected - mark as stale
        staleIds.add(machineId);
      }
    }

    // Remove stale devices
    if (staleIds.isNotEmpty) {
      print('🧹 [BLE] Removing ${staleIds.length} stale devices: $staleIds');
      for (final id in staleIds) {
        _availableMachineIds.remove(id);
        _machineDeviceMap.remove(id);
      }
      _availableMachineIdsController.add(Set.from(_availableMachineIds));
      
      // Also clean up the lactosure devices list
      _lactosureDevices.removeWhere((d) {
        final serial = _extractSerialNumber(d.platformName);
        return serial != null && staleIds.contains(serial);
      });
      _devicesController.add(List.from(_lactosureDevices));
    }
  }

  /// Schedule next auto-scan
  void _scheduleNextScan() {
    // Don't auto-scan if initial scan has completed
    if (!_autoScanEnabled || _hasCompletedInitialScan) return;

    _autoScanTimer?.cancel();
    _autoScanTimer = Timer(autoScanInterval, () {
      if (_autoScanEnabled && _status != BluetoothStatus.connected && !_hasCompletedInitialScan) {
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

      // Monitor connection state for automatic disconnection detection
      _startConnectionStateMonitoring(numericId, device);

      // Start data listener for this device
      _startListenerForSingleDevice(numericId, device);

      // Start RSSI monitoring if this is the first connection
      if (_connectedMachines.length == 1) {
        _startRssiMonitoring();
      }

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

      // Stop monitoring connection state
      await _connectionStateSubscriptions[numericId]?.cancel();
      _connectionStateSubscriptions.remove(numericId);

      // Mark as disconnected
      _connectedMachines.remove(numericId);
      _machineRssi.remove(numericId);
      _machineDistance.remove(numericId);
      _connectedMachinesController.add(Map.from(_connectedMachines));

      // Remove from available list since we lost connection
      _availableMachineIds.remove(numericId);
      _availableMachineIdsController.add(Set.from(_availableMachineIds));

      // If no more connected machines, update status
      if (_connectedMachines.isEmpty) {
        _connectedDevice = null;
        _connectedDeviceController.add(null);
        _updateStatus(BluetoothStatus.available);

        // Stop RSSI monitoring
        _stopRssiMonitoring();

        // Don't resume auto-scanning after disconnect
        // User must scan manually
        // if (_autoScanEnabled) {
        //   _scheduleNextScan();
        // }
      }

      print('✅ [BLE] Disconnected from $machineId');
    } catch (e) {
      print('❌ [BLE] Disconnect failed for $machineId: $e');
      // Still mark as disconnected locally
      _connectedMachines.remove(numericId);
      _connectedMachinesController.add(Map.from(_connectedMachines));
    }
  }

  /// Connect to a device immediately when found
  Future<void> _connectToDeviceImmediately(
    BluetoothDevice device,
    String serialNumber,
  ) async {
    // Avoid reconnecting if already connected
    if (_connectedMachines.containsKey(serialNumber)) {
      print('ℹ️ [BLE] Machine $serialNumber already connected, skipping');
      return;
    }

    print('⚡ [BLE] Auto-connecting to machine $serialNumber immediately...');

    // Connect in background without blocking scan
    Future.delayed(Duration.zero, () async {
      await connectToMachine('m$serialNumber');
    });
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

      // Don't resume auto-scanning after disconnect
      // User must scan manually
      // if (_autoScanEnabled) {
      //   _scheduleNextScan();
      // }
    }
  }

  /// Enable/disable auto-scan
  void setAutoScan(bool enabled) {
    _autoScanEnabled = enabled;
    // Only start scan if initial scan hasn't completed
    if (enabled && !_isScanning && _status != BluetoothStatus.connected && !_hasCompletedInitialScan) {
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

      // AUTO-START listening to all connected devices for data
      _startGlobalDataListener();

      // Start RSSI monitoring for distance calculation
      _startRssiMonitoring();
    }

    print(
      '✅ [BLE] Connect all completed: ${results.values.where((v) => v).length}/${results.length} successful',
    );
    return results;
  }

  /// Start listening to all connected devices and store readings globally
  void _startGlobalDataListener() async {
    print('\n═══════════════════════════════════════════════════════════════');
    print('🔵 [BLE] AUTO-STARTING global data listener for ALL devices');
    print('═══════════════════════════════════════════════════════════════\n');

    // Cancel existing subscriptions
    for (final sub in _dataSubscriptions) {
      await sub.cancel();
    }
    _dataSubscriptions.clear();

    for (final entry in _machineDeviceMap.entries) {
      final machineId = entry.key;
      final device = entry.value;

      // Only listen to connected devices
      if (_connectedMachines[machineId] != true) continue;

      await _setupDeviceListener(machineId, device);
    }

    print('✅ [BLE] Global data listener setup complete\n');
  }

  /// Start listener for a single device after individual connection
  Future<void> _startListenerForSingleDevice(
    String machineId,
    BluetoothDevice device,
  ) async {
    print('🔵 [BLE $machineId] Starting data listener after connection...');
    await _setupDeviceListener(machineId, device);
  }

  /// Setup listener for a specific device
  Future<void> _setupDeviceListener(
    String machineId,
    BluetoothDevice device,
  ) async {
    try {
      print('🔵 [BLE $machineId] Setting up listener...');
      final services = await device.discoverServices();

      for (final service in services) {
        for (final char in service.characteristics) {
          if (char.properties.notify) {
            await char.setNotifyValue(true);
            print('✅ [BLE $machineId] Listening on ${char.uuid}');

            final sub = char.lastValueStream.listen((value) {
              if (value.isNotEmpty) {
                final rawData = String.fromCharCodes(value);
                _processIncomingData(rawData, machineId);
              }
            });
            _dataSubscriptions.add(sub);
          }
        }
      }
      print('✅ [BLE $machineId] Listener active');
    } catch (e) {
      print('❌ [BLE $machineId] Error setting up listener: $e');
    }
  }

  /// Process incoming BLE data and store globally
  void _processIncomingData(String rawData, String deviceMachineId) {
    print('\n╔══════════════════════════════════════════════════════════════╗');
    print('║        📥 BLE DATA RECEIVED (Global Listener)               ║');
    print('╠══════════════════════════════════════════════════════════════╣');
    print('║ Device Machine ID: $deviceMachineId');
    print(
      '║ Data: ${rawData.substring(0, rawData.length > 50 ? 50 : rawData.length)}...',
    );
    print('╚══════════════════════════════════════════════════════════════╝\n');

    // Broadcast raw data immediately (for timer stopping etc.)
    _rawDataController.add(rawData);

    final reading = LactosureReading.parse(rawData);

    if (reading != null) {
      // Extract machine ID from data (remove M prefix and leading zeros)
      final readingMachineId = reading.machineId
          .replaceFirst(RegExp(r'^[Mm]+'), '')
          .replaceFirst(RegExp(r'^0+'), '');

      final storageKey = readingMachineId.isNotEmpty
          ? readingMachineId
          : deviceMachineId;

      // Store reading
      _machineReadings[storageKey] = reading;

      // Add to history
      _machineReadingHistory.putIfAbsent(storageKey, () => []);
      _machineReadingHistory[storageKey]!.add(reading);
      if (_machineReadingHistory[storageKey]!.length > _maxHistoryPoints) {
        _machineReadingHistory[storageKey]!.removeAt(0);
      }

      // Broadcast to all listeners
      _readingsController.add(reading);

      print('✅ [BLE Global] Stored reading for machine: $storageKey');
      print(
        '📊 [BLE Global] Total readings stored: ${_machineReadings.length} machines',
      );
    }
  }

  // Nordic UART Service UUIDs
  static const String _nordicUartServiceUuid =
      '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const String _nordicUartRxUuid =
      '6e400002-b5a3-f393-e0a9-e50e24dcca9e'; // Write to this
  // Unused - keeping for reference
  // static const String _nordicUartTxUuid =
  //     '6e400003-b5a3-f393-e0a9-e50e24dcca9e'; // Read from this

  /// Send data (bytes) to a specific machine via BLE
  /// Returns true if successful, false otherwise
  Future<bool> sendToMachine(String machineId, List<int> data) async {
    final normalizedId = machineId.replaceAll(RegExp(r'[^0-9]'), '');
    final device = _machineDeviceMap[normalizedId];

    if (device == null) {
      print('❌ [BLE] Machine $machineId not found in device map');
      return false;
    }

    if (_connectedMachines[normalizedId] != true) {
      print('❌ [BLE] Machine $machineId is not connected');
      return false;
    }

    try {
      print(
        '\n╔══════════════════════════════════════════════════════════════╗',
      );
      print('║        📤 SENDING BLE DATA TO MACHINE                        ║');
      print('╠══════════════════════════════════════════════════════════════╣');
      print('║ Machine ID: $normalizedId');
      print(
        '║ Data (hex): ${data.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}',
      );
      print('║ Data (bytes): $data');
      print(
        '╚══════════════════════════════════════════════════════════════╝\n',
      );

      // Discover services if needed
      final services = await device.discoverServices();

      // Find Nordic UART Service
      BluetoothCharacteristic? rxCharacteristic;

      for (final service in services) {
        if (service.uuid.toString().toLowerCase() == _nordicUartServiceUuid) {
          for (final char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() == _nordicUartRxUuid) {
              rxCharacteristic = char;
              break;
            }
          }
        }
      }

      if (rxCharacteristic == null) {
        print('❌ [BLE] RX characteristic not found on machine $normalizedId');
        return false;
      }

      // Write data to RX characteristic
      await rxCharacteristic.write(data, withoutResponse: false);

      print('✅ [BLE] Data sent successfully to machine $normalizedId');
      return true;
    } catch (e) {
      print('❌ [BLE] Error sending data to machine $normalizedId: $e');
      return false;
    }
  }

  /// Send hex string to machine (convenience method)
  /// Example: sendHexToMachine("201", "40 04 07 00 00 41")
  Future<bool> sendHexToMachine(String machineId, String hexString) async {
    final bytes = hexString
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => int.parse(s, radix: 16))
        .toList();
    return sendToMachine(machineId, bytes);
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

    // Stop all connection state monitoring subscriptions
    for (final subscription in _connectionStateSubscriptions.values) {
      await subscription.cancel();
    }
    _connectionStateSubscriptions.clear();
    print('🔵 [BLE] Stopped all connection state monitors');

    // Stop all data listeners
    for (final sub in _dataSubscriptions) {
      await sub.cancel();
    }
    _dataSubscriptions.clear();
    print('🔵 [BLE] Stopped all data listeners');

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
      _availableMachineIds.remove(serialNumber);
    }

    // Update streams
    _connectedMachinesController.add(Map.from(_connectedMachines));
    _availableMachineIdsController.add(Set.from(_availableMachineIds));
    _connectedDevice = null;
    _connectedDeviceController.add(null);

    // Update status
    if (_lactosureDevices.isNotEmpty) {
      _updateStatus(BluetoothStatus.available);
    } else {
      _updateStatus(BluetoothStatus.offline);
    }

    // Don't resume auto-scanning after disconnect all
    // User must scan manually
    // if (_autoScanEnabled) {
    //   _scheduleNextScan();
    // }

    print('✅ [BLE] Disconnect all completed');
  }

  /// Clear all readings
  void clearReadings() {
    _machineReadings.clear();
    _machineReadingHistory.clear();
    print('🧹 [BLE] All readings cleared');
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

  /// Get BLE data stream from ALL connected machines (for debugging)
  /// Returns a stream of raw data strings from ALL devices
  Stream<String> getAllMachineDataStream() async* {
    print('═══════════════════════════════════════════════════════════════');
    print('🔵 [BLE DEBUG] Starting to listen to ALL connected devices');
    print(
      '🔵 [BLE DEBUG] Total connected machines: ${_machineDeviceMap.length}',
    );
    print('🔵 [BLE DEBUG] Machine IDs: ${_machineDeviceMap.keys.toList()}');
    print('═══════════════════════════════════════════════════════════════');

    if (_machineDeviceMap.isEmpty) {
      print('❌ [BLE DEBUG] No devices connected!');
      return;
    }

    // Setup listeners for all connected devices
    for (var entry in _machineDeviceMap.entries) {
      final machineId = entry.key;
      final device = entry.value;

      print(
        '\n┌─────────────────────────────────────────────────────────────┐',
      );
      print('│ Setting up listener for Machine: $machineId');
      print('└─────────────────────────────────────────────────────────────┘');

      try {
        print('  🔵 [BLE $machineId] Discovering services...');
        final services = await device.discoverServices();
        print('  ✅ [BLE $machineId] Found ${services.length} services');

        for (var service in services) {
          print('  🔵 [BLE $machineId] Service: ${service.uuid}');

          for (var char in service.characteristics) {
            print('    📡 [BLE $machineId] Characteristic: ${char.uuid}');
            print('       - Notify: ${char.properties.notify}');
            print('       - Read: ${char.properties.read}');
            print('       - Write: ${char.properties.write}');

            // Listen to ALL characteristics that support notify
            if (char.properties.notify) {
              print(
                '    ✅ [BLE $machineId] Found NOTIFY characteristic: ${char.uuid}',
              );

              try {
                await char.setNotifyValue(true);
                print(
                  '    ✅ [BLE $machineId] Enabled notifications on ${char.uuid}',
                );

                // Listen to this characteristic
                await for (final value in char.lastValueStream) {
                  if (value.isNotEmpty) {
                    final rawData = String.fromCharCodes(value);

                    print(
                      '\n╔════════════════════════════════════════════════════════════╗',
                    );
                    print(
                      '║            📥 BLE DATA RECEIVED FROM DEVICE                ║',
                    );
                    print(
                      '╠════════════════════════════════════════════════════════════╣',
                    );
                    print('║ Machine ID: $machineId');
                    print('║ Characteristic: ${char.uuid}');
                    print('║ Byte Length: ${value.length}');
                    print('║ Raw Bytes: $value');
                    print('║ String Data: $rawData');
                    print(
                      '╚════════════════════════════════════════════════════════════╝\n',
                    );

                    yield rawData;
                  } else {
                    print(
                      '    ⚠️ [BLE $machineId] Empty value received on ${char.uuid}',
                    );
                  }
                }
              } catch (e) {
                print('    ❌ [BLE $machineId] Error on ${char.uuid}: $e');
              }
            }
          }
        }
      } catch (e, stackTrace) {
        print('  ❌ [BLE $machineId] Error setting up listener: $e');
        print('  📍 Stack trace: $stackTrace');
      }
    }
  }

  /// Get BLE data stream from a connected machine
  /// Returns a stream of raw data strings from the TX characteristic
  Stream<String> getMachineDataStream(String machineId) async* {
    final numericId = machineId.replaceAll(RegExp(r'[^0-9]'), '');
    final device = _machineDeviceMap[numericId];

    if (device == null) {
      print('❌ [BLE] No device found for machine $machineId');
      return;
    }

    if (_connectedMachines[numericId] != true) {
      print('❌ [BLE] Machine $machineId not connected');
      return;
    }

    print('🔵 [BLE] Setting up data stream for machine $machineId...');

    try {
      // Discover services
      print('🔵 [BLE] Discovering services for $machineId...');
      final services = await device.discoverServices();
      print('✅ [BLE] Found ${services.length} services');

      // Find the Nordic UART service (6E400001-B5A3-F393-E0A9-E50E24DCCA9E)
      // TX Characteristic: 6E400003-B5A3-F393-E0A9-E50E24DCCA9E (Device -> App)
      final String txCharacteristicUuid =
          '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

      BluetoothCharacteristic? txCharacteristic;

      for (var service in services) {
        print('🔵 [BLE] Checking service: ${service.uuid}');
        for (var char in service.characteristics) {
          print('  📡 Characteristic: ${char.uuid}');
          if (char.uuid.toString().toLowerCase() == txCharacteristicUuid) {
            txCharacteristic = char;
            print('✅ [BLE] Found TX characteristic!');
            break;
          }
        }
        if (txCharacteristic != null) break;
      }

      if (txCharacteristic == null) {
        print('❌ [BLE] TX characteristic not found for $machineId');
        return;
      }

      // Enable notifications
      print('🔵 [BLE] Enabling notifications for TX characteristic...');
      await txCharacteristic.setNotifyValue(true);
      print('✅ [BLE] Notifications enabled!');

      // Listen to characteristic updates
      print('🔵 [BLE] Listening for data from $machineId...');
      await for (final value in txCharacteristic.lastValueStream) {
        if (value.isNotEmpty) {
          // Convert bytes to string
          final rawData = String.fromCharCodes(value);

          // Debug print - show what we received
          print('📥 [BLE DATA] Machine $machineId: $rawData');
          print('📥 [BLE RAW BYTES] Length: ${value.length}, Bytes: $value');

          yield rawData;
        }
      }
    } catch (e, stackTrace) {
      print('❌ [BLE] Error setting up data stream for $machineId: $e');
      print('📍 [BLE] Stack trace: $stackTrace');
    }
  }

  /// Start monitoring connection state for a device to detect automatic disconnections
  void _startConnectionStateMonitoring(String machineId, BluetoothDevice device) {
    // Cancel existing subscription if any
    _connectionStateSubscriptions[machineId]?.cancel();

    print('🔵 [BLE Monitor] Starting connection state monitoring for $machineId');

    // Listen to connection state changes
    _connectionStateSubscriptions[machineId] = device.connectionState.listen(
      (BluetoothConnectionState state) {
        print('🔵 [BLE Monitor] $machineId connection state: $state');

        if (state == BluetoothConnectionState.disconnected) {
          print('⚠️ [BLE Monitor] $machineId DISCONNECTED (signal lost or device powered off)');
          
          // Device disconnected automatically - clean up
          _handleAutomaticDisconnection(machineId, device);
        }
      },
      onError: (error) {
        print('❌ [BLE Monitor] Error monitoring $machineId: $error');
      },
    );
  }

  /// Handle automatic disconnection when signal is lost
  void _handleAutomaticDisconnection(String machineId, BluetoothDevice device) {
    print('🔴 [BLE] Handling automatic disconnection for $machineId');

    // Stop monitoring this device's connection state
    _connectionStateSubscriptions[machineId]?.cancel();
    _connectionStateSubscriptions.remove(machineId);

    // Mark as disconnected
    _connectedMachines.remove(machineId);
    _machineRssi.remove(machineId);
    _machineDistance.remove(machineId);

    // Remove from available devices list
    _availableMachineIds.remove(machineId);

    // Update streams to notify UI
    _connectedMachinesController.add(Map.from(_connectedMachines));
    _availableMachineIdsController.add(Set.from(_availableMachineIds));

    print('🔴 [BLE] $machineId marked as OFFLINE');
    print('🔴 [BLE] Remaining connected: ${_connectedMachines.keys.toList()}');
    print('🔴 [BLE] Remaining available: ${_availableMachineIds.toList()}');

    // If no more connected machines, update global status
    if (_connectedMachines.isEmpty) {
      _connectedDevice = null;
      _connectedDeviceController.add(null);
      
      // Update status based on remaining available devices
      if (_availableMachineIds.isNotEmpty) {
        _updateStatus(BluetoothStatus.available);
      } else {
        _updateStatus(BluetoothStatus.offline);
      }

      // Stop RSSI monitoring
      _stopRssiMonitoring();

      // Don't resume auto-scanning after disconnection
      // User must scan manually
      // if (_autoScanEnabled) {
      //   print('🔵 [BLE] Resuming auto-scan after disconnection');
      //   _scheduleNextScan();
      // }
    }
  }

  /// Dispose service and clean up resources
  void dispose() {
    _autoScanTimer?.cancel();
    _scanSubscription?.cancel();
    _rssiMonitorTimer?.cancel();
    
    // Cancel all connection state monitoring subscriptions
    for (final subscription in _connectionStateSubscriptions.values) {
      subscription.cancel();
    }
    _connectionStateSubscriptions.clear();
    
    // Cancel all data subscriptions
    // Cancel all data subscriptions
    for (final subscription in _dataSubscriptions) {
      subscription.cancel();
    }
    _dataSubscriptions.clear();
    
    _devicesController.close();
    _statusController.close();
    _connectedDeviceController.close();
    _availableMachineIdsController.close();
    _connectedMachinesController.close();
    _readingsController.close();
    _rawDataController.close();
    _rssiDistanceController.close();
  }
}
