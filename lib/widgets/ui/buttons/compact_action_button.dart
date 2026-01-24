import 'package:flutter/material.dart';
import '../../../utils/helpers/size_config.dart';

/// Compact pill-shaped button with icon and text
/// Used for quick actions like Reports, Clear, etc.
class CompactActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const CompactActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(SizeConfig.spaceMedium),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.spaceTiny,
            vertical: SizeConfig.spaceTiny,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(SizeConfig.spaceMedium),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(SizeConfig.spaceTiny),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
                ),
                child: Icon(
                  icon,
                  size: SizeConfig.iconSizeSmall,
                  color: color,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.spaceXSmall,
                  vertical: 1,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: SizeConfig.fontSizeXSmall,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
