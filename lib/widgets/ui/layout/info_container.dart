import 'package:flutter/material.dart';
import '../../../utils/utils.dart';
import '../../../utils/helpers/size_config.dart';

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
    SizeConfig.init(context);
    final isDark = context.isDarkMode;
    final bgColor =
        backgroundColor ?? (isDark ? AppTheme.darkBg2 : AppTheme.lightBg2);
    final txtColor = textColor ?? context.textSecondaryColor;
    final icnColor = iconColor ?? AppTheme.primaryGreen;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.radiusLarge,
        vertical: SizeConfig.spaceRegular - 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(
          borderRadius ?? SizeConfig.radiusRegular,
        ),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: SizeConfig.normalize(1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(SizeConfig.spaceSmall),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(SizeConfig.radiusSmall),
            ),
            child: Icon(icon, color: icnColor, size: SizeConfig.iconSizeMedium),
          ),
          SizedBox(width: SizeConfig.spaceMedium),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: txtColor,
                fontSize: SizeConfig.fontSizeSmall,
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
