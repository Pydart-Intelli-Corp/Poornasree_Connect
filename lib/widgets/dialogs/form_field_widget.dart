import 'package:flutter/material.dart';
import '../../utils/helpers/size_config.dart';
import '../../utils/utils.dart';

/// A reusable form field widget for dialogs
class FormFieldWidget extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool enabled;
  final String? hint;
  final TextInputType keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const FormFieldWidget({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.enabled = true,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final isDark = context.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: SizeConfig.fontSizeRegular + 2,
            fontWeight: FontWeight.w500,
            color: context.textSecondaryColor,
          ),
        ),
        SizedBox(height: SizeConfig.spaceSmall),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(
            fontSize: SizeConfig.fontSizeRegular,
            color: enabled
                ? context.textPrimaryColor
                : context.textSecondaryColor.withOpacity(0.5),
          ),
          decoration: InputDecoration(
            hintText: hint ?? 'Enter $label',
            hintStyle: TextStyle(
              color: context.textSecondaryColor.withOpacity(0.5),
              fontSize: SizeConfig.fontSizeRegular,
            ),
            prefixIcon: Icon(
              icon,
              color: enabled
                  ? (isDark
                        ? AppTheme.primaryGreen
                        : AppTheme.primaryGreen.withOpacity(0.8))
                  : context.textSecondaryColor.withOpacity(0.5),
              size: SizeConfig.iconSizeMedium,
            ),
            filled: true,
            fillColor: enabled
                ? (isDark ? AppTheme.darkBg2 : const Color(0xFFF5F5F5))
                : context.surfaceColor.withOpacity(0.5),
            contentPadding: EdgeInsets.symmetric(
              horizontal: SizeConfig.spaceRegular,
              vertical: SizeConfig.spaceRegular - 2,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SizeConfig.radiusRegular),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SizeConfig.radiusRegular),
              borderSide: BorderSide(
                color: isDark
                    ? context.borderColor.withOpacity(0.5)
                    : const Color(0xFFE0E0E0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SizeConfig.radiusRegular),
              borderSide: BorderSide(
                color: isDark
                    ? AppTheme.primaryGreen
                    : AppTheme.primaryGreen.withOpacity(0.8),
                width: 1.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SizeConfig.radiusRegular),
              borderSide: BorderSide(
                color: isDark
                    ? context.borderColor.withOpacity(0.3)
                    : const Color(0xFFE0E0E0).withOpacity(0.5),
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SizeConfig.radiusRegular),
              borderSide: BorderSide(
                color: isDark ? Colors.red : Colors.red.shade700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
