import 'package:flutter/material.dart';
import '../../utils/utils.dart';

/// A reusable row widget for displaying label-value pairs with an icon
class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final double? iconSize;
  final double? fontSize;
  final EdgeInsets? padding;

  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.iconSize,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Padding(
      padding: padding ?? EdgeInsets.only(bottom: SizeConfig.spaceMedium),
      child: Row(
        children: [
          Icon(
            icon,
            size: iconSize ?? SizeConfig.iconSizeMedium,
            color: iconColor ?? AppTheme.primaryGreen,
          ),
          SizedBox(width: SizeConfig.spaceMedium),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: fontSize ?? SizeConfig.fontSizeRegular,
              color: context.textSecondaryColor,
            ),
          ),
          SizedBox(width: SizeConfig.spaceSmall),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: fontSize ?? SizeConfig.fontSizeRegular,
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
