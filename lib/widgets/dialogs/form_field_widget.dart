import 'package:flutter/material.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(
            fontSize: 15,
            color: enabled ? AppTheme.textPrimary : AppTheme.textTertiary,
          ),
          decoration: InputDecoration(
            hintText: hint ?? 'Enter $label',
            hintStyle: TextStyle(
              color: AppTheme.textTertiary.withOpacity(0.5),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: enabled ? AppTheme.primaryGreen : AppTheme.textTertiary,
              size: 20,
            ),
            filled: true,
            fillColor: enabled
                ? AppTheme.darkBg2
                : AppTheme.cardDark.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.borderDark.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryGreen,
                width: 1.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.borderDark.withOpacity(0.3),
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}
