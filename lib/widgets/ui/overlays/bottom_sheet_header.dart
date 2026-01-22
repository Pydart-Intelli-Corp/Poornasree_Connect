import 'package:flutter/material.dart';
import '../../../utils/utils.dart';

/// A styled bottom sheet header with icon and title
class BottomSheetHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const BottomSheetHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}
