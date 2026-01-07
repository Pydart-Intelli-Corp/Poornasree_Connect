import 'package:flutter/material.dart';
import '../../../utils/utils.dart';

class InfoContainer extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final double? borderRadius;

  const InfoContainer({
    super.key,
    required this.text,
    required this.icon,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bgColor =
        backgroundColor ?? (isDark ? AppTheme.darkBg2 : AppTheme.lightBg2);
    final txtColor = textColor ?? context.textSecondaryColor;
    final icnColor = iconColor ?? AppTheme.primaryGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: icnColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: txtColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
