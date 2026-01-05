import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/services.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';
import '../../models/lactosure_reading.dart';
import '../../widgets/reading_card.dart' as reading;

class MachineControlPanelScreen extends StatefulWidget {
  final String? machineId;
  final String? machineName;

  const MachineControlPanelScreen({
    super.key,
    this.machineId,
    this.machineName,
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

  // Current display reading (based on selected machine)
  LactosureReading get _currentReading {
    if (_currentMachineId == null) return _emptyReading;

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

  // Machine navigation state
  int _currentMachineIndex = 0;
  List<String> _connectedMachineIds = [];
  String? _currentMachineId;
  String? _currentMachineName;

  // BLE data subscription
  StreamSubscription? _bleDataSubscription;
  StreamSubscription? _rawDataSubscription;

  @override
  void initState() {
    super.initState();
    _initializeMachineList();
    _loadExistingReadings(); // Load readings that were collected before opening this screen
    _setupBLEDataListener();
  }

  @override
  void dispose() {
    _bleDataSubscription?.cancel();
    _rawDataSubscription?.cancel();
    _testTimer?.cancel();
    super.dispose();
  }

  /// Load existing readings from BluetoothService (collected before opening Control Panel)
  void _loadExistingReadings() {
    print('\n═══════════════════════════════════════════════════════════════');
    print('🔵 [Control Panel] Loading existing readings from BluetoothService');
    print('═══════════════════════════════════════════════════════════════\n');

    final existingReadings = _bluetoothService.machineReadings;
    final existingHistory = _bluetoothService.machineReadingHistory;

    if (existingReadings.isNotEmpty) {
      setState(() {
        _machineReadings.addAll(existingReadings);
        for (final entry in existingHistory.entries) {
          _machineReadingHistory[entry.key] = List.from(entry.value);
        }
      });
      print(
        '✅ [Control Panel] Loaded ${existingReadings.length} machine readings',
      );
      print('📊 [Control Panel] Machines: ${existingReadings.keys.toList()}');
    } else {
      print('ℹ️ [Control Panel] No existing readings found');
    }
  }

  void _setupBLEDataListener() {
    print('\n═══════════════════════════════════════════════════════════════');
    print('🔵 [Control Panel] Setting up BLE listener (using global stream)');
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

              // Stop test timer when ANY data is received
              if (_isTestRunning) {
                _testTimer?.cancel();
                _isTestRunning = false;
                _testElapsedSeconds = 0;
                print('⏱️ [Control Panel] Test completed - data received');
              }
            });
            print('✅ [Control Panel] UI updated for machine: $storageKey');
          }
        },
        onError: (error) {
          print('❌ [Control Panel] Readings stream error: $error');
        },
      );

      // Listen to raw data stream - stops timer IMMEDIATELY when any BLE data arrives
      _rawDataSubscription = _bluetoothService.rawDataStream.listen(
        (rawData) {
          // Stop test timer immediately when ANY raw BLE data is received
          if (_isTestRunning && mounted) {
            _testTimer?.cancel();
            setState(() {
              _isTestRunning = false;
              _testElapsedSeconds = 0;
            });
            print('⏱️ [Control Panel] Timer stopped - raw BLE data received (${rawData.length} chars)');
          }
        },
      );

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
      _currentMachineName = 'Machine ${_currentMachineId}';
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
            _currentMachineName = 'Machine ${_currentMachineId}';
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
      _currentMachineName = 'Machine $_currentMachineId';
      // No need to reset data - it's stored per machine in _machineReadings
      // The getters _currentReading and _readingHistory will automatically
      // return the correct data for the newly selected machine
    });
    print('⬅️ [Control Panel] Switched to machine: $_currentMachineId');
  }

  void _switchToNextMachine() {
    if (_connectedMachineIds.isEmpty) return;
    setState(() {
      _currentMachineIndex =
          (_currentMachineIndex + 1) % _connectedMachineIds.length;
      _currentMachineId = _connectedMachineIds[_currentMachineIndex];
      _currentMachineName = 'Machine $_currentMachineId';
      // No need to reset data - it's stored per machine in _machineReadings
      // The getters _currentReading and _readingHistory will automatically
      // return the correct data for the newly selected machine
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
      CustomSnackbar.show(
        context,
        message: 'No machine selected',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _isTestRunning = true;
      _testElapsedSeconds = 0;
    });

    // Start timer to count elapsed seconds
    _testTimer?.cancel();
    _testTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _testElapsedSeconds++;
        });

        // Auto-stop after 60 seconds (timeout)
        if (_testElapsedSeconds >= 60) {
          timer.cancel();
          setState(() {
            _isTestRunning = false;
            _testElapsedSeconds = 0;
          });
          CustomSnackbar.show(
            context,
            message: 'Test timeout',
            submessage: 'No response from machine',
            isSuccess: false,
          );
        }
      } else {
        timer.cancel();
      }
    });

    // Send test command to all selected machines
    int successCount = 0;
    for (final machineId in machinesToTest) {
      final success = await _bluetoothService.sendHexToMachine(
        machineId,
        '40 04 07 00 00 43',
      );
      if (success) successCount++;
    }

    if (successCount > 0) {
      CustomSnackbar.show(
        context,
        message: 'Test command sent',
        submessage: machinesToTest.length > 1
            ? 'Testing $successCount/${machinesToTest.length} machines...'
            : 'Starting milk test on m${_formatMachineId(machinesToTest.first)}...',
        isSuccess: true,
      );
    } else {
      CustomSnackbar.show(
        context,
        message: 'Failed to send test command',
        submessage: 'Check BLE connection',
        isSuccess: false,
      );
      _testTimer?.cancel();
      setState(() {
        _isTestRunning = false;
        _testElapsedSeconds = 0;
      });
      return;
    }
  }

  void _showTestMachineSelector() {
    _showMachineSelector('Test');
  }

  void _showMachineSelector(String actionName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get color and icon based on action
    Color actionColor;
    IconData actionIcon;
    switch (actionName) {
      case 'Test':
        actionColor = const Color(0xFF10B981);
        actionIcon = Icons.science_rounded;
        break;
      case 'OK':
        actionColor = const Color(0xFF3b82f6);
        actionIcon = Icons.done_rounded;
        break;
      case 'Cancel':
        actionColor = const Color(0xFFf59e0b);
        actionIcon = Icons.close_rounded;
        break;
      case 'Clean':
        actionColor = const Color(0xFF8b5cf6);
        actionIcon = Icons.opacity_rounded;
        break;
      default:
        actionColor = const Color(0xFF10B981);
        actionIcon = Icons.settings_rounded;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                Row(
                  children: [
                    Icon(actionIcon, color: actionColor, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Select Machines for $actionName',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
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
                    'All Machines',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    '${_connectedMachineIds.length} machines connected',
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                  activeColor: actionColor,
                  contentPadding: EdgeInsets.zero,
                ),

                const Divider(),

                // Individual machine checkboxes
                ..._connectedMachineIds.map((machineId) {
                  final isSelected =
                      _testAllMachines ||
                      _selectedTestMachines.contains(machineId);
                  return CheckboxListTile(
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
                      'Machine m${_formatMachineId(machineId)}',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    activeColor: actionColor,
                    contentPadding: EdgeInsets.zero,
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
                          ? 'Save (All ${_connectedMachineIds.length} machines)'
                          : 'Save (${_selectedTestMachines.length} selected)',
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
        message: 'No machine selected',
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
        message: 'OK command sent',
        submessage: machinesToSend.length > 1
            ? 'Sent to $successCount/${machinesToSend.length} machines'
            : 'Sent to m${_formatMachineId(machinesToSend.first)}',
        isSuccess: true,
      );
    } else {
      CustomSnackbar.show(
        context,
        message: 'Failed to send OK command',
        submessage: 'Check BLE connection',
        isSuccess: false,
      );
    }
  }

  void _handleCancel() async {
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
        message: 'No machine selected',
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
        message: 'Cancel command sent',
        submessage: machinesToSend.length > 1
            ? 'Sent to $successCount/${machinesToSend.length} machines'
            : 'Sent to m${_formatMachineId(machinesToSend.first)}',
        isSuccess: true,
      );
    } else {
      CustomSnackbar.show(
        context,
        message: 'Failed to send Cancel command',
        submessage: 'Check BLE connection',
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
        message: 'No machine selected',
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
        message: 'Clean command sent',
        submessage: machinesToClean.length > 1
            ? 'Cleaning $successCount/${machinesToClean.length} machines...'
            : 'Starting cleaning cycle on m${_formatMachineId(machinesToClean.first)}...',
        isSuccess: true,
      );
    } else {
      CustomSnackbar.show(
        context,
        message: 'Failed to send clean command',
        submessage: 'Check BLE connection',
        isSuccess: false,
      );
    }
  }

  void _clearAllReadings() {
    if (_currentMachineId == null) return;

    setState(() {
      // Clear only the current machine's readings
      _machineReadings.remove(_currentMachineId);
      _machineReadingHistory[_currentMachineId]?.clear();
    });
    print(
      '🧹 [Control Panel] Readings cleared for machine: $_currentMachineId',
    );
    CustomSnackbar.show(
      context,
      message:
          'Readings cleared for ${_formatMachineId(_currentMachineId ?? '')}',
      isSuccess: true,
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
        title: const Text('Control Panel'),
        actions: [
          // Machine navigation (shown when multiple machines connected)
          if (showNavigation) ...[
            IconButton(
              onPressed: _switchToPreviousMachine,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous Machine',
              iconSize: 20,
              padding: const EdgeInsets.all(8),
            ),
            // Machine number dropdown
            PopupMenuButton<int>(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        color: isConnected ? Colors.green : Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _currentMachineId ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 14),
                    ],
                  ),
                ),
              ),
              onSelected: (index) {
                setState(() {
                  _currentMachineIndex = index;
                  _currentMachineId =
                      _connectedMachineIds[_currentMachineIndex];
                  _currentMachineName = 'Machine $_currentMachineId';
                });
              },
              itemBuilder: (context) =>
                  List.generate(_connectedMachineIds.length, (index) {
                    final machineId = _connectedMachineIds[index];
                    final machineConnected = _bluetoothService
                        .isMachineConnected(machineId);
                    return PopupMenuItem<int>(
                      value: index,
                      child: Row(
                        children: [
                          if (index == _currentMachineIndex)
                            const Icon(
                              Icons.check,
                              color: AppTheme.primaryGreen,
                              size: 20,
                            )
                          else
                            const SizedBox(width: 20),
                          const SizedBox(width: 8),
                          Text('Machine $machineId'),
                          const SizedBox(width: 8),
                          Icon(
                            machineConnected
                                ? Icons.bluetooth_connected
                                : Icons.bluetooth_disabled,
                            color: machineConnected ? Colors.green : Colors.red,
                            size: 16,
                          ),
                        ],
                      ),
                    );
                  }),
            ),
            IconButton(
              onPressed: _switchToNextMachine,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next Machine',
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
                  // === SECTION 1: FARMER INFO (Top) ===
                  _buildSectionLabel('FARMER'),
                  const SizedBox(height: 8),
                  SizedBox(height: 60, child: _buildFarmerCard()),
                  const SizedBox(height: 16),

                  // === SECTION 2: PRIMARY READINGS (Fat, SNF, CLR) ===
                  _buildSectionLabel('MILK QUALITY'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 170,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildPrimaryCard(
                            'FAT',
                            _currentReading.fat.toStringAsFixed(2),
                            '%',
                            const Color(0xFFf59e0b),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPrimaryCard(
                            'SNF',
                            _currentReading.snf.toStringAsFixed(2),
                            '%',
                            const Color(0xFF3b82f6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPrimaryCard(
                            'CLR',
                            _currentReading.clr.toStringAsFixed(1),
                            '',
                            const Color(0xFF8b5cf6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // === SECTION 3: ADDITIONAL PARAMETERS ===
                  _buildSectionLabel('PARAMETERS'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildInfoChip(
                            'Milk Type',
                            _currentReading.milkTypeName,
                            Icons.category,
                            const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInfoChip(
                            'Protein',
                            '${_currentReading.protein.toStringAsFixed(2)}%',
                            Icons.fitness_center,
                            const Color(0xFFef4444),
                            maxValue: 6.0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInfoChip(
                            'Lactose',
                            '${_currentReading.lactose.toStringAsFixed(2)}%',
                            Icons.science,
                            const Color(0xFFec4899),
                            maxValue: 8.0,
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
                          child: _buildInfoChip(
                            'Salt',
                            '${_currentReading.salt.toStringAsFixed(2)}%',
                            Icons.grain,
                            const Color(0xFF78716c),
                            maxValue: 2.0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInfoChip(
                            'Water',
                            '${_currentReading.water.toStringAsFixed(2)}%',
                            Icons.water_drop,
                            const Color(0xFF14B8A6),
                            maxValue: 10.0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInfoChip(
                            'Temp',
                            '${_currentReading.temperature.toStringAsFixed(1)}°C',
                            Icons.thermostat,
                            const Color(0xFFf97316),
                            maxValue: 50.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // === SECTION 4: TRANSACTION ===
                  _buildSectionLabel('TRANSACTION'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 95,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTransactionCard(
                            'Quantity',
                            '${_currentReading.quantity.toStringAsFixed(2)}',
                            'L',
                            const Color(0xFF3b82f6),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTransactionCard(
                            'Rate',
                            '₹${_currentReading.rate.toStringAsFixed(2)}',
                            '/L',
                            const Color(0xFFf59e0b),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTransactionCard(
                            'Bonus',
                            '₹${_currentReading.incentive.toStringAsFixed(2)}',
                            '',
                            const Color(0xFF8b5cf6),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(flex: 2, child: _buildTotalAmountCard()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // === SECTION 5: LIVE GRAPH (Bottom) ===
                  _buildSectionLabel('LIVE TREND'),
                  const SizedBox(height: 8),
                  _buildLiveGraphCard(),
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

  Widget _buildLiveGraphCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Define parameter colors
    const fatColor = Color(0xFFf59e0b);
    const snfColor = Color(0xFF3b82f6);
    const clrColor = Color(0xFF8b5cf6);
    const waterColor = Color(0xFF14B8A6);

    // Create line data for each parameter
    List<FlSpot> fatSpots = [];
    List<FlSpot> snfSpots = [];
    List<FlSpot> clrSpots = [];
    List<FlSpot> waterSpots = [];

    double maxValue = 10; // Default minimum scale

    for (int i = 0; i < _readingHistory.length; i++) {
      final reading = _readingHistory[i];
      fatSpots.add(FlSpot(i.toDouble(), reading.fat));
      snfSpots.add(FlSpot(i.toDouble(), reading.snf));
      clrSpots.add(FlSpot(i.toDouble(), reading.clr));
      waterSpots.add(FlSpot(i.toDouble(), reading.water));

      // Track max value for auto-scaling
      if (reading.fat > maxValue) maxValue = reading.fat;
      if (reading.snf > maxValue) maxValue = reading.snf;
      if (reading.clr > maxValue) maxValue = reading.clr;
      if (reading.water > maxValue) maxValue = reading.water;
    }

    // Round up to next nice interval (10, 20, 30, 40, 50, etc.)
    final double maxY = ((maxValue / 10).ceil() * 10).toDouble().clamp(10, 100);
    final double interval = maxY / 10;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Legend row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('FAT', fatColor),
                  const SizedBox(width: 16),
                  _buildLegendItem('SNF', snfColor),
                  const SizedBox(width: 16),
                  _buildLegendItem('CLR', clrColor),
                  const SizedBox(width: 16),
                  _buildLegendItem('Water', waterColor),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Graph or placeholder
            Expanded(
              child: _readingHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.show_chart,
                            size: 40,
                            color: isDark
                                ? Colors.grey.shade600
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Waiting for data...',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade500,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Graph will show live trends when readings come in',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: interval,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              reservedSize: 22,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                // Show mark for every reading point
                                if (index >= 0 &&
                                    index < _readingHistory.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey.shade500
                                            : Colors.grey.shade600,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: interval,
                              reservedSize: 32,
                              getTitlesWidget: (value, meta) => Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: (_readingHistory.length - 1).toDouble().clamp(
                          0,
                          19,
                        ),
                        minY: 0,
                        maxY: maxY,
                        lineBarsData: [
                          _buildLineChartBarData(fatSpots, fatColor),
                          _buildLineChartBarData(snfSpots, snfColor),
                          _buildLineChartBarData(clrSpots, clrColor),
                          _buildLineChartBarData(waterSpots, waterColor),
                        ],
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (touchedSpot) =>
                                isDark ? const Color(0xFF1E293B) : Colors.white,
                            tooltipBorder: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                            ),
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                String label = '';
                                double actualValue = spot.y;
                                if (spot.barIndex == 0) {
                                  label = 'FAT';
                                } else if (spot.barIndex == 1) {
                                  label = 'SNF';
                                } else if (spot.barIndex == 2) {
                                  label = 'CLR';
                                } else if (spot.barIndex == 3) {
                                  label = 'Water';
                                }
                                return LineTooltipItem(
                                  '$label: ${actualValue.toStringAsFixed(2)}',
                                  TextStyle(
                                    color: spot.bar.color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.5), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  LineChartBarData _buildLineChartBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          // Only show dot for the last point (latest reading)
          if (index == spots.length - 1) {
            return FlDotCirclePainter(
              radius: 4,
              color: color,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          }
          return FlDotCirclePainter(
            radius: 0,
            color: Colors.transparent,
            strokeWidth: 0,
            strokeColor: Colors.transparent,
          );
        },
      ),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey[600],
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryCard(
    String title,
    String value,
    String unit,
    Color color,
  ) {
    final double numValue = double.tryParse(value) ?? 0.0;
    final double maxValue = title == 'CLR' ? 100 : 15;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: numValue),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        final progress = (animatedValue / maxValue).clamp(0.0, 1.0);
        final isActive = animatedValue > 0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [Colors.white, Colors.grey.shade50],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? color.withOpacity(isDark ? 0.5 : 0.4)
                  : color.withOpacity(isDark ? 0.2 : 0.1),
              width: isActive ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? color.withOpacity(0.3)
                    : color.withOpacity(0.1),
                blurRadius: isActive ? 16 : 8,
                offset: const Offset(0, 4),
                spreadRadius: isActive ? 2 : 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated title badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(
                  horizontal: isActive ? 12 : 8,
                  vertical: isActive ? 4 : 2,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? color.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unit.isNotEmpty ? '$title($unit)' : title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? color
                        : (isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Animated circular indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing glow when active
                  if (isActive)
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  color.withOpacity(0.2),
                                  color.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  // Background ring
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 5,
                      backgroundColor: isDark
                          ? const Color(0xFF374151)
                          : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? const Color(0xFF374151) : Colors.grey.shade200,
                      ),
                    ),
                  ),
                  // Animated progress ring
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  // Animated value in center
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: isActive ? 18 : 16,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                    child: Text(animatedValue.toStringAsFixed(2)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Animated status indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(
                  horizontal: isActive ? 10 : 8,
                  vertical: isActive ? 4 : 2,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF10B981).withOpacity(0.15)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated pulsing dot
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isActive ? 10 : 6,
                      height: isActive ? 10 : 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? const Color(0xFF10B981) : Colors.grey,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withOpacity(0.6),
                                  blurRadius: 8,
                                  spreadRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isActive ? 'LIVE' : 'IDLE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isActive ? const Color(0xFF10B981) : Colors.grey,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(
    String title,
    String value,
    IconData icon,
    Color color, {
    double maxValue = 10.0,
  }) {
    // Extract numeric value for progress calculation
    final numericStr = value.replaceAll(RegExp(r'[^0-9.]'), '');
    final double numValue = double.tryParse(numericStr) ?? 0.0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = numValue > 0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: numValue),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        final progress = (animatedValue / maxValue).clamp(0.0, 1.0);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [Colors.white, Colors.grey.shade50],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? color.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? color.withOpacity(0.15)
                    : Colors.black.withOpacity(0.05),
                blurRadius: isActive ? 10 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with icon and title
                Row(
                  children: [
                    // Animated icon container
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(isActive ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: isActive ? color : color.withOpacity(0.5),
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Animated value
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: isActive ? 16 : 14,
                    fontWeight: FontWeight.w800,
                    color: isActive
                        ? color
                        : (isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade400),
                  ),
                  child: Text(
                    title == 'Milk Type'
                        ? value
                        : (title == 'Temp'
                              ? '${animatedValue.toStringAsFixed(1)}°C'
                              : '${animatedValue.toStringAsFixed(2)}%'),
                  ),
                ),
                const SizedBox(height: 6),
                // Animated line progress indicator
                Stack(
                  children: [
                    // Background track
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF374151)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Animated progress bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      height: 4,
                      width: double.infinity,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: title == 'Milk Type' ? 1.0 : progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withOpacity(0.7)],
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.5),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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

  // Format farmer ID: "00310" → "310", "000000" → "0"
  String _formatFarmerId(String id) {
    final result = id.replaceFirst(RegExp(r'^0+'), '');
    return result.isEmpty ? '0' : result;
  }

  Widget _buildFarmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.teal, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FARMER ID',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatFarmerId(_currentReading.farmerId),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 30, width: 1, color: Colors.teal.withOpacity(0.3)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.precision_manufacturing,
              color: Colors.indigo,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MACHINE ID',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatMachineId(_currentReading.machineId),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    String title,
    String value,
    String unit,
    Color color,
  ) {
    final numericStr = value.replaceAll(RegExp(r'[^0-9.]'), '');
    final double numValue = double.tryParse(numericStr) ?? 0.0;
    final double maxValue = title == 'Quantity'
        ? 50
        : 100; // Max for progress indicator
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: numValue),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        final progress = (animatedValue / maxValue).clamp(0.0, 1.0);
        final isActive = animatedValue > 0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [Colors.white, Colors.grey.shade50],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? color.withOpacity(isDark ? 0.5 : 0.4)
                  : color.withOpacity(isDark ? 0.2 : 0.1),
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? color.withOpacity(0.25)
                    : color.withOpacity(0.08),
                blurRadius: isActive ? 12 : 6,
                offset: const Offset(0, 3),
                spreadRadius: isActive ? 1 : 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.symmetric(
                    horizontal: isActive ? 8 : 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? color.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? color
                          : (isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Spacer(),
                // Animated value with unit
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: isActive ? 18 : 15,
                          fontWeight: FontWeight.w800,
                          color: isActive
                              ? color
                              : (isDark
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade400),
                        ),
                        child: Text(
                          value.contains('₹')
                              ? '₹${animatedValue.toStringAsFixed(2)}'
                              : animatedValue.toStringAsFixed(2),
                        ),
                      ),
                      if (unit.isNotEmpty)
                        Text(
                          unit,
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Progress bar
                Stack(
                  children: [
                    // Background track
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF374151)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Animated fill
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color.withOpacity(0.7), color],
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.4),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalAmountCard() {
    final double totalAmount = _currentReading.totalAmount;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = totalAmount > 0;
    const color = Color(0xFF10B981);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: totalAmount),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E293B), color.withOpacity(0.15)]
                  : [Colors.white, color.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withOpacity(isActive ? 0.6 : 0.3),
              width: isActive ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(isActive ? 0.3 : 0.1),
                blurRadius: isActive ? 16 : 8,
                offset: const Offset(0, 4),
                spreadRadius: isActive ? 2 : 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Glowing accent bar at top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.6), color],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title with icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(isActive ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: color,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'TOTAL',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Animated amount
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: isActive ? 24 : 20,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                        child: Text('₹${animatedValue.toStringAsFixed(2)}'),
                      ),
                    ),
                    const Spacer(),
                    // Status badge
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.symmetric(
                        horizontal: isActive ? 10 : 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? color.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: isActive ? 8 : 6,
                            height: isActive ? 8 : 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? color : Colors.grey,
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.6),
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isActive ? 'PAID' : 'PENDING',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: isActive ? color : Colors.grey,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTestButton(),
          _buildNavButton(
            'OK',
            Icons.done_rounded,
            const Color(0xFF3b82f6),
            _handleOk,
            onLongPress: () => _showMachineSelector('OK'),
            showAllIndicator: true,
          ),
          _buildNavButton(
            'Cancel',
            Icons.close_rounded,
            const Color(0xFFf59e0b),
            _handleCancel,
            onLongPress: () => _showMachineSelector('Cancel'),
            showAllIndicator: true,
          ),
          _buildNavButton(
            'Clean',
            Icons.opacity_rounded,
            const Color(0xFF8b5cf6),
            _handleClean,
            onLongPress: () => _showMachineSelector('Clean'),
            showAllIndicator: true,
          ),
          _buildNavButton(
            'Clear',
            Icons.restart_alt_rounded,
            const Color(0xFFef4444),
            _clearAllReadings,
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _isTestRunning
        ? const Color(0xFFf59e0b)
        : const Color(0xFF10B981);
    final isDisabled = _isTestRunning;
    final label = _isTestRunning ? '${_testElapsedSeconds}s' : 'Test';
    final icon = _isTestRunning
        ? Icons.hourglass_top_rounded
        : Icons.play_arrow_rounded;

    return Expanded(
      child: GestureDetector(
        onTap: _isTestRunning ? null : _handleTest,
        onLongPress: _isTestRunning ? null : _showTestMachineSelector,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? (isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100)
                          : color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: isDisabled ? Colors.grey : color,
                      size: 24,
                    ),
                  ),
                  // Indicator for "Test All" mode
                  if (_testAllMachines && !_isTestRunning)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'A',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? Colors.grey
                      : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onTap, {
    VoidCallback? onLongPress,
    bool showAllIndicator = false,
  }) {
    final isDisabled = onTap == null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? (isDark ? Colors.grey.shade800 : Colors.grey.shade100)
                          : color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: isDisabled ? Colors.grey : color,
                      size: 24,
                    ),
                  ),
                  // "A" indicator for "All Machines" mode
                  if (showAllIndicator && _testAllMachines)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'A',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? Colors.grey
                      : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
