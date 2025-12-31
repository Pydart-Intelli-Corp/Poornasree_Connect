import 'package:flutter/material.dart';
import '../../utils/utils.dart';

/// Reusable machine selection dialog for changing master machine
class MachineSelectionDialog extends StatefulWidget {
  final String currentMachineId;
  final List<Map<String, dynamic>> availableMachines;
  final String? expiresAt;

  const MachineSelectionDialog({
    super.key,
    required this.currentMachineId,
    required this.availableMachines,
    this.expiresAt,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String currentMachineId,
    required List<Map<String, dynamic>> availableMachines,
    String? expiresAt,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MachineSelectionDialog(
        currentMachineId: currentMachineId,
        availableMachines: availableMachines,
        expiresAt: expiresAt,
      ),
    );
  }

  @override
  State<MachineSelectionDialog> createState() => _MachineSelectionDialogState();
}

class _MachineSelectionDialogState extends State<MachineSelectionDialog> {
  Map<String, dynamic>? _selectedMachine;
  String? _timeRemaining;

  @override
  void initState() {
    super.initState();
    if (widget.expiresAt != null) {
      _updateTimeRemaining();
      // Update every second
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          _updateTimeRemaining();
          return true;
        }
        return false;
      });
    }
  }

  void _updateTimeRemaining() {
    if (widget.expiresAt == null) return;

    try {
      final expiresAt = DateTime.parse(widget.expiresAt!);
      final now = DateTime.now(); // Use local IST time
      final difference = expiresAt.difference(now);

      if (difference.isNegative) {
        setState(() => _timeRemaining = 'Expired');
      } else {
        final minutes = difference.inMinutes;
        final seconds = difference.inSeconds % 60;
        setState(() => _timeRemaining = '${minutes}m ${seconds}s');
      }
    } catch (e) {
      setState(() => _timeRemaining = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.swap_horiz,
                    color: AppTheme.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select New Master',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current machine info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Current: ${widget.currentMachineId}',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Timer display if expires_at is provided
            if (_timeRemaining != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _timeRemaining == 'Expired'
                      ? AppTheme.errorColor.withOpacity(0.1)
                      : AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _timeRemaining == 'Expired'
                        ? AppTheme.errorColor.withOpacity(0.3)
                        : AppTheme.primaryGreen.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: _timeRemaining == 'Expired'
                          ? AppTheme.errorColor
                          : AppTheme.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _timeRemaining == 'Expired'
                            ? 'Access Expired'
                            : 'Time Remaining: $_timeRemaining',
                        style: TextStyle(
                          color: _timeRemaining == 'Expired'
                              ? AppTheme.errorColor
                              : AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Available machines label
            Text(
              'Available Machines:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Machines list
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.availableMachines.length,
                itemBuilder: (context, index) {
                  final machine = widget.availableMachines[index];
                  final machineId =
                      machine['machineId'] ?? machine['machine_id'];
                  final isSelected = _selectedMachine == machine;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: isSelected ? 2 : 0,
                    color: isSelected
                        ? AppTheme.primaryGreen.withOpacity(0.1)
                        : AppTheme.cardDark2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : AppTheme.borderDark,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      leading: Icon(
                        Icons.agriculture,
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : AppTheme.textSecondary,
                      ),
                      title: Text(
                        machineId.toString(),
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : AppTheme.textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: AppTheme.primaryGreen,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedMachine = machine;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: BorderSide(color: AppTheme.borderDark),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _selectedMachine == null || _timeRemaining == 'Expired'
                        ? null
                        : () => Navigator.pop(context, _selectedMachine),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.cardDark2,
                      disabledForegroundColor: AppTheme.textTertiary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _timeRemaining == 'Expired'
                          ? 'Access Expired'
                          : 'Confirm',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
