import 'package:flutter/material.dart';
import '../../../utils/utils.dart';

/// A navigation button used in bottom navigation bar
class NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showAllIndicator;
  final bool isAllMode;

  const NavButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
    this.onLongPress,
    this.showAllIndicator = false,
    this.isAllMode = false,
  });

  @override
  Widget build(BuildContext context) {
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
                          ? context.surfaceColor
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
