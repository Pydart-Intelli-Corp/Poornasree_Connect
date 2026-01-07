import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/lactosure_reading.dart';
import 'live_test_overlay.dart';

/// Overlay widget showing test results with animated ticks for each machine
class TestResultOverlay extends StatefulWidget {
  final List<String> machines;
  final Set<String> receivedMachines;
  final Map<String, LactosureReading> machineReadings;
  final bool success;
  final bool timeout;
  final VoidCallback onDismiss;

  const TestResultOverlay({
    super.key,
    required this.machines,
    required this.receivedMachines,
    required this.machineReadings,
    required this.success,
    required this.timeout,
    required this.onDismiss,
  });

  @override
  State<TestResultOverlay> createState() => _TestResultOverlayState();
}

class _TestResultOverlayState extends State<TestResultOverlay>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _itemController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _itemController = AnimationController(
      duration: Duration(milliseconds: 300 * widget.machines.length + 500),
      vsync: this,
    );

    _slideController.forward();
    _itemController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    _slideController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  String _normalizeId(String id) {
    return id.replaceFirst(RegExp(r'^0+'), '');
  }

  bool _machineReceivedData(String machineId) {
    final normalizedId = _normalizeId(machineId);
    for (final received in widget.receivedMachines) {
      if (_normalizeId(received) == normalizedId || received == machineId) {
        return true;
      }
    }
    return false;
  }

  LactosureReading? _getReadingForMachine(String machineId) {
    final normalizedId = _normalizeId(machineId);

    // Try exact match
    if (widget.machineReadings.containsKey(machineId)) {
      return widget.machineReadings[machineId];
    }

    // Try normalized match
    for (final entry in widget.machineReadings.entries) {
      if (_normalizeId(entry.key) == normalizedId) {
        return entry.value;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allReceived =
        widget.receivedMachines.length >= widget.machines.length;
    final someReceived = widget.receivedMachines.isNotEmpty;

    final headerColor = allReceived
        ? const Color(0xFF10B981)
        : someReceived
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    final headerIcon = allReceived
        ? Icons.check_circle_rounded
        : someReceived
        ? Icons.warning_rounded
        : Icons.error_rounded;

    final headerText = allReceived
        ? AppLocalizations().tr('test_complete')
        : someReceived
        ? AppLocalizations().tr('partial_results')
        : AppLocalizations().tr('no_response');

    final subText = allReceived
        ? '${AppLocalizations().tr('all_machines_responded').replaceAll('{count}', widget.machines.length.toString())}' 
        : someReceived
        ? '${widget.receivedMachines.length}/${widget.machines.length} ${AppLocalizations().tr('machines_responded')}'
        : widget.timeout
        ? AppLocalizations().tr('timeout_no_response')
        : AppLocalizations().tr('failed_receive_data');

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: GestureDetector(
              onTap: _handleDismiss,
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity!.abs() > 100) {
                  _handleDismiss();
                }
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 400,
                    minWidth: 300,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E1E).withOpacity(0.95)
                        : Colors.white.withOpacity(0.98),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: headerColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: headerColor.withOpacity(0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: -4,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: headerColor.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            AnimatedHeaderIcon(
                              icon: headerIcon,
                              color: headerColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    headerText,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : headerColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _handleDismiss,
                              icon: Icon(
                                Icons.close_rounded,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade500,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Machine list
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: widget.machines.asMap().entries.map((
                            entry,
                          ) {
                            final index = entry.key;
                            final machineId = entry.value;
                            final received = _machineReceivedData(machineId);
                            final reading = _getReadingForMachine(machineId);

                            return AnimatedMachineItem(
                              index: index,
                              totalCount: widget.machines.length,
                              machineId: machineId,
                              received: received,
                              reading: reading,
                              controller: _itemController,
                              isDark: isDark,
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated machine item with staggered tick animation
class AnimatedMachineItem extends StatelessWidget {
  final int index;
  final int totalCount;
  final String machineId;
  final bool received;
  final LactosureReading? reading;
  final AnimationController controller;
  final bool isDark;

  const AnimatedMachineItem({
    super.key,
    required this.index,
    required this.totalCount,
    required this.machineId,
    required this.received,
    this.reading,
    required this.controller,
    required this.isDark,
  });

  String _formatMachineId(String id) {
    final normalized = id.replaceFirst(RegExp(r'^0+'), '');
    return normalized.isEmpty ? id : normalized;
  }

  @override
  Widget build(BuildContext context) {
    // Stagger animation based on index
    final startInterval = index / (totalCount + 1);
    final endInterval = (index + 1) / (totalCount + 1);

    final itemAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(startInterval, endInterval, curve: Curves.easeOut),
      ),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = itemAnimation.value;

        return Opacity(
          opacity: progress.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - progress)),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey.shade800.withOpacity(0.5)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: received
                      ? const Color(0xFF10B981).withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  // Machine icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: received
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.precision_manufacturing_rounded,
                      size: 20,
                      color: received
                          ? const Color(0xFF10B981)
                          : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Machine info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppLocalizations().tr('machine')} ${_formatMachineId(machineId)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (received && reading != null)
                          Text(
                            '${AppLocalizations().tr('fat').toUpperCase()}: ${reading!.fat.toStringAsFixed(2)} | ${AppLocalizations().tr('snf').toUpperCase()}: ${reading!.snf.toStringAsFixed(2)} | ${AppLocalizations().tr('quantity').substring(0, 3)}: ${reading!.quantity.toStringAsFixed(1)}L',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          )
                        else
                          Text(
                            received ? AppLocalizations().tr('data_received') : AppLocalizations().tr('no_response'),
                            style: TextStyle(
                              fontSize: 11,
                              color: received
                                  ? const Color(0xFF10B981)
                                  : Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Status icon with animation
                  AnimatedStatusIcon(
                    received: received,
                    delay: Duration(milliseconds: 200 + (index * 150)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
