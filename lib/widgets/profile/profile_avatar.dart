import 'package:flutter/material.dart';
import '../../utils/utils.dart';

/// A reusable profile avatar widget
class ProfileAvatar extends StatelessWidget {
  final String? name;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final bool showShadow;

  const ProfileAvatar({
    super.key,
    this.name,
    this.size = 100,
    this.borderColor,
    this.borderWidth = 3,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = borderColor ?? AppTheme.primaryGreen;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(size * 0.2),
        border: Border.all(color: color.withOpacity(0.5), width: borderWidth),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: name != null && name!.isNotEmpty
            ? Text(
                name!.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              )
            : Icon(Icons.person, size: size * 0.5, color: color),
      ),
    );
  }
}

/// A role badge widget
class RoleBadge extends StatelessWidget {
  final String role;
  final Color? color;
  final double fontSize;

  const RoleBadge({
    super.key,
    required this.role,
    this.color,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? AppTheme.primaryGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: badgeColor,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
