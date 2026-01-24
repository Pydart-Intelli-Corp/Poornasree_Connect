import 'package:flutter/material.dart';
import '../../../utils/utils.dart';
import '../../../utils/helpers/size_config.dart';

/// A reusable action button for bottom navigation bars
/// Supports icons, labels, disabled state, and "all machines" indicator
class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showAllIndicator;
  final bool isAllMode;
  final Widget? customIcon;

  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
    this.onLongPress,
    this.showAllIndicator = false,
    this.isAllMode = false,
    this.customIcon,
  });

  bool get isDisabled => onTap == null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.spaceSmall),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    width: SizeConfig.iconSizeHuge,
                    height: SizeConfig.iconSizeHuge,
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? context.surfaceColor
                          : (isDark ? color.withOpacity(0.12) : color.withOpacity(0.08)),
                      borderRadius: BorderRadius.circular(SizeConfig.spaceMedium),
                      border: !isDisabled && !isDark ? Border.all(
                        color: color.withOpacity(0.2),
                        width: 1,
                      ) : null,
                    ),
                    child:
                        customIcon ??
                        Icon(
                          icon,
                          color: isDisabled ? Colors.grey : color,
                          size: SizeConfig.iconSizeLarge,
                        ),
                  ),
                  // "A" indicator for "All Machines" mode
                  if (showAllIndicator && isAllMode)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: SizeConfig.iconSizeMedium,
                        height: SizeConfig.iconSizeMedium,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'A',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: SizeConfig.fontSizeXSmall,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: SizeConfig.spaceTiny),
              Text(
                label,
                style: TextStyle(
                  fontSize: SizeConfig.fontSizeXSmall,
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? context.textSecondaryColor.withValues(alpha: 0.5)
                      : context.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
