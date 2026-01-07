import 'package:flutter/material.dart';
import '../../../utils/utils.dart';

class PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Color? iconBackgroundColor;
  final Color? iconColor;

  const PremiumTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.iconBackgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg2 : AppTheme.lightBg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: context.textPrimaryColor,
          letterSpacing: 0.3,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: context.textSecondaryColor,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            color: context.textSecondaryColor.withOpacity(0.5),
            fontSize: 14,
            letterSpacing: 0.3,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBackgroundColor ??
                  AppTheme.primaryGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? AppTheme.primaryGreen,
              size: 18,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        validator: validator,
      ),
    );
  }
}
