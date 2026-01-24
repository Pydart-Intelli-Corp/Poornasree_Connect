import 'package:flutter/material.dart';
import '../../../utils/utils.dart';
import '../../../utils/helpers/size_config.dart';
import '../feedback/flower_spinner.dart';

class PremiumGradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? height;
  final double? borderRadius;
  final List<Color>? gradientColors;

  const PremiumGradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height,
    this.borderRadius,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final effectiveHeight = height ?? SizeConfig.normalize(58);
    final effectiveRadius = borderRadius ?? SizeConfig.radiusRegular;

    return Container(
      height: effectiveHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              gradientColors ?? [AppTheme.primaryGreen, AppTheme.primaryTeal],
        ),
        borderRadius: BorderRadius.circular(effectiveRadius),
        boxShadow: [
          BoxShadow(
            color: (gradientColors?.first ?? AppTheme.primaryGreen).withOpacity(
              0.4,
            ),
            blurRadius: SizeConfig.normalize(20),
            offset: Offset(0, SizeConfig.normalize(10)),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: Center(
            child: isLoading
                ? FlowerSpinner(
                    size: SizeConfig.iconSizeLarge,
                    color: Colors.white,
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        text,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: SizeConfig.fontSizeRegular + 1,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (icon != null) ...[
                        SizedBox(width: SizeConfig.spaceSmall),
                        Icon(
                          icon,
                          color: Colors.white,
                          size: SizeConfig.iconSizeMedium,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
