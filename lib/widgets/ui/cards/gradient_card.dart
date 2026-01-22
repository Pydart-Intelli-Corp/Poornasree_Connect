import 'package:flutter/material.dart';
import '../../../utils/utils.dart';

/// A container with gradient background commonly used for stats cards
class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const GradientCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, context.surfaceColor],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: context.borderColor,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
