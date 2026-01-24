import 'package:flutter/material.dart';
import '../../../utils/utils.dart';
import '../../../utils/helpers/size_config.dart';

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
    SizeConfig.init(context);
    final isDark = context.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg2 : AppTheme.lightBg2,
        borderRadius: BorderRadius.circular(SizeConfig.radiusRegular),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: SizeConfig.fontSizeRegular,
          fontWeight: FontWeight.w500,
          color: context.textPrimaryColor,
          letterSpacing: 0.3,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: context.textSecondaryColor,
            fontSize: SizeConfig.fontSizeRegular + 2,
            letterSpacing: 0.3,
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            color: context.textSecondaryColor.withOpacity(0.5),
            fontSize: SizeConfig.fontSizeRegular,
            letterSpacing: 0.3,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(SizeConfig.spaceSmall),
            padding: EdgeInsets.all(SizeConfig.spaceSmall),
            decoration: BoxDecoration(
              color:
                  iconBackgroundColor ??
                  AppTheme.primaryGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(SizeConfig.radiusSmall),
            ),
            child: Icon(
              icon,
              color: iconColor ?? AppTheme.primaryGreen,
              size: SizeConfig.iconSizeMedium - 2,
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: SizeConfig.spaceRegular,
            vertical: SizeConfig.spaceRegular + 2,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        validator: validator,
      ),
    );
  }
}
