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
        Icon(icon, color: color, size: SizeConfig.iconSizeLarge),
        SizedBox(width: SizeConfig.spaceSmall),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: SizeConfig.fontSizeXLarge,
              fontWeight: FontWeight.w700,
              color: context.textPrimaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
