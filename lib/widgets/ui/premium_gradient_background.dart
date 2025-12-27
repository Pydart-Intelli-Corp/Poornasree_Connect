import 'package:flutter/material.dart';
import '../../utils/utils.dart';

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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors ?? [
            const Color(0xFF1A5F3A),
            const Color(0xFF2D8B5E),
            AppTheme.primaryTeal,
          ],
          stops: stops ?? const [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}
