import 'package:flutter/material.dart';

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
                                : const Color(0xFFF3F4F6))
                          : (isDark ? color.withOpacity(0.12) : color.withOpacity(0.08)),
                      borderRadius: BorderRadius.circular(14),
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
                          size: 24,
                        ),
                  ),
                  // "A" indicator for "All Machines" mode
                  if (showAllIndicator && isAllMode)
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
}
