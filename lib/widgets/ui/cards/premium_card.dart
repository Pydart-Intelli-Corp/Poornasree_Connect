import 'package:flutter/material.dart';
import '../../../utils/utils.dart';
import '../../../utils/helpers/size_config.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Container(
      padding: padding ?? EdgeInsets.all(SizeConfig.spaceRegular + 4),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(
          borderRadius ?? SizeConfig.radiusRegular,
        ),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: SizeConfig.normalize(1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.05),
            blurRadius: SizeConfig.normalize(20),
            spreadRadius: 0,
            offset: Offset(0, SizeConfig.normalize(4)),
          ),
        ],
      ),
      child: child,
    );
  }
}
