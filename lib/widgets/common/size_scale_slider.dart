import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/utils.dart';
import '../../l10n/l10n.dart';

/// Size Scale Slider - Allows users to adjust UI size
class SizeScaleSlider extends StatefulWidget {
  final ValueChanged<double>? onChanged;

  const SizeScaleSlider({super.key, this.onChanged});

  @override
  State<SizeScaleSlider> createState() => _SizeScaleSliderState();
}

class _SizeScaleSliderState extends State<SizeScaleSlider> {
  double _currentScale = 1.0;
  static const String _prefsKey = 'ui_size_scale';

  @override
  void initState() {
    super.initState();
    _loadScale();
  }

  Future<void> _loadScale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedScale = prefs.getDouble(_prefsKey) ?? 1.0;
    // Clamp the scale to the new max value (1.15)
    final clampedScale = savedScale.clamp(1.0, 1.15);
    
    // If the value was clamped, save the new value
    if (clampedScale != savedScale) {
      await prefs.setDouble(_prefsKey, clampedScale);
    }
    
    setState(() {
      _currentScale = clampedScale;
    });
    SizeConfig.setUserScale(clampedScale);
  }

  Future<void> _saveScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsKey, scale);
    setState(() {
      _currentScale = scale;
    });
    SizeConfig.setUserScale(scale);
    widget.onChanged?.call(scale);
  }

  String _getScaleLabel(double scale) {
    if (scale <= 1.0) return AppLocalizations().tr('size_normal');
    if (scale <= 1.05) return AppLocalizations().tr('size_medium');
    if (scale <= 1.1) return AppLocalizations().tr('size_large');
    return AppLocalizations().tr('size_extra_large');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations();

    return Container(
      padding: EdgeInsets.all(SizeConfig.spaceMedium),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(SizeConfig.radiusRegular),
        border: Border.all(color: context.borderColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.text_fields,
                    size: SizeConfig.iconSizeMedium,
                    color: AppTheme.primaryGreen,
                  ),
                  SizedBox(width: SizeConfig.spaceSmall),
                  Text(
                    l10n.tr('ui_size'),
                    style: TextStyle(
                      fontSize: SizeConfig.fontSizeRegular,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.spaceSmall,
                  vertical: SizeConfig.spaceXSmall,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(SizeConfig.radiusSmall),
                ),
                child: Text(
                  _getScaleLabel(_currentScale),
                  style: TextStyle(
                    fontSize: SizeConfig.fontSizeSmall,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.spaceSmall),
          Row(
            children: [
              Icon(
                Icons.text_decrease,
                size: SizeConfig.iconSizeSmall,
                color: context.textSecondaryColor,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.primaryGreen,
                    inactiveTrackColor: AppTheme.primaryGreen.withOpacity(0.2),
                    thumbColor: AppTheme.primaryGreen,
                    overlayColor: AppTheme.primaryGreen.withOpacity(0.2),
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: SizeConfig.spaceSmall + 2,
                    ),
                    overlayShape: RoundSliderOverlayShape(
                      overlayRadius: SizeConfig.spaceRegular,
                    ),
                  ),
                  child: Slider(
                    value: _currentScale,
                    min: 1.0,
                    max: 1.15,
                    divisions: 15,
                    onChanged: (value) {
                      _saveScale(value);
                    },
                  ),
                ),
              ),
              Icon(
                Icons.text_increase,
                size: SizeConfig.iconSizeMedium,
                color: context.textSecondaryColor,
              ),
            ],
          ),
          SizedBox(height: SizeConfig.spaceXSmall),
          Text(
            l10n.tr('ui_size_description'),
            style: TextStyle(
              fontSize: SizeConfig.fontSizeSmall,
              color: context.textSecondaryColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
