import 'package:flutter/material.dart';
import '../../../utils/utils.dart';
import '../../../utils/helpers/size_config.dart';

/// A styled section label with colored accent bar
class SectionLabel extends StatelessWidget {
  final String label;
  final Color? accentColor;

  const SectionLabel({super.key, required this.label, this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: SizeConfig.spaceTiny + 2,
          height: SizeConfig.iconSizeMedium,
          decoration: BoxDecoration(
            color: accentColor ?? AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(SizeConfig.spaceTiny),
          ),
        ),
        SizedBox(width: SizeConfig.spaceSmall),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: SizeConfig.fontSizeSmall,
              fontWeight: FontWeight.w700,
              color: context.textSecondaryColor,
              letterSpacing: 1.2,
            ),
            softWrap: true,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
