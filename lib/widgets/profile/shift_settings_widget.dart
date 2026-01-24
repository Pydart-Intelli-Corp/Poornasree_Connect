import 'package:flutter/material.dart';
import '../../services/shift_settings_service.dart';
import '../../utils/helpers/size_config.dart';
import '../../utils/utils.dart';
import '../../l10n/l10n.dart';

/// Widget to configure shift time settings
class ShiftSettingsWidget extends StatefulWidget {
  const ShiftSettingsWidget({super.key});

  @override
  State<ShiftSettingsWidget> createState() => _ShiftSettingsWidgetState();
}

class _ShiftSettingsWidgetState extends State<ShiftSettingsWidget> {
  final ShiftSettingsService _shiftService = ShiftSettingsService();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _shiftService.loadSettings();
    setState(() {});
  }

  Future<void> _selectTime(String shiftType, bool isStart) async {
    int currentMinutes;
    if (shiftType == 'MR') {
      currentMinutes = isStart
          ? _shiftService.mrStartMinutes
          : _shiftService.mrEndMinutes;
    } else {
      currentMinutes = isStart
          ? _shiftService.evStartMinutes
          : _shiftService.evEndMinutes;
    }

    final TimeOfDay initialTime = TimeOfDay(
      hour: currentMinutes ~/ 60,
      minute: currentMinutes % 60,
    );

    final isDark = context.isDarkMode;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: AppTheme.primaryGreen,
                    onPrimary: Colors.white,
                    surface: context.cardColor,
                    onSurface: AppTheme.textPrimary,
                  )
                : ColorScheme.light(
                    primary: AppTheme.primaryGreen,
                    onPrimary: Colors.white,
                    surface: context.cardColor,
                    onSurface: AppTheme.textPrimaryLight,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final newMinutes = picked.hour * 60 + picked.minute;

      setState(() {
        if (shiftType == 'MR') {
          if (isStart) {
            _shiftService.setMorningShift(
              newMinutes,
              _shiftService.mrEndMinutes,
            );
          } else {
            // When MR end time changes, auto-update EV start time to match
            _shiftService.setMorningShift(
              _shiftService.mrStartMinutes,
              newMinutes,
            );
            _shiftService.setEveningShift(
              newMinutes,
              _shiftService.evEndMinutes,
            );
          }
        } else {
          if (isStart) {
            // When EV start time changes, also update MR end time to match
            _shiftService.setMorningShift(
              _shiftService.mrStartMinutes,
              newMinutes,
            );
            _shiftService.setEveningShift(
              newMinutes,
              _shiftService.evEndMinutes,
            );
          } else {
            _shiftService.setEveningShift(
              _shiftService.evStartMinutes,
              newMinutes,
            );
          }
        }
      });

      await _shiftService.saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final l10n = AppLocalizations();
    final isDark = context.isDarkMode;

    return Container(
      padding: EdgeInsets.all(SizeConfig.spaceMedium),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg2 : AppTheme.lightBg2,
        borderRadius: BorderRadius.circular(SizeConfig.radiusRegular),
      ),
      child: Column(
        children: [
          // Header row - tap to expand (matches SettingsTile layout)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(SizeConfig.spaceSmall),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    color: Colors.orange,
                    size: SizeConfig.iconSizeMedium,
                  ),
                ),
                SizedBox(width: SizeConfig.spaceMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tr('shift_settings'),
                        style: TextStyle(
                          fontSize: SizeConfig.fontSizeRegular,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      Text(
                        _isExpanded
                            ? ''
                            : '${l10n.tr('mr')}: ${_shiftService.minutesToTimeString(_shiftService.mrStartMinutes)}-${_shiftService.minutesToTimeString(_shiftService.mrEndMinutes)} | ${l10n.tr('ev')}: ${_shiftService.minutesToTimeString(_shiftService.evStartMinutes)}-${_shiftService.minutesToTimeString(_shiftService.evEndMinutes)}',
                        style: TextStyle(
                          fontSize: SizeConfig.fontSizeXSmall,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: context.textSecondaryColor,
                  size: SizeConfig.iconSizeMedium,
                ),
              ],
            ),
          ),

          // Expandable content
          if (_isExpanded) ...[
            SizedBox(height: SizeConfig.spaceMedium),
            Container(
              padding: EdgeInsets.all(SizeConfig.spaceMedium),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                children: [
                  // Morning Shift
                  _buildShiftRow(
                    label: '${l10n.tr('morning_shift')} (${l10n.tr('mr')})',
                    color: Colors.amber,
                    startTime: _shiftService.minutesToTimeString(
                      _shiftService.mrStartMinutes,
                    ),
                    endTime: _shiftService.minutesToTimeString(
                      _shiftService.mrEndMinutes,
                    ),
                    onStartTap: () => _selectTime('MR', true),
                    onEndTap: () => _selectTime('MR', false),
                    startLabel: l10n.tr('shift_start'),
                    endLabel: l10n.tr('shift_end'),
                    toLabel: l10n.tr('to'),
                  ),
                  SizedBox(height: SizeConfig.spaceSmall + 2),
                  // Evening Shift
                  _buildShiftRow(
                    label: '${l10n.tr('evening_shift')} (${l10n.tr('ev')})',
                    color: Colors.deepPurple,
                    startTime: _shiftService.minutesToTimeString(
                      _shiftService.evStartMinutes,
                    ),
                    endTime: _shiftService.minutesToTimeString(
                      _shiftService.evEndMinutes,
                    ),
                    onStartTap: () => _selectTime('EV', true),
                    onEndTap: () => _selectTime('EV', false),
                    startLabel: l10n.tr('shift_start'),
                    endLabel: l10n.tr('shift_end'),
                    toLabel: l10n.tr('to'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShiftRow({
    required String label,
    required Color color,
    required String startTime,
    required String endTime,
    required VoidCallback onStartTap,
    required VoidCallback onEndTap,
    required String startLabel,
    required String endLabel,
    required String toLabel,
  }) {
    return Row(
      children: [
        // Shift label
        Container(
          width: SizeConfig.normalize(100.0),
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.spaceSmall,
            vertical: SizeConfig.spaceXSmall,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(SizeConfig.spaceXSmall + 2),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: SizeConfig.fontSizeXSmall,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(width: SizeConfig.spaceMedium),
        // Start time
        Expanded(
          child: _buildTimeButton(
            time: startTime,
            label: startLabel,
            onTap: onStartTap,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.spaceSmall),
          child: Text(
            toLabel,
            style: TextStyle(
              fontSize: SizeConfig.fontSizeSmall,
              color: context.textSecondaryColor,
            ),
          ),
        ),
        // End time
        Expanded(
          child: _buildTimeButton(
            time: endTime,
            label: endLabel,
            onTap: onEndTap,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeButton({
    required String time,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDarkMode;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.spaceMedium,
          vertical: SizeConfig.spaceSmall,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
          borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
          border: Border.all(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          ),
        ),
        child: Column(
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: SizeConfig.fontSizeSmall,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: SizeConfig.fontSizeXSmall - 1,
                color: context.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
