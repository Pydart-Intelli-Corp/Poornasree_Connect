import 'package:flutter/material.dart';
import '../../../utils/utils.dart';

class PremiumIconContainer extends StatelessWidget {
  final Widget child;
  final double? size;
  final double? borderRadius;
  final Color? shadowColor;
  final String? heroTag;

  const PremiumIconContainer({
    super.key,
    required this.child,
    this.size,
    this.borderRadius,
    this.shadowColor,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      width: size ?? 120,
      height: size ?? 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius ?? 32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: (shadowColor ?? AppTheme.primaryGreen).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(size != null ? size! * 0.166 : 20),
      child: child,
    );

    if (heroTag != null) {
      return Hero(tag: heroTag!, child: container);
    }
    return container;
  }
}
