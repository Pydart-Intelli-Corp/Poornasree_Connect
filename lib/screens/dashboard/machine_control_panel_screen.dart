import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../services/services.dart';
import '../../services/readings_storage_service.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';
import '../../models/lactosure_reading.dart';
import '../reports/reports_screen.dart';

class MachineControlPanelScreen extends StatefulWidget {
  final String? machineId;
  final String? machineName;
  final String? machineType;

  const MachineControlPanelScreen({
    super.key,
    this.machineId,
    this.machineName,
    this.machineType,
  });

  @override
  State<MachineControlPanelScreen> createState() =>
      _MachineControlPanelScreenState();
}

class _MachineControlPanelScreenState extends State<MachineControlPanelScreen>
    with TickerProviderStateMixin {
  final BluetoothService _bluetoothService = BluetoothService();

  // Store readings for ALL connected machines
  final Map<String, LactosureReading> _machineReadings = {};

  // History of readings for graph per machine (max 20 points each)
  final Map<String, List<LactosureReading>> _machineReadingHistory = {};
  static const int _maxHistoryPoints = 20;

  // Normalize machine ID (remove leading zeros for matching)
  String _normalizeId(String id) {
    return id.replaceFirst(RegExp(r'^0+'), '');
  }

  // Current display reading (based on selected machine and history index)
  LactosureReading get _currentReading {
    if (_currentMachineId == null) return _emptyReading;

    // If viewing history, get from history list
    if (_isViewingHistory && _readingHistory.isNotEmpty) {
      final historyList = _readingHistory;
      // _historyIndex 0 = latest (last item), 1 = second last, etc.
      final actualIndex = historyList.length - 1 - _historyIndex;
      if (actualIndex >= 0 && actualIndex < historyList.length) {
        return historyList[actualIndex];
      }
    }

    // Try exact match first
    if (_machineReadings.containsKey(_currentMachineId)) {
      return _machineReadings[_currentMachineId]!;
    }

    // Try normalized match (e.g., "201" matches stored "201", "00201" matches "201")
    final normalizedCurrent = _normalizeId(_currentMachineId!);
    for (final entry in _machineReadings.entries) {
      if (_normalizeId(entry.key) == normalizedCurrent) {
        return entry.value;
      }
    }

    // No data for this machine yet - return empty
    return _emptyReading;
  }

  // Current history for selected machine
  List<LactosureReading> get _readingHistory {
    if (_currentMachineId == null) return [];

    // Try exact match first
    if (_machineReadingHistory.containsKey(_currentMachineId)) {
      return _machineReadingHistory[_currentMachineId]!;
    }

    // Try normalized match
    final normalizedCurrent = _normalizeId(_currentMachineId!);
    for (final entry in _machineReadingHistory.entries) {
      if (_normalizeId(entry.key) == normalizedCurrent) {
        return entry.value;
      }
    }

    // No history for this machine yet - return empty
    return [];
  }

  // Empty reading template
  final LactosureReading _emptyReading = LactosureReading(
    milkType: '1',
    fat: 0.0,
    snf: 0.0,
    clr: 0.0,
    protein: 0.0,
    lactose: 0.0,
    salt: 0.0,
    water: 0.0,
    temperature: 0.0,
    farmerId: '000000',
    quantity: 0.0,
    totalAmount: 0.0,
    rate: 0.0,
    incentive: 0.0,
    machineId: '00000',
  );

  bool _isTestRunning = false;
  Timer? _testTimer;
  int _testElapsedSeconds = 0;
  bool _testAllMachines = true; // Default to test all machines
  Set<String> _selectedTestMachines = {}; // Selected machines for testing
  // Track machines that received data during current test
  Set<String> _machinesWithDataReceived = {};
  List<String> _currentTestMachines =
      []; // Machines being tested in current test
  // bool _isShowingResultSnackbar = false; // Prevent duplicate snackbars - Unused

  // Live test overlay
  OverlayEntry? _liveTestOverlay;
  final ValueNotifier<Set<String>> _receivedMachinesNotifier = ValueNotifier(
    {},
  );
  final ValueNotifier<bool> _testCompleteNotifier = ValueNotifier(false);

  // Machine navigation state
  int _currentMachineIndex = 0;
  List<String> _connectedMachineIds = [];
  String? _currentMachineId;
  // String? _currentMachineName; // Unused

  // BLE data subscription
  StreamSubscription? _bleDataSubscription;
  StreamSubscription? _rawDataSubscription;
  StreamSubscription<Map<String, double>>? _rssiSubscription;
  double? _currentMachineDistance;

  // Storage service
  final ReadingsStorageService _storageService = ReadingsStorageService();

  // Today's statistics (across all machines)
  int _todayTestCount = 0;
  Map<String, int> _machineTestCounts = {}; // Per-machine test counts
  LactosureReading? _bestReading;
  String? _bestMachineId;
  LactosureReading? _worstReading;
  String? _worstMachineId;

  // Additional statistics
  double _avgFat = 0.0;
  double _avgSnf = 0.0;
  double _totalQuantity = 0.0;
  double _totalAmount = 0.0;
  double _highestFat = 0.0;
  double _lowestFat = 0.0;
  double _highestSnf = 0.0;
  double _lowestSnf = 0.0;

  // History navigation
  bool _isViewingHistory = false;
  int _historyIndex = 0; // 0 = latest, 1 = previous, etc.

  // Weighing scale mode per machine (true = Auto, false = Manual)
  Map<String, bool> _machineWeighingScaleMode = {};

  // Farmer ID mode per machine (true = Auto, false = Manual) - Default: Manual
  Map<String, bool> _machineFarmerIdMode = {};

  // Farmer ID per machine
  Map<String, String> _machineFarmerIds = {};

  // Weight per machine
  Map<String, String> _machineWeights = {};

  // Selected channel filter (CH1=Cow, CH2=Buffalo, CH3=Mixed)
  String _selectedChannel = 'CH1';

  @override
  void initState() {
    super.initState();
    _initializeMachineList();
    _loadPreferences();
    _clearOldReadings(); // Clear readings from previous days
    _loadSavedReadings(); // Load today's saved readings from storage
    _loadExistingReadings(); // Load readings that were collected before opening this screen
    _setupBLEDataListener();
    _listenToRssiDistance(); // Listen to RSSI distance updates
    _calculateTodayStatistics(); // Calculate statistics from all machines
  }

  @override
  void dispose() {
    _bleDataSubscription?.cancel();
    _rawDataSubscription?.cancel();
    _rssiSubscription?.cancel();
    _testTimer?.cancel();
    _liveTestOverlay?.remove();
    _receivedMachinesNotifier.dispose();
    _testCompleteNotifier.dispose();
    super.dispose();
  }

  /// Listen to RSSI distance updates
  void _listenToRssiDistance() {
    _rssiSubscription = _bluetoothService.rssiDistanceStream.listen((
      distances,
    ) {
      if (_currentMachineId != null && mounted) {
        final numericId = _currentMachineId!.replaceAll(RegExp(r'[^0-9]'), '');
        if (distances.containsKey(numericId)) {
          setState(() {
            _currentMachineDistance = distances[numericId];
          });
        }
      }
    });
  }

  /// Calculate today's statistics across all machines
  void _calculateTodayStatistics() async {
    final allReadings = await _storageService.loadAllTodayReadings();

    int totalTests = 0;
    Map<String, int> machineCounts = {};
    LactosureReading? best;
    String? bestMachine;
    LactosureReading? worst;
    String? worstMachine;

    // Additional stats
    double sumFat = 0.0;
    double sumSnf = 0.0;
    double sumQuantity = 0.0;
    double sumAmount = 0.0;
    double maxFat = 0.0;
    double minFat = double.infinity;
    double maxSnf = 0.0;
    double minSnf = double.infinity;

    // Calculate quality score: higher FAT + SNF = better quality
    double calculateQuality(LactosureReading r) => r.fat + r.snf;

    for (final entry in allReadings.entries) {
      final machineId = entry.key;
      final readings = entry.value;
      totalTests += readings.length;
      machineCounts[machineId] = readings.length;

      for (final reading in readings) {
        final quality = calculateQuality(reading);

        // Sum for averages
        sumFat += reading.fat;
        sumSnf += reading.snf;
        sumQuantity += reading.quantity;
        sumAmount += reading.totalAmount;

        // Track min/max
        if (reading.fat > maxFat) maxFat = reading.fat;
        if (reading.fat < minFat && reading.fat > 0) minFat = reading.fat;
        if (reading.snf > maxSnf) maxSnf = reading.snf;
        if (reading.snf < minSnf && reading.snf > 0) minSnf = reading.snf;

        // Find best
        if (best == null || quality > calculateQuality(best)) {
          best = reading;
          bestMachine = machineId;
        }

        // Find worst
        if (worst == null || quality < calculateQuality(worst)) {
          worst = reading;
          worstMachine = machineId;
        }
      }
    }

    if (mounted) {
      setState(() {
        _todayTestCount = totalTests;
        _machineTestCounts = machineCounts;
        _bestReading = best;
        _bestMachineId = bestMachine;
        _worstReading = worst;
        _worstMachineId = worstMachine;

        // Calculate averages
        _avgFat = totalTests > 0 ? sumFat / totalTests : 0.0;
        _avgSnf = totalTests > 0 ? sumSnf / totalTests : 0.0;
        _totalQuantity = sumQuantity;
        _totalAmount = sumAmount;
        _highestFat = maxFat;
        _lowestFat = minFat == double.infinity ? 0.0 : minFat;
        _highestSnf = maxSnf;
        _lowestSnf = minSnf == double.infinity ? 0.0 : minSnf;
      });
    }

    print(
      '📊 [Stats] Today: $totalTests tests, Best: m$bestMachine, Worst: m$worstMachine',
    );
  }

  /// Clear old readings from previous days
  void _clearOldReadings() async {
    await _storageService.clearOldReadings();
  }

  /// Load today's saved readings from storage (only for trends, not current display)
  void _loadSavedReadings() async {
    print('\n═══════════════════════════════════════════════════════════════');
    print(
      '🔵 [Control Panel] Loading saved readings from storage (for trends only)',
    );
    print('═══════════════════════════════════════════════════════════════\n');

    final savedReadings = await _storageService.loadAllTodayReadings();

    if (savedReadings.isNotEmpty && mounted) {
      setState(() {
        for (final entry in savedReadings.entries) {
          final machineId = entry.key;
          final readings = entry.value;

          if (readings.isNotEmpty) {
            // Only set history for trends - DON'T set current reading
            // Current reading starts at 0 until new data arrives
            _machineReadingHistory[machineId] = readings;
          }
        }
      });
      print(
        '✅ [Control Panel] Loaded trend data for ${savedReadings.length} machines',
      );
    } else {
      print('ℹ️ [Control Panel] No saved readings found for today');
    }
  }

  /// Load existing readings from BluetoothService (only for trends, not current display)
  void _loadExistingReadings() {
    print('\n═══════════════════════════════════════════════════════════════');
    print(
      '🔵 [Control Panel] Loading existing readings from BluetoothService (for trends only)',
    );
    print('═══════════════════════════════════════════════════════════════\n');

    final existingHistory = _bluetoothService.machineReadingHistory;

    if (existingHistory.isNotEmpty) {
      setState(() {
        // Only load history for trends - DON'T set current readings
        for (final entry in existingHistory.entries) {
          _machineReadingHistory[entry.key] = List.from(entry.value);
        }
      });
      print(
        '✅ [Control Panel] Loaded trend history for ${existingHistory.length} machines',
      );
    } else {
      print('ℹ️ [Control Panel] No existing readings found');
    }
  }

  void _setupBLEDataListener() {
    print('\n═══════════════════════════════════════════════════════════════');
    print('🔵 [Control Panel] Setting up BLE listener (using global stream)');
    print('🔵 [Control Panel] ⚠️ NEW LISTENER CODE v2 - WITH TEST TRACKING ⚠️');
    print('🔵 [Control Panel] Current machine: $_currentMachineId');
    print('═══════════════════════════════════════════════════════════════\n');

    // Cancel existing subscription if any
    _bleDataSubscription?.cancel();

    try {
      // Listen to the global readings stream from BluetoothService
      _bleDataSubscription = _bluetoothService.readingsStream.listen(
        (reading) {
          print(
            '\n╔══════════════════════════════════════════════════════════════╗',
          );
          print(
            '║        📥 NEW READING FROM GLOBAL STREAM                     ║',
          );
          print(
            '╠══════════════════════════════════════════════════════════════╣',
          );
          print('║ Machine: ${reading.machineId}');
          print(
            '║ Fat: ${reading.fat} | SNF: ${reading.snf} | CLR: ${reading.clr}',
          );
          print(
            '╚══════════════════════════════════════════════════════════════╝\n',
          );

          // Extract machine ID from the reading
          final readingMachineId = reading.machineId
              .replaceFirst(RegExp(r'^[Mm]+'), '')
              .replaceFirst(RegExp(r'^0+'), '');

          final storageKey = readingMachineId.isNotEmpty
              ? readingMachineId
              : (_currentMachineId ?? 'unknown');

          // Save reading to storage (persists to phone storage)
          _storageService.saveReading(storageKey, reading);

          // Recalculate statistics with new data
          _calculateTodayStatistics();

          if (mounted) {
            setState(() {
              // Store locally for display
              _machineReadings[storageKey] = reading;

              // Add to history
              _machineReadingHistory.putIfAbsent(storageKey, () => []);
              _machineReadingHistory[storageKey]!.add(reading);
              if (_machineReadingHistory[storageKey]!.length >
                  _maxHistoryPoints) {
                _machineReadingHistory[storageKey]!.removeAt(0);
              }

              // Track machine that received data during test
              if (_isTestRunning && _currentTestMachines.isNotEmpty) {
                // Find matching machine in current test
                for (final testMachine in _currentTestMachines) {
                  final normalizedTest = _normalizeId(testMachine);
                  final normalizedStorage = _normalizeId(storageKey);
                  if (normalizedTest == normalizedStorage ||
                      testMachine == storageKey) {
                    final isFirstResponse = _machinesWithDataReceived.isEmpty;
                    _machinesWithDataReceived.add(testMachine);
                    // Update notifier for live overlay
                    _receivedMachinesNotifier.value = Set.from(
                      _machinesWithDataReceived,
                    );
                    print(
                      '✅ [Test] Machine $testMachine received data (${_machinesWithDataReceived.length}/${_currentTestMachines.length})',
                    );

                    // Show overlay on first response
                    if (isFirstResponse) {
                      CustomSnackbar.dismiss();
                      _showLiveTestOverlay();
                    }
                    break;
                  }
                }
              } else {
                // Not in test mode - show snackbar for data received
                _showDataReceivedSnackbar(storageKey, reading);
              }
            });

            // Check if ALL machines received data - mark complete
            if (_isTestRunning &&
                _machinesWithDataReceived.length >=
                    _currentTestMachines.length &&
                _currentTestMachines.isNotEmpty) {
              _testTimer?.cancel();
              print('🎉 [Test] All machines received data!');
              _testCompleteNotifier.value = true;
              _completeTest(success: true);
            }

            print('✅ [Control Panel] UI updated for machine: $storageKey');
          }
        },
        onError: (error) {
          print('❌ [Control Panel] Readings stream error: $error');
        },
      );

      // Listen to raw data stream for immediate feedback
      _rawDataSubscription = _bluetoothService.rawDataStream.listen((rawData) {
        print(
          '📡 [Control Panel] Raw BLE data received (${rawData.length} chars)',
        );
      });

      print('✅ [Control Panel] Listening to global readings stream');
    } catch (e) {
      print('❌ [Control Panel] Error setting up BLE listener: $e');
    }
  }

  /// Updates the display with new BLE data
  /// Call this method when BLE characteristic data is received
  void updateWithBLEData(String rawData) {
    print('\n▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼');
    print('🔄 [Control Panel] PARSING BLE DATA');
    print('─────────────────────────────────────────────────────────────');
    print('📥 Input: $rawData');
    print('📏 Length: ${rawData.length}');
    print('🔢 Bytes: ${rawData.codeUnits}');
    print('─────────────────────────────────────────────────────────────');

    final reading = LactosureReading.parse(rawData);

    if (reading != null) {
      // Extract machine ID from the reading (remove M prefix and leading zeros)
      final readingMachineId = reading.machineId
          .replaceFirst(RegExp(r'^[Mm]+'), '')
          .replaceFirst(RegExp(r'^0+'), '');

      print('✅ [Control Panel] PARSING SUCCESSFUL!');
      print('─────────────────────────────────────────────────────────────');
      print(
        '   🏭 Machine ID from data: ${reading.machineId} → $readingMachineId',
      );
      print('   🎯 Currently selected: $_currentMachineId');
      print('   🥛 Milk Type: ${reading.milkTypeName} (${reading.milkType})');
      print('   🧈 Fat: ${reading.fat}');
      print('   🥤 SNF: ${reading.snf}');
      print('   💧 CLR: ${reading.clr}');
      print('   🧀 Protein: ${reading.protein}');
      print('   🍼 Lactose: ${reading.lactose}');
      print('   🧂 Salt: ${reading.salt}');
      print('   💦 Water: ${reading.water}');
      print('   🌡️  Temperature: ${reading.temperature}°C');
      print('   👤 Farmer ID: ${reading.farmerId}');
      print('   📦 Quantity: ${reading.quantity}');
      print('   💰 Total: ₹${reading.totalAmount}');
      print('   💵 Rate: ₹${reading.rate}');
      print('   🎁 Incentive: ₹${reading.incentive}');
      print('─────────────────────────────────────────────────────────────');

      if (mounted) {
        setState(() {
          // Always store by machine ID from the data (normalized)
          final storageKey = readingMachineId.isNotEmpty
              ? readingMachineId
              : (_currentMachineId ?? 'unknown');

          // Store reading for this machine
          _machineReadings[storageKey] = reading;

          // Add to history for this machine
          _machineReadingHistory.putIfAbsent(storageKey, () => []);
          _machineReadingHistory[storageKey]!.add(reading);
          if (_machineReadingHistory[storageKey]!.length > _maxHistoryPoints) {
            _machineReadingHistory[storageKey]!.removeAt(0);
          }

          print('📊 [Control Panel] Stored reading for machine: $storageKey');
          print(
            '📊 [Control Panel] History size: ${_machineReadingHistory[storageKey]!.length}',
          );
          print(
            '📊 [Control Panel] All stored machines: ${_machineReadings.keys.toList()}',
          );

          // Check if this matches currently selected machine (for logging)
          final normalizedCurrentId = _normalizeId(_currentMachineId ?? '');
          final isCurrentMachine =
              storageKey == _currentMachineId ||
              storageKey == normalizedCurrentId ||
              _machineReadings.length == 1;

          if (isCurrentMachine) {
            print(
              '✅ [Control Panel] UI UPDATED - Data matches selected machine',
            );
          } else {
            print(
              '📥 [Control Panel] UI UPDATED - Data from machine $storageKey stored',
            );
          }
        });
      } else {
        print('❌ [Control Panel] Widget NOT MOUNTED, cannot update UI');
      }
    } else {
      print('❌ [Control Panel] PARSING FAILED!');
      print('─────────────────────────────────────────────────────────────');
      print('   Input was: $rawData');
    }
    print('▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲\n');
  }

  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (final machineId in _connectedMachineIds) {
        _machineWeighingScaleMode[machineId] =
            prefs.getBool('weighing_$machineId') ?? true;
        _machineFarmerIdMode[machineId] =
            prefs.getBool('farmerid_$machineId') ?? false; // Default: Manual
      }
    });
  }

  void _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in _machineWeighingScaleMode.entries) {
      await prefs.setBool('weighing_${entry.key}', entry.value);
    }
    for (final entry in _machineFarmerIdMode.entries) {
      await prefs.setBool('farmerid_${entry.key}', entry.value);
    }
  }

  void _initializeMachineList() {
    final connectedMachines = _bluetoothService.connectedMachines;
    _connectedMachineIds = connectedMachines.keys.toList();

    if (_connectedMachineIds.isNotEmpty) {
      // Try to find the initial machine or use first one
      if (widget.machineId != null) {
        final numericId = widget.machineId!.replaceAll(RegExp(r'[^0-9]'), '');
        final index = _connectedMachineIds.indexOf(numericId);
        if (index != -1) {
          _currentMachineIndex = index;
        }
      }
      _currentMachineId = _connectedMachineIds[_currentMachineIndex];
      // _currentMachineName = 'Machine ${_currentMachineId}'; // Commented - field unused

      // Clear all machine readings when panel opens - values start at 0
      // (trends are loaded separately from _loadSavedReadings)
      _machineReadings.clear();
    }

    // Listen to connection changes
    _bluetoothService.connectedMachinesStream.listen((machines) {
      if (mounted) {
        setState(() {
          _connectedMachineIds = machines.keys.toList();
          // Adjust index if current machine is disconnected
          if (_connectedMachineIds.isEmpty) {
            Navigator.pop(context); // Go back if all disconnected
          } else if (_currentMachineIndex >= _connectedMachineIds.length) {
            _currentMachineIndex = _connectedMachineIds.length - 1;
            _currentMachineId = _connectedMachineIds[_currentMachineIndex];
            // _currentMachineName = 'Machine ${_currentMachineId}'; // Commented - field unused
          }
        });
      }
    });
  }

  void _switchToPreviousMachine() {
    if (_connectedMachineIds.isEmpty) return;
    setState(() {
      _currentMachineIndex =
          (_currentMachineIndex - 1) % _connectedMachineIds.length;
      if (_currentMachineIndex < 0) {
        _currentMachineIndex = _connectedMachineIds.length - 1;
      }
      _currentMachineId = _connectedMachineIds[_currentMachineIndex];
      // _currentMachineName = 'Machine $_currentMachineId'; // Commented - field unused
      // Reset history navigation when switching machines
      _isViewingHistory = false;
      _historyIndex = 0;
    });
    print('⬅️ [Control Panel] Switched to machine: $_currentMachineId');
  }

  void _switchToNextMachine() {
    if (_connectedMachineIds.isEmpty) return;
    setState(() {
      _currentMachineIndex =
          (_currentMachineIndex + 1) % _connectedMachineIds.length;
      _currentMachineId = _connectedMachineIds[_currentMachineIndex];
      // _currentMachineName = 'Machine $_currentMachineId'; // Commented - field unused
      // Reset history navigation when switching machines
      _isViewingHistory = false;
      _historyIndex = 0;
    });
    print('➡️ [Control Panel] Switched to machine: $_currentMachineId');
  }

  void _handleTest() async {
    // Determine which machines to test
    List<String> machinesToTest = [];

    if (_testAllMachines) {
      machinesToTest = List.from(_connectedMachineIds);
    } else if (_selectedTestMachines.isNotEmpty) {
      machinesToTest = _selectedTestMachines.toList();
    } else if (_currentMachineId != null) {
      machinesToTest = [_currentMachineId!];
    }

    if (machinesToTest.isEmpty) {
      CustomSnackbar.showError(
        context,
        message: AppLocalizations().tr('no_machine_selected'),
        submessage: AppLocalizations().tr('select_machine_test'),
      );
      return;
    }

    // Clear stored farmer IDs and weights for new test
    _machineFarmerIds.clear();
    _machineWeights.clear();

    // Check which machines need manual farmer ID input (default is Manual = false)
    final manualFarmerIdMachines = machinesToTest
        .where((id) => !(_machineFarmerIdMode[id] ?? false))
        .toList();

    // Check which machines need manual weight input
    final manualWeightMachines = machinesToTest
        .where((id) => !(_machineWeighingScaleMode[id] ?? true))
        .toList();
    final hasWeightDialog = manualWeightMachines.isNotEmpty;

    // Only show dialog if there are manual machines
    if (manualFarmerIdMachines.isNotEmpty) {
      final farmerIds = await _showFarmerIdDialog(
        manualFarmerIdMachines,
        showStartTest: !hasWeightDialog,
      );

      if (farmerIds == null) {
        print('❌ [Test] User cancelled farmer ID input');
        return;
      }

      _machineFarmerIds.addAll(farmerIds);
      print('✅ [Test] Farmer IDs stored: $farmerIds');
    } else {
      print('✅ [Test] All machines in Auto mode, skipping farmer ID dialog');
    }

    if (hasWeightDialog) {
      final weights = await _showWeightDialog(manualWeightMachines);

      if (weights == null) {
        print('❌ [Test] User cancelled weight input');
        return;
      }

      _machineWeights.addAll(weights);
      print('✅ [Test] Weights stored: $weights');
    } else {
      print(
        '✅ [Test] All machines in Auto weighing mode, skipping weight dialog',
      );
    }

    _startTest(machinesToTest);
  }

  void _startTest(List<String> machinesToTest) async {
    // Reset all card values for all selected machines (same as clear button)
    setState(() {
      for (final machineId in machinesToTest) {
        _machineReadings.remove(machineId);
      }
      _isTestRunning = true;
      _testElapsedSeconds = 0;
      _machinesWithDataReceived.clear();
      _currentTestMachines = List.from(machinesToTest);
    });

    // Reset notifiers for live overlay
    _receivedMachinesNotifier.value = {};
    _testCompleteNotifier.value = false;
    _liveTestOverlay?.remove();
    _liveTestOverlay = null;

    // Start timer after 3 seconds delay
    _testTimer?.cancel();
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (!mounted || !_isTestRunning) return;

      _testTimer = Timer.periodic(const Duration(milliseconds: 1100), (timer) {
        if (mounted) {
          setState(() {
            _testElapsedSeconds++;
          });

          // Auto-stop after 45 seconds
          if (_testElapsedSeconds >= 45) {
            timer.cancel();
            CustomSnackbar.dismiss();
            if (_liveTestOverlay == null) {
              _showLiveTestOverlay();
            }
            _testCompleteNotifier.value = true;
            _completeTest(success: false, timeout: true);
          }
        } else {
          timer.cancel();
        }
      });
    });

    // Send test command to all selected machines
    int successCount = 0;
    for (final machineId in machinesToTest) {
      final command = _buildTestCommand(machineId);
      final success = await _bluetoothService.sendHexToMachine(
        machineId,
        command,
      );
      if (success) successCount++;
    }

    if (successCount > 0) {
      CustomSnackbar.showLoading(
        context,
        message: machinesToTest.length > 1
            ? '${AppLocalizations().tr('testing')} ${machinesToTest.length} ${AppLocalizations().tr('machines').toLowerCase()}'
            : '${AppLocalizations().tr('testing')} m${_formatMachineId(machinesToTest.first)}',
        submessage: AppLocalizations().tr('waiting_results'),
      );
    } else {
      CustomSnackbar.showError(
        context,
        message: AppLocalizations().tr('failed_test_command'),
        submessage: AppLocalizations().tr('check_ble_connection'),
      );
      _testTimer?.cancel();
      setState(() {
        _isTestRunning = false;
        _testElapsedSeconds = 0;
        _currentTestMachines.clear();
      });
      return;
    }
  }

  /// Show live test overlay that updates as machines respond
  void _showLiveTestOverlay() {
    _liveTestOverlay?.remove();
    final overlay = Overlay.of(context);

    _liveTestOverlay = OverlayEntry(
      builder: (context) => LiveTestOverlay(
        machines: _currentTestMachines,
        receivedMachinesNotifier: _receivedMachinesNotifier,
        testCompleteNotifier: _testCompleteNotifier,
        machineReadings: _machineReadings,
        onDismiss: () {
          _liveTestOverlay?.remove();
          _liveTestOverlay = null;
        },
      ),
    );

    overlay.insert(_liveTestOverlay!);
  }

  /// Show snackbar when data is received without test button
  void _showDataReceivedSnackbar(String machineId, LactosureReading reading) {
    final formattedId = _formatMachineId(machineId);
    CustomSnackbar.showSuccess(
      context,
      message: '${AppLocalizations().tr('data_received')} M$formattedId',
      submessage:
          '${AppLocalizations().tr('fat')}: ${reading.fat.toStringAsFixed(1)} | ${AppLocalizations().tr('snf')}: ${reading.snf.toStringAsFixed(1)} | ${AppLocalizations().tr('clr')}: ${reading.clr.toStringAsFixed(1)}',
      duration: const Duration(seconds: 3),
    );
  }

  /// Complete the test and update overlay state
  void _completeTest({required bool success, bool timeout = false}) {
    _testTimer?.cancel();
    setState(() {
      _isTestRunning = false;
      _testElapsedSeconds = 0;
    });

    // Auto dismiss overlay after 4 seconds when complete
    Future.delayed(const Duration(seconds: 4), () {
      _liveTestOverlay?.remove();
      _liveTestOverlay = null;
    });
  }

  /// Show test completion snackbar with machine status (legacy - kept for reference)
  // void _showTestCompletionSnackbar({
  //   required bool success,
  //   bool timeout = false,
  // }) {
  //   if (_isShowingResultSnackbar) return;
  //   _isShowingResultSnackbar = true;
  //
  //   // Cancel timer first
  //   _testTimer?.cancel();
  //
  //   setState(() {
  //     _isTestRunning = false;
  //     _testElapsedSeconds = 0;
  //   });
  //
  //   // Dismiss loading snackbar immediately
  //   CustomSnackbar.dismiss();
  //
  //   // Small delay to ensure loading snackbar is removed before showing result
  //   Future.delayed(const Duration(milliseconds: 100), () {
  //     if (mounted) {
  //       // Show result overlay with machine status
  //       _showTestResultOverlay(success: success, timeout: timeout);
  //     }
  //   });
  // }

  /// Show test result overlay with animated ticks for each machine
  // void _showTestResultOverlay({required bool success, bool timeout = false}) { // Unused
  //   final overlay = Overlay.of(context);
  //   late OverlayEntry overlayEntry;
  //
  //   overlayEntry = OverlayEntry(
  //     builder: (context) => TestResultOverlay(
  //       machines: _currentTestMachines,
  //       receivedMachines: _machinesWithDataReceived,
  //       machineReadings: _machineReadings,
  //       success: success,
  //       timeout: timeout,
  //       onDismiss: () {
  //         overlayEntry.remove();
  //         // _isShowingResultSnackbar = false;
  //       },
  //     ),
  //   );
  //
  //   overlay.insert(overlayEntry);
  //
  //   // Auto dismiss after 5 seconds
  //   Future.delayed(const Duration(seconds: 5), () {
  //     if (overlayEntry.mounted) {
  //       overlayEntry.remove();
  //       // _isShowingResultSnackbar = false;
  //     }
  //   });
  // }

  void _showTestMachineSelector() {
    _showMachineSelector('Test');
  }

  void _showMachineSelector(String actionName) {
    final l10n = AppLocalizations();

    // Get color and icon based on action
    Color actionColor;
    IconData actionIcon;
    switch (actionName) {
      case 'Test':
        actionColor = AppTheme.successColor;
        actionIcon = Icons.science_rounded;
        break;
      case 'OK':
        actionColor = AppTheme.primaryBlue;
        actionIcon = Icons.done_rounded;
        break;
      case 'Cancel':
        actionColor = AppTheme.warningColor;
        actionIcon = Icons.close_rounded;
        break;
      case 'Clean':
        actionColor = AppTheme.primaryPurple;
        actionIcon = Icons.opacity_rounded;
        break;
      default:
        actionColor = AppTheme.successColor;
        actionIcon = Icons.settings_rounded;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BottomSheetHeader(
                  title:
                      '${AppLocalizations().tr('select_machines_for')} $actionName',
                  icon: actionIcon,
                  color: actionColor,
                ),
                const SizedBox(height: 16),

                // All Machines checkbox
                CheckboxListTile(
                  value: _testAllMachines,
                  onChanged: (value) {
                    setModalState(() {
                      _testAllMachines = value ?? true;
                      if (_testAllMachines) {
                        _selectedTestMachines = Set.from(_connectedMachineIds);
                      }
                    });
                    setState(() {});
                  },
                  title: Text(
                    AppLocalizations().tr('all_machines'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  subtitle: Text(
                    '${_connectedMachineIds.length} ${AppLocalizations().tr('machines_connected')}',
                    style: TextStyle(color: context.textSecondaryColor),
                  ),
                  activeColor: actionColor,
                  contentPadding: EdgeInsets.zero,
                ),

                const Divider(),

                // Individual machine checkboxes with weighing scale toggle
                ..._connectedMachineIds.map((machineId) {
                  final isSelected =
                      _testAllMachines ||
                      _selectedTestMachines.contains(machineId);
                  final isWeighingAuto =
                      _machineWeighingScaleMode[machineId] ?? true;

                  return Column(
                    children: [
                      CheckboxListTile(
                        value: isSelected,
                        onChanged: _testAllMachines
                            ? null
                            : (value) {
                                setModalState(() {
                                  if (value == true) {
                                    _selectedTestMachines.add(machineId);
                                  } else {
                                    _selectedTestMachines.remove(machineId);
                                  }
                                });
                                setState(() {});
                              },
                        title: Text(
                          '${AppLocalizations().tr('machine')} m${_formatMachineId(machineId)}',
                          style: TextStyle(color: context.textPrimaryColor),
                        ),
                        activeColor: actionColor,
                        contentPadding: EdgeInsets.zero,
                      ),
                      // Weighing Scale & Farmer ID Toggles (only for Test)
                      if (actionName == 'Test') ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 48,
                            right: 16,
                            bottom: 4,
                            top: 4,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.scale_rounded,
                                size: 16,
                                color: context.textSecondaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Weighing Scale:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.textSecondaryColor,
                                  ),
                                ),
                              ),
                              _buildInlineToggle(
                                label: l10n.tr('auto'),
                                isSelected: isWeighingAuto,
                                onTap: () {
                                  setModalState(() {
                                    _machineWeighingScaleMode[machineId] = true;
                                  });
                                  setState(() {});
                                  _savePreferences();
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildInlineToggle(
                                label: l10n.tr('manual'),
                                isSelected: !isWeighingAuto,
                                onTap: () {
                                  setModalState(() {
                                    _machineWeighingScaleMode[machineId] =
                                        false;
                                  });
                                  setState(() {});
                                  _savePreferences();
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 48,
                            right: 16,
                            bottom: 8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.badge_rounded,
                                size: 16,
                                color: context.textSecondaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Farmer ID:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.textSecondaryColor,
                                  ),
                                ),
                              ),
                              _buildInlineToggle(
                                label: l10n.tr('auto'),
                                isSelected:
                                    _machineFarmerIdMode[machineId] ?? false,
                                onTap: () {
                                  setModalState(() {
                                    _machineFarmerIdMode[machineId] = true;
                                  });
                                  setState(() {});
                                  _savePreferences();
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildInlineToggle(
                                label: l10n.tr('manual'),
                                isSelected:
                                    !(_machineFarmerIdMode[machineId] ?? false),
                                onTap: () {
                                  setModalState(() {
                                    _machineFarmerIdMode[machineId] = false;
                                  });
                                  setState(() {});
                                  _savePreferences();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                }).toList(),

                const SizedBox(height: 16),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: Text(
                      _testAllMachines
                          ? '${AppLocalizations().tr('save')} (${AppLocalizations().tr('all')} ${_connectedMachineIds.length} ${AppLocalizations().tr('machines').toLowerCase()})'
                          : '${AppLocalizations().tr('save')} (${_selectedTestMachines.length} ${AppLocalizations().tr('selected').toLowerCase()})',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleOk() async {
    // Determine which machines to send OK (same logic as test)
    List<String> machinesToSend = [];

    if (_testAllMachines) {
      machinesToSend = List.from(_connectedMachineIds);
    } else if (_selectedTestMachines.isNotEmpty) {
      machinesToSend = _selectedTestMachines.toList();
    } else if (_currentMachineId != null) {
      machinesToSend = [_currentMachineId!];
    }

    if (machinesToSend.isEmpty) {
      CustomSnackbar.show(
        context,
        message: AppLocalizations().tr('no_machine_selected'),
        isSuccess: false,
      );
      return;
    }

    // Send OK command: 40 04 01 04 00 41
    int successCount = 0;
    for (final machineId in machinesToSend) {
      final success = await _bluetoothService.sendHexToMachine(
        machineId,
        '40 04 01 04 00 41',
      );
      if (success) successCount++;
    }

    if (successCount > 0) {
      CustomSnackbar.show(
        context,
        message: AppLocalizations().tr('ok_command_sent'),
        submessage: machinesToSend.length > 1
            ? '${AppLocalizations().tr('sent_to_machines').replaceAll('{count}', successCount.toString()).replaceAll('{total}', machinesToSend.length.toString())}'
            : '${AppLocalizations().tr('sent_to_machine').replaceAll('{id}', _formatMachineId(machinesToSend.first))}',
        isSuccess: true,
      );
    } else {
      CustomSnackbar.show(
        context,
        message: AppLocalizations().tr('failed_ok_command'),
        submessage: AppLocalizations().tr('check_ble_connection'),
        isSuccess: false,
      );
    }
  }

  void _handleCancel() async {
    // Stop the test timer and reset state
    if (_isTestRunning) {
      _testTimer?.cancel();
      setState(() {
        _isTestRunning = false;
        _testElapsedSeconds = 0;
      });
    }

    // Determine which machines to send Cancel (same logic as test)
    List<String> machinesToSend = [];

    if (_testAllMachines) {
      machinesToSend = List.from(_connectedMachineIds);
    } else if (_selectedTestMachines.isNotEmpty) {
      machinesToSend = _selectedTestMachines.toList();
    } else if (_currentMachineId != null) {
      machinesToSend = [_currentMachineId!];
    }

    if (machinesToSend.isEmpty) {
      CustomSnackbar.show(
        context,
        message: AppLocalizations().tr('no_machine_selected'),
        isSuccess: false,
      );
      return;
    }

    // Send Cancel command: 40 04 01 0A 00 4F
    int successCount = 0;
    for (final machineId in machinesToSend) {
      final success = await _bluetoothService.sendHexToMachine(
        machineId,
        '40 04 01 0A 00 4F',
      );
      if (success) successCount++;
    }

    if (successCount > 0) {
      CustomSnackbar.show(
        context,
        message: AppLocalizations().tr('cancel_command_sent'),
        submessage: machinesToSend.length > 1
            ? '${AppLocalizations().tr('sent_to_machines').replaceAll('{count}', successCount.toString()).replaceAll('{total}', machinesToSend.length.toString())}'
            : '${AppLocalizations().tr('sent_to_machine').replaceAll('{id}', _formatMachineId(machinesToSend.first))}',
        isSuccess: true,
      );
    } else {
      CustomSnackbar.show(
        context,
        message: AppLocalizations().tr('failed_cancel_command'),
        submessage: AppLocalizations().tr('check_ble_connection'),
        isSuccess: false,
      );
    }
  }

  void _handleClean() async {
    // Determine which machines to clean (same logic as test)
    List<String> machinesToClean = [];

    if (_testAllMachines) {
      machinesToClean = List.from(_connectedMachineIds);
    } else if (_selectedTestMachines.isNotEmpty) {
      machinesToClean = _selectedTestMachines.toList();
    } else if (_currentMachineId != null) {
      machinesToClean = [_currentMachineId!];
    }

    if (machinesToClean.isEmpty) {
      CustomSnackbar.show(
        context,
        message: AppLocalizations().tr('no_machine_selected'),
        isSuccess: false,
      );
      return;
    }

    // Send clean command to all selected machines: 40 04 09 00 0A 47
    int successCount = 0;
    for (final machineId in machinesToClean) {
      final success = await _bluetoothService.sendHexToMachine(
        machineId,
        '40 04 09 00 0A 47',
      );
      if (success) successCount++;
    }

    if (successCount > 0) {
      CustomSnackbar.show(
        context,
        message: AppLocalizations().tr('clean_command_sent'),
        submessage: machinesToClean.length > 1
            ? '${AppLocalizations().tr('cleaning_machines').replaceAll('{count}', successCount.toString()).replaceAll('{total}', machinesToClean.length.toString())}'
            : '${AppLocalizations().tr('starting_cleaning').replaceAll('{id}', _formatMachineId(machinesToClean.first))}',
        isSuccess: true,
      );
    } else {
      CustomSnackbar.show(
        context,
        message: AppLocalizations().tr('failed_clean_command'),
        submessage: AppLocalizations().tr('check_ble_connection'),
        isSuccess: false,
      );
    }
  }

  void _clearCurrentReading() {
    if (_currentMachineId == null) return;

    setState(() {
      // Clear only the current reading display, keep trends and stats
      _machineReadings.remove(_currentMachineId);
    });

    print(
      '🧹 [Control Panel] Current reading cleared for machine: $_currentMachineId',
    );
    CustomSnackbar.show(
      context,
      message:
          '${AppLocalizations().tr('display_cleared')} ${_formatMachineId(_currentMachineId ?? '')}',
      isSuccess: true,
    );
  }

  void _clearAllReadings() {
    if (_currentMachineId == null) return;

    setState(() {
      // Clear current reading and history
      _machineReadings.remove(_currentMachineId);
      _machineReadingHistory[_currentMachineId]?.clear();
    });

    // Also clear from storage
    _storageService.clearTodayReadings();

    // Recalculate statistics
    _calculateTodayStatistics();

    print(
      '🧹 [Control Panel] Readings cleared for machine: $_currentMachineId',
    );
    CustomSnackbar.show(
      context,
      message:
          '${AppLocalizations().tr('readings_cleared')} ${_formatMachineId(_currentMachineId ?? '')}',
      isSuccess: true,
    );
  }

  void _clearTrendOnly() {
    if (_currentMachineId == null) return;

    setState(() {
      // Clear only the history (trend), keep current reading
      _machineReadingHistory[_currentMachineId]?.clear();
    });

    // Clear from storage too
    _storageService.clearTodayReadings();

    // Recalculate statistics
    _calculateTodayStatistics();

    print('🧹 [Control Panel] Trend cleared for machine: $_currentMachineId');
    CustomSnackbar.show(
      context,
      message:
          '${AppLocalizations().tr('trend_cleared')}${_formatMachineId(_currentMachineId ?? '')}',
      isSuccess: true,
    );
  }

  void _showClearOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BottomSheetHeader(
              title: AppLocalizations().tr('clear_options'),
              icon: Icons.delete_sweep_rounded,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 20),

            // Clear Trend Only option
            OptionListTile(
              title: AppLocalizations().tr('clear_trend_only'),
              subtitle: AppLocalizations().tr('clear_trend_desc'),
              icon: Icons.show_chart_rounded,
              color: AppTheme.primaryAmber,
              showDividerAfter: true,
              onTap: () {
                Navigator.pop(context);
                _clearTrendOnly();
              },
            ),

            // Clear All option
            OptionListTile(
              title: AppLocalizations().tr('clear_all'),
              subtitle: AppLocalizations().tr('clear_all_desc'),
              icon: Icons.delete_forever_rounded,
              color: AppTheme.errorColor,
              onTap: () {
                Navigator.pop(context);
                _clearAllReadings();
              },
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected =
        _currentMachineId != null &&
        _bluetoothService.isMachineConnected(_currentMachineId!);
    final showNavigation = _connectedMachineIds.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations().tr('control_panel')),
        actions: [
          // Machine navigation (shown when multiple machines connected)
          if (showNavigation) ...[
            IconButton(
              onPressed: _switchToPreviousMachine,
              icon: const Icon(Icons.chevron_left),
              tooltip: AppLocalizations().tr('previous_machine'),
              iconSize: 20,
              padding: const EdgeInsets.all(8),
            ),
            // Machine number dropdown
            PopupMenuButton<int>(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: context.cardColor,
              elevation: 8,
              offset: const Offset(0, 50),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppTheme.primaryGreen.withOpacity(context.isDarkMode ? 0.15 : 0.08)
                      : AppTheme.errorColor.withOpacity(context.isDarkMode ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isConnected
                        ? AppTheme.primaryGreen.withOpacity(context.isDarkMode ? 0.4 : 0.6)
                        : AppTheme.errorColor.withOpacity(context.isDarkMode ? 0.4 : 0.6),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bluetooth icon colored by RSSI signal strength
                    Icon(
                      isConnected
                          ? Icons.bluetooth_connected_rounded
                          : Icons.bluetooth_disabled_rounded,
                      color: isConnected && _currentMachineDistance != null
                          ? _getSignalColor(_currentMachineDistance!)
                          : (isConnected
                                ? AppTheme.primaryGreen
                                : AppTheme.errorColor),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _currentMachineId ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isConnected
                            ? AppTheme.primaryGreen
                            : AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.expand_more_rounded,
                      size: 16,
                      color: isConnected
                          ? AppTheme.primaryGreen
                          : AppTheme.errorColor,
                    ),
                  ],
                ),
              ),
              onSelected: (index) {
                setState(() {
                  _currentMachineIndex = index;
                  _currentMachineId =
                      _connectedMachineIds[_currentMachineIndex];
                  // _currentMachineName = 'Machine $_currentMachineId'; // Commented - field unused
                });
              },
              itemBuilder: (context) {
                return List.generate(_connectedMachineIds.length, (index) {
                  final machineId = _connectedMachineIds[index];
                  final machineConnected = _bluetoothService.isMachineConnected(
                    machineId,
                  );
                  final isCurrentMachine = index == _currentMachineIndex;

                  return PopupMenuItem<int>(
                    value: index,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCurrentMachine
                            ? AppTheme.primaryGreen.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrentMachine
                              ? AppTheme.primaryGreen.withOpacity(0.3)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Serial number badge
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: machineConnected
                                  ? AppTheme.primaryGreen.withOpacity(0.15)
                                  : context.textSecondaryColor.withOpacity(
                                      0.15,
                                    ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: machineConnected
                                    ? AppTheme.primaryGreen.withOpacity(0.4)
                                    : context.textSecondaryColor.withOpacity(
                                        0.4,
                                      ),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: machineConnected
                                      ? AppTheme.primaryGreen
                                      : context.textSecondaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Machine info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${AppLocalizations().tr('machine')} $machineId',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: context.textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Bluetooth icon with signal strength color
                                    Icon(
                                      machineConnected
                                          ? Icons.bluetooth_connected_rounded
                                          : Icons.bluetooth_disabled_rounded,
                                      color: () {
                                        if (!machineConnected) {
                                          return AppTheme.errorColor;
                                        }
                                        final numericId = machineId.replaceAll(
                                          RegExp(r'[^0-9]'),
                                          '',
                                        );
                                        final distance = _bluetoothService
                                            .getMachineDistance(numericId);
                                        if (distance != null) {
                                          return _getSignalColor(distance);
                                        }
                                        return AppTheme.primaryGreen;
                                      }(),
                                      size: 14,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: machineConnected
                                            ? AppTheme.primaryGreen
                                            : AppTheme.errorColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      machineConnected
                                          ? AppLocalizations().tr('connected')
                                          : AppLocalizations().tr('offline'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: machineConnected
                                            ? AppTheme.primaryGreen
                                            : AppTheme.errorColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Check icon for current machine
                          if (isCurrentMachine)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: AppTheme.primaryGreen,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                });
              },
            ),
            IconButton(
              onPressed: _switchToNextMachine,
              icon: const Icon(Icons.chevron_right),
              tooltip: AppLocalizations().tr('next_machine'),
              iconSize: 20,
              padding: const EdgeInsets.all(8),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Main content area - Scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === SECTION 1: INFO (Top) ===
                  Row(
                    children: [
                      Expanded(
                        child: SectionLabel(
                          label: AppLocalizations().tr('info'),
                        ),
                      ),
                      // Channel dropdown
                      ChannelDropdownButton(
                        selectedChannel: _selectedChannel,
                        onChannelChanged: (channel) {
                          setState(() {
                            _selectedChannel = channel;
                          });
                          print(
                            '📡 [Control Panel] Channel changed to: $channel',
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // Reports button
                      CompactActionButton(
                        icon: Icons.assessment_rounded,
                        label: AppLocalizations().tr('reports'),
                        color: AppTheme.primaryPurple,
                        onTap: () {
                          // Set machine type for local reports
                          LocalReportsService().setMachineType(
                            widget.machineType,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ReportsScreen(defaultLocalMode: true),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // History navigation
                      if (_readingHistory.length > 1) ...[
                        HistoryNavigator(
                          historyCount: _readingHistory.length,
                          historyIndex: _historyIndex,
                          isViewingHistory: _isViewingHistory,
                          onPrevious: () {
                            setState(() {
                              _isViewingHistory = true;
                              _historyIndex++;
                            });
                          },
                          onNext: () {
                            setState(() {
                              _historyIndex--;
                              if (_historyIndex == 0) {
                                _isViewingHistory = false;
                              }
                            });
                          },
                          onGoToLive: () {
                            setState(() {
                              _isViewingHistory = false;
                              _historyIndex = 0;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Clear button
                      CompactActionButton(
                        icon: Icons.restart_alt_rounded,
                        label: AppLocalizations().tr('clear'),
                        color: AppTheme.errorColor,
                        onTap: _clearCurrentReading,
                        onLongPress: _showClearOptions,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(height: 60, child: _buildFarmerCard()),
                  const SizedBox(height: 16),

                  // === SECTION 2: PRIMARY READINGS (Fat, SNF, CLR) ===
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SectionLabel(
                        label: AppLocalizations().tr('milk_quality'),
                      ),
                      // Show timestamp of current reading
                      Text(
                        _formatReadingTimestamp(_currentReading.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _isViewingHistory
                              ? AppTheme.warningColor
                              : context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 170,
                    child: Row(
                      children: [
                        Expanded(
                          child: PrimaryReadingCard(
                            title: AppLocalizations().tr('fat').toUpperCase(),
                            value: _currentReading.fat.toStringAsFixed(2),
                            unit: '%',
                            color: AppTheme.primaryAmber,
                            isViewingHistory: _isViewingHistory,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PrimaryReadingCard(
                            title: AppLocalizations().tr('snf').toUpperCase(),
                            value: _currentReading.snf.toStringAsFixed(2),
                            unit: '%',
                            color: AppTheme.primaryBlue,
                            isViewingHistory: _isViewingHistory,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PrimaryReadingCard(
                            title: AppLocalizations().tr('clr').toUpperCase(),
                            value: _currentReading.clr.toStringAsFixed(1),
                            unit: '',
                            color: AppTheme.primaryPurple,
                            isViewingHistory: _isViewingHistory,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // === SECTION 3: TRANSACTION ===
                  SectionLabel(label: AppLocalizations().tr('transaction')),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 95,
                    child: Row(
                      children: [
                        Expanded(
                          child: TransactionCard(
                            title: AppLocalizations().tr('quantity'),
                            value: _currentReading.quantity.toStringAsFixed(2),
                            unit: 'L',
                            color: AppTheme.primaryBlue,
                            type: TransactionType.quantity,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '×',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TransactionCard(
                            title: AppLocalizations().tr('rate'),
                            value:
                                '₹${_currentReading.rate.toStringAsFixed(2)}',
                            unit: '/L',
                            color: AppTheme.primaryAmber,
                            type: TransactionType.rate,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '=',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: TotalAmountCard(
                            totalAmount: _currentReading.totalAmount,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // === SECTION 4: ADDITIONAL PARAMETERS ===
                  SectionLabel(
                    label: AppLocalizations().tr('other_parameters'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: Row(
                      children: [
                        Expanded(
                          child: InfoChip(
                            title: AppLocalizations().tr('milk_type'),
                            value: _currentReading.milkTypeName,
                            icon: Icons.category,
                            color: AppTheme.primaryGreen,
                            type: InfoChipType.milkType,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InfoChip(
                            title: AppLocalizations().tr('protein'),
                            value:
                                '${_currentReading.protein.toStringAsFixed(2)}%',
                            icon: Icons.fitness_center,
                            color: AppTheme.errorColor,
                            maxValue: 6.0,
                            type: InfoChipType.protein,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InfoChip(
                            title: AppLocalizations().tr('lactose'),
                            value:
                                '${_currentReading.lactose.toStringAsFixed(2)}%',
                            icon: Icons.science,
                            color: AppTheme.primaryPink,
                            maxValue: 8.0,
                            type: InfoChipType.lactose,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: Row(
                      children: [
                        Expanded(
                          child: InfoChip(
                            title: AppLocalizations().tr('salt'),
                            value:
                                '${_currentReading.salt.toStringAsFixed(2)}%',
                            icon: Icons.grain,
                            color: AppTheme.primarySlate,
                            maxValue: 2.0,
                            type: InfoChipType.salt,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InfoChip(
                            title: AppLocalizations().tr('water'),
                            value:
                                '${_currentReading.water.toStringAsFixed(2)}%',
                            icon: Icons.water_drop,
                            color: AppTheme.primaryTeal,
                            maxValue: 10.0,
                            type: InfoChipType.water,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InfoChip(
                            title: AppLocalizations().tr('temp'),
                            value:
                                '${_currentReading.temperature.toStringAsFixed(1)}°C',
                            icon: Icons.thermostat,
                            color: AppTheme.primaryOrange,
                            maxValue: 50.0,
                            type: InfoChipType.temp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // === SECTION 5: LIVE GRAPH (Bottom) ===
                  SectionLabel(
                    label:
                        '${AppLocalizations().tr('live_trend')} (${_getTodayDateString()})',
                  ),
                  const SizedBox(height: 8),
                  LiveTrendGraph(readingHistory: _readingHistory),

                  // === TODAY'S STATISTICS ===
                  if (_todayTestCount > 0) ...[
                    const SizedBox(height: 16),
                    SectionLabel(
                      label:
                          '${AppLocalizations().tr('todays_stats')} (${_getTodayDateString()})',
                    ),
                    const SizedBox(height: 8),
                    _buildTodayStatsCard(),
                  ],
                ],
              ),
            ),
          ),

          // === BOTTOM NAVIGATION BAR ===
          _buildBottomNavBar(),
        ],
      ),
    );
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    final l10n = AppLocalizations();
    final months = [
      l10n.tr('jan'),
      l10n.tr('feb'),
      l10n.tr('mar'),
      l10n.tr('apr'),
      l10n.tr('may'),
      l10n.tr('jun'),
      l10n.tr('jul'),
      l10n.tr('aug'),
      l10n.tr('sep'),
      l10n.tr('oct'),
      l10n.tr('nov'),
      l10n.tr('dec'),
    ];
    return '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}';
  }

  // Format machine ID: "Mm00200" → "m200", "Mm020" → "m20", "M12345" → "12345"
  String _formatMachineId(String id) {
    // Remove leading uppercase 'M' if present
    String result = id.startsWith('M') ? id.substring(1) : id;

    // If starts with lowercase 'm', keep it and remove leading zeros after it
    if (result.startsWith('m')) {
      final afterM = result.substring(1).replaceFirst(RegExp(r'^0+'), '');
      result = 'm${afterM.isEmpty ? '0' : afterM}';
    } else {
      // Just remove leading zeros
      result = result.replaceFirst(RegExp(r'^0+'), '');
      if (result.isEmpty) result = '0';
    }

    return result;
  }

  // Format reading timestamp for display
  String _formatReadingTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '--';
    final now = DateTime.now();
    final isToday =
        timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;

    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    if (isToday) {
      return '${AppLocalizations().tr('today')} $timeStr';
    } else {
      final dateStr =
          '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}';
      return '$dateStr $timeStr';
    }
  }

  // Format farmer ID: "00310" → "310", "000000" → "0"
  String _formatFarmerId(String id) {
    final result = id.replaceFirst(RegExp(r'^0+'), '');
    return result.isEmpty ? '0' : result;
  }

  Widget _buildTodayStatsCard() {
    return GradientCard(
      child: Column(
        children: [
          // Summary row (Tests, Quantity, Amount)
          Row(
            children: [
              StatItem(
                label: AppLocalizations().tr('tests'),
                value: '$_todayTestCount',
                icon: Icons.assignment_rounded,
                color: AppTheme.primaryBlue,
              ),
              const StatDivider(),
              StatItem(
                label: AppLocalizations().tr('quantity'),
                value: '${_totalQuantity.toStringAsFixed(1)}L',
                icon: Icons.water_drop_rounded,
                color: AppTheme.primaryTeal,
              ),
              const StatDivider(),
              StatItem(
                label: AppLocalizations().tr('amount'),
                value: '₹${_totalAmount.toStringAsFixed(0)}',
                icon: Icons.currency_rupee_rounded,
                color: AppTheme.primaryGreen,
              ),
            ],
          ),

          const SizedBox(height: 12),
          const ThemedDivider(),
          const SizedBox(height: 12),

          // Averages row (Avg FAT, Avg SNF)
          Row(
            children: [
              StatItem(
                label: AppLocalizations().tr('avg_fat'),
                value: _avgFat.toStringAsFixed(2),
                icon: Icons.opacity_rounded,
                color: AppTheme.primaryAmber,
                subtitle:
                    '${_lowestFat.toStringAsFixed(1)} - ${_highestFat.toStringAsFixed(1)}',
              ),
              const StatDivider(),
              StatItem(
                label: AppLocalizations().tr('avg_snf'),
                value: _avgSnf.toStringAsFixed(2),
                icon: Icons.grain_rounded,
                color: AppTheme.primaryPurple,
                subtitle:
                    '${_lowestSnf.toStringAsFixed(1)} - ${_highestSnf.toStringAsFixed(1)}',
              ),
            ],
          ),

          const SizedBox(height: 12),
          const ThemedDivider(),
          const SizedBox(height: 12),

          // Best and Worst row
          Row(
            children: [
              QualityHighlightCard(
                title: AppLocalizations().tr('best_quality'),
                icon: Icons.emoji_events_rounded,
                color: AppTheme.primaryGreen,
                farmerLabel: _bestReading != null
                    ? '${AppLocalizations().tr('farmer')} ${_formatFarmerId(_bestReading!.farmerId)}'
                    : null,
                farmerId: _bestReading?.farmerId,
                fatValue: _bestReading?.fat,
                snfValue: _bestReading?.snf,
                machineId: _bestMachineId != null
                    ? 'm${_formatMachineId(_bestMachineId!)}'
                    : null,
              ),
              const SizedBox(width: 10),
              QualityHighlightCard(
                title: AppLocalizations().tr('needs_improvement'),
                icon: Icons.trending_down_rounded,
                color: AppTheme.errorColor,
                farmerLabel: _worstReading != null
                    ? '${AppLocalizations().tr('farmer')} ${_formatFarmerId(_worstReading!.farmerId)}'
                    : null,
                farmerId: _worstReading?.farmerId,
                fatValue: _worstReading?.fat,
                snfValue: _worstReading?.snf,
                machineId: _worstMachineId != null
                    ? 'm${_formatMachineId(_worstMachineId!)}'
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(isDark ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          FarmerInfoItem(
            label: AppLocalizations().tr('tests').toUpperCase(),
            value:
                '${_currentMachineId != null ? (_machineTestCounts[_currentMachineId] ?? 0) : 0}',
            icon: Icons.assignment_rounded,
            color: AppTheme.primaryBlue,
            showDivider: false,
          ),
          FarmerInfoItem(
            label: AppLocalizations().tr('machine').toUpperCase(),
            value: _formatMachineId(_currentReading.machineId),
            icon: Icons.precision_manufacturing,
            color: AppTheme.primaryBlue,
          ),
          FarmerInfoItem(
            label: AppLocalizations().tr('farmer').toUpperCase(),
            value: _formatFarmerId(_currentReading.farmerId),
            icon: Icons.person,
            color: AppTheme.primaryTeal,
          ),
          FarmerInfoItem(
            label: AppLocalizations().tr('bonus').toUpperCase(),
            value: '₹${_currentReading.incentive.toStringAsFixed(2)}',
            icon: Icons.card_giftcard,
            color: AppTheme.primaryPurple,
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: isDark ? 20 : 12,
            offset: isDark ? const Offset(0, 4) : const Offset(0, 2),
            spreadRadius: isDark ? 0 : -2,
          ),
        ],
        border: Border.all(color: context.borderColor, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTestButton(),
          ActionButton(
            label: AppLocalizations().tr('ok'),
            icon: Icons.done_rounded,
            color: AppTheme.primaryBlue,
            onTap: _handleOk,
            onLongPress: () => _showMachineSelector('OK'),
            showAllIndicator: _connectedMachineIds.length > 1,
            isAllMode: _testAllMachines,
          ),
          ActionButton(
            label: AppLocalizations().tr('cancel'),
            icon: Icons.close_rounded,
            color: AppTheme.primaryAmber,
            onTap: _handleCancel,
            onLongPress: () => _showMachineSelector('Cancel'),
            showAllIndicator: _connectedMachineIds.length > 1,
            isAllMode: _testAllMachines,
          ),
          ActionButton(
            label: AppLocalizations().tr('clean'),
            icon: Icons.opacity_rounded,
            color: AppTheme.primaryPurple,
            onTap: _handleClean,
            onLongPress: () => _showMachineSelector('Clean'),
            showAllIndicator: _connectedMachineIds.length > 1,
            isAllMode: _testAllMachines,
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton() {
    final color = _isTestRunning
        ? AppTheme.primaryAmber
        : AppTheme.primaryGreen;
    final label = _isTestRunning
        ? '${_testElapsedSeconds}s'
        : AppLocalizations().tr('test');
    final icon = _isTestRunning
        ? Icons.hourglass_top_rounded
        : Icons.play_arrow_rounded;

    return ActionButton(
      label: label,
      icon: icon,
      color: color,
      onTap: _isTestRunning ? null : _handleTest,
      onLongPress: _isTestRunning ? null : _showTestMachineSelector,
      showAllIndicator: _connectedMachineIds.length > 1,
      isAllMode: _testAllMachines && !_isTestRunning,
      customIcon: _isTestRunning
          ? MilkTestAnimation(primaryColor: color, size: 44)
          : null,
    );
  }

  Widget _buildInlineToggle({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.successColor.withOpacity(0.15)
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppTheme.successColor : context.borderColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? AppTheme.primaryGreen
                : context.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Future<Map<String, String>?> _showFarmerIdDialog(
    List<String> machines, {
    bool showStartTest = false,
  }) async {
    final controllers = <String, TextEditingController>{};
    final focusNodes = <String, FocusNode>{};

    for (final machineId in machines) {
      controllers[machineId] = TextEditingController(
        text: _machineFarmerIds[machineId] ?? '',
      );
      focusNodes[machineId] = FocusNode();
    }

    // Auto-focus first field after dialog builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (machines.isNotEmpty) {
        focusNodes[machines.first]?.requestFocus();
      }
    });

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final l10n = AppLocalizations();
        return StatefulBuilder(
          builder: (context, setState) {
            final allFilled = controllers.values.every(
              (c) => c.text.trim().isNotEmpty,
            );

            return AlertDialog(
              backgroundColor: context.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.person_rounded,
                    color: AppTheme.successColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.tr('enter_farmer_ids'),
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: machines.asMap().entries.map((entry) {
                    final index = entry.key;
                    final machineId = entry.value;
                    final isLast = index == machines.length - 1;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n
                                .tr('machine_m')
                                .replaceAll(
                                  '{id}',
                                  _formatMachineId(machineId),
                                ),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: controllers[machineId],
                            focusNode: focusNodes[machineId],
                            keyboardType: TextInputType.number,
                            textInputAction: isLast
                                ? TextInputAction.done
                                : TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) {
                              if (!isLast) {
                                // Move to next field
                                final nextMachineId = machines[index + 1];
                                focusNodes[nextMachineId]?.requestFocus();
                              } else {
                                // Last field - auto-submit if all filled
                                final allCurrentlyFilled = controllers.values
                                    .every((c) => c.text.trim().isNotEmpty);
                                if (allCurrentlyFilled) {
                                  final farmerIds = <String, String>{};
                                  for (final entry in controllers.entries) {
                                    farmerIds[entry.key] = entry.value.text
                                        .trim();
                                  }
                                  // Don't dispose focus nodes - keep keyboard alive
                                  Navigator.pop(context, farmerIds);
                                }
                              }
                            },
                            decoration: InputDecoration(
                              hintText: l10n.tr('enter_farmer_id'),
                              prefixIcon: Icon(
                                Icons.badge_rounded,
                                color: AppTheme.primaryGreen,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: context.surfaceColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.borderColor,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppTheme.primaryGreen,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Dispose focus nodes
                    for (final node in focusNodes.values) {
                      node.dispose();
                    }
                    Navigator.pop(context, null);
                  },
                  child: Text(
                    l10n.tr('cancel'),
                    style: TextStyle(color: context.textSecondaryColor),
                  ),
                ),
                ElevatedButton(
                  onPressed: allFilled
                      ? () {
                          final farmerIds = <String, String>{};
                          for (final entry in controllers.entries) {
                            farmerIds[entry.key] = entry.value.text.trim();
                          }
                          // Dispose focus nodes
                          for (final node in focusNodes.values) {
                            node.dispose();
                          }
                          Navigator.pop(context, farmerIds);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: context.borderColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    showStartTest ? l10n.tr('start_test') : l10n.tr('continue'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  String _buildTestCommand(String machineId) {
    // Get channel byte based on dropdown selection
    // CH1 (Cow) = 0x00, CH2 (Buffalo) = 0x01, CH3 (Mixed) = 0x02
    int channelByte;
    switch (_selectedChannel) {
      case 'CH1':
        channelByte = 0x00; // Cow
        break;
      case 'CH2':
        channelByte = 0x01; // Buffalo
        break;
      case 'CH3':
        channelByte = 0x02; // Mixed
        break;
      default:
        channelByte = 0x00; // Default to Cow
    }

    // Get farmer ID (default 1 if not set or in Auto mode)
    final farmerIdStr = _machineFarmerIds[machineId] ?? '1';
    final farmerId = int.tryParse(farmerIdStr) ?? 1;

    // Convert farmer ID to 3 bytes (Big-Endian: MSB, MID, LSB)
    final farmerIdMsb = (farmerId >> 16) & 0xFF; // Most significant byte
    final farmerIdMid = (farmerId >> 8) & 0xFF; // Middle byte
    final farmerIdLsb = farmerId & 0xFF; // Least significant byte

    // Get weight (default 1 if not set or in Auto mode)
    final weightStr = _machineWeights[machineId] ?? '1';
    final weightFloat = double.tryParse(weightStr) ?? 1.0;

    // Multiply weight by 100 (e.g., 2.55 → 255, 0.01 → 1)
    final weightInt = (weightFloat * 100).round();

    // Convert weight to 4 bytes (Big-Endian: MSB first)
    final weightByte3 = (weightInt >> 24) & 0xFF; // Most significant byte
    final weightByte2 = (weightInt >> 16) & 0xFF; // Byte 2
    final weightByte1 = (weightInt >> 8) & 0xFF; // Byte 1
    final weightByte0 = weightInt & 0xFF; // Least significant byte

    // Cycle mode (default to 0x00)
    final cycleMode = 0x00;

    // Build command bytes
    // Format: 40 0B 07 [channel] [cycleMode] [farmerID_MSB] [farmerID_MID] [farmerID_LSB] [weight3] [weight2] [weight1] [weight0] [LRC]
    final bytes = [
      0x40, // Header
      0x0B, // Number of bytes (11)
      0x07, // Command: Test
      channelByte, // Channel (00=Cow, 01=Buffalo, 02=Mixed)
      cycleMode, // Cycle mode (default 00)
      farmerIdMsb, // Farmer ID MSB
      farmerIdMid, // Farmer ID MID
      farmerIdLsb, // Farmer ID LSB
      weightByte3, // Weight byte 3 (MSB)
      weightByte2, // Weight byte 2
      weightByte1, // Weight byte 1
      weightByte0, // Weight byte 0 (LSB)
    ];

    // Calculate LRC (XOR of all bytes)
    int lrc = 0;
    for (final byte in bytes) {
      lrc ^= byte;
    }
    bytes.add(lrc);

    // Convert to hex string
    final hexCommand = bytes
        .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
        .join(' ');

    print(
      '🔧 [Test Command] Machine: $machineId, Channel: $_selectedChannel, Farmer ID: $farmerId, Weight: ${weightFloat}kg',
    );
    print('🔧 [Test Command] Hex: $hexCommand');

    return hexCommand;
  }

  Future<Map<String, String>?> _showWeightDialog(List<String> machines) async {
    final controllers = <String, TextEditingController>{};
    final focusNodes = <String, FocusNode>{};

    for (final machineId in machines) {
      controllers[machineId] = TextEditingController(
        text: _machineWeights[machineId] ?? '',
      );
      focusNodes[machineId] = FocusNode();
    }

    // Auto-focus first field after dialog builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (machines.isNotEmpty) {
        focusNodes[machines.first]?.requestFocus();
      }
    });

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final l10n = AppLocalizations();
        return StatefulBuilder(
          builder: (context, setState) {
            final allFilled = controllers.values.every(
              (c) => c.text.trim().isNotEmpty,
            );

            return AlertDialog(
              backgroundColor: context.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.scale_rounded,
                    color: AppTheme.primaryGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.tr('enter_weights'),
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: machines.asMap().entries.map((entry) {
                    final index = entry.key;
                    final machineId = entry.value;
                    final isLast = index == machines.length - 1;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Machine m${_formatMachineId(machineId)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: controllers[machineId],
                            focusNode: focusNodes[machineId],
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: isLast
                                ? TextInputAction.done
                                : TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) {
                              if (!isLast) {
                                // Move to next field
                                final nextMachineId = machines[index + 1];
                                focusNodes[nextMachineId]?.requestFocus();
                              } else {
                                // Last field - auto-submit if all filled
                                final allCurrentlyFilled = controllers.values
                                    .every((c) => c.text.trim().isNotEmpty);
                                if (allCurrentlyFilled) {
                                  final weights = <String, String>{};
                                  for (final entry in controllers.entries) {
                                    weights[entry.key] = entry.value.text
                                        .trim();
                                  }
                                  // Dispose focus nodes
                                  for (final node in focusNodes.values) {
                                    node.dispose();
                                  }
                                  Navigator.pop(context, weights);
                                }
                              }
                            },
                            decoration: InputDecoration(
                              hintText: l10n.tr('enter_weight_kg'),
                              prefixIcon: Icon(
                                Icons.monitor_weight_rounded,
                                color: AppTheme.primaryGreen,
                                size: 20,
                              ),
                              suffixText: 'kg',
                              filled: true,
                              fillColor: context.surfaceColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.borderColor,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppTheme.successColor,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Dispose focus nodes
                    for (final node in focusNodes.values) {
                      node.dispose();
                    }
                    Navigator.pop(context, null);
                  },
                  child: Text(
                    l10n.tr('cancel'),
                    style: TextStyle(color: context.textSecondaryColor),
                  ),
                ),
                ElevatedButton(
                  onPressed: allFilled
                      ? () {
                          final weights = <String, String>{};
                          for (final entry in controllers.entries) {
                            weights[entry.key] = entry.value.text.trim();
                          }
                          // Dispose focus nodes
                          for (final node in focusNodes.values) {
                            node.dispose();
                          }
                          Navigator.pop(context, weights);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: context.borderColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(l10n.tr('start_test')),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  /// Get signal color based on distance
  Color _getSignalColor(double distance) {
    if (distance < 2.0) {
      return AppTheme.primaryGreen; // Excellent
    } else if (distance < 5.0) {
      return AppTheme.primaryAmber; // Good
    } else if (distance < 10.0) {
      return Colors.redAccent; // Weak
    } else {
      return Colors.red; // Very weak
    }
  }
}
