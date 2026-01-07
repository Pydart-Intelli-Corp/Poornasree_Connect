import 'package:flutter/material.dart';
import '../../../utils/utils.dart';

/// A styled section label with colored accent bar
class SectionLabel extends StatelessWidget {
  final String label;
  final Color? accentColor;

  const SectionLabel({super.key, required this.label, this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: accentColor ?? AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey[600],
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
