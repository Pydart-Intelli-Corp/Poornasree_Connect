import 'package:flutter/material.dart';

class TransparentBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? borderRadius;

  const TransparentBackButton({
    super.key,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: iconColor ?? Colors.white,
        ),
        onPressed: onPressed ?? () => Navigator.of(context).pop(),
      ),
    );
  }
}
