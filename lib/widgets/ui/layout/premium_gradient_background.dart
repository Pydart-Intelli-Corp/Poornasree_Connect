import 'package:flutter/material.dart';
import '../../../utils/utils.dart';

class PremiumGradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final List<double>? stops;

  const PremiumGradientBackground({
    super.key,
    required this.child,
    this.colors,
    this.stops,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors ?? (isDark
            ? [
                AppTheme.darkBg,
                AppTheme.darkBg2,
                AppTheme.darkBg3,
              ]
            : [
                AppTheme.lightBg,
                AppTheme.lightBg2,
                AppTheme.lightBg3,
              ]),
          stops: stops ?? const [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}
