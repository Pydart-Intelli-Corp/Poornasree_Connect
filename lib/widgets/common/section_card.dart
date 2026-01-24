import 'package:flutter/material.dart';
import '../../utils/utils.dart';

/// A reusable section card with title and content
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding ?? EdgeInsets.all(SizeConfig.spaceRegular),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(SizeConfig.spaceRegular),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: SizeConfig.fontSizeMedium,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: SizeConfig.spaceSmall),
                trailing!,
              ],
            ],
          ),
          SizedBox(height: SizeConfig.spaceRegular),
          child,
        ],
      ),
    );
  }
}
