import 'package:flutter/material.dart';
import '../../utils/utils.dart';

/// A reusable row widget for displaying label-value pairs with an icon
class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final double iconSize;
  final double fontSize;
  final EdgeInsets padding;

  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.iconSize = 18,
    this.fontSize = 13,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Icon(icon, size: iconSize, color: iconColor ?? AppTheme.primaryGreen),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(fontSize: fontSize, color: context.textSecondaryColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: context.textPrimaryColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
