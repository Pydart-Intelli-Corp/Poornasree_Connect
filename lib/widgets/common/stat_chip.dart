import 'package:flutter/material.dart';
import '../../utils/utils.dart';

/// A reusable stat chip widget for displaying statistics with icon
class StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const StatChip({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primaryGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(context, 9),
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(context, 11),
                    fontWeight: FontWeight.w700,
                    color: chipColor,
                    letterSpacing: 0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
