import 'package:flutter/material.dart';
import '../../utils/utils.dart';

/// A reusable profile avatar widget
class ProfileAvatar extends StatelessWidget {
  final String? name;
  final double? size;
  final Color? borderColor;
  final double? borderWidth;
  final bool showShadow;

  const ProfileAvatar({
    super.key,
    this.name,
    this.size,
    this.borderColor,
    this.borderWidth,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final avatarSize = size ?? SizeConfig.normalize(100.0);
    final border = borderWidth ?? SizeConfig.normalize(3.0);
    final color = borderColor ?? AppTheme.primaryGreen;

    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(avatarSize * 0.2),
        border: Border.all(color: color.withOpacity(0.5), width: border),
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
                  fontSize: avatarSize * 0.4,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              )
            : Icon(Icons.person, size: avatarSize * 0.5, color: color),
      ),
    );
  }
}

/// A role badge widget
class RoleBadge extends StatelessWidget {
  final String role;
  final Color? color;
  final double? fontSize;

  const RoleBadge({super.key, required this.role, this.color, this.fontSize});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final badgeColor = color ?? AppTheme.primaryGreen;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.spaceRegular,
        vertical: SizeConfig.spaceXSmall + 2,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(SizeConfig.spaceLarge),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: fontSize ?? SizeConfig.fontSizeSmall,
          fontWeight: FontWeight.w600,
          color: badgeColor,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
