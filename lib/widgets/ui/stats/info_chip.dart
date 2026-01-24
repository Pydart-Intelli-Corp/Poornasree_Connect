import 'package:flutter/material.dart';
import '../../../utils/utils.dart';
import '../../../utils/helpers/size_config.dart';

/// Info chip types for value formatting determination
enum InfoChipType { milkType, protein, lactose, salt, water, temp }

/// A compact info chip widget with icon, title, value and progress bar
/// Used for displaying parameters like Protein, Lactose, Salt, Water, Temperature
class InfoChip extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double maxValue;
  final InfoChipType type;

  const InfoChip({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.maxValue = 10.0,
    this.type = InfoChipType.protein,
  });

  @override
  Widget build(BuildContext context) {
    // Extract numeric value for progress calculation
    final numericStr = value.replaceAll(RegExp(r'[^0-9.]'), '');
    final double numValue = double.tryParse(numericStr) ?? 0.0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = numValue > 0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: numValue),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        final progress = (animatedValue / maxValue).clamp(0.0, 1.0);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFFF9FAFB), context.surfaceColor],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? (isDark ? color.withOpacity(0.3) : color.withOpacity(0.2))
                  : context.borderColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? (isDark ? color.withOpacity(0.15) : color.withOpacity(0.08))
                    : (isDark ? Colors.black.withOpacity(0.05) : const Color(0xFF000000).withOpacity(0.03)),
                blurRadius: isActive ? (isDark ? 10 : 5) : 3,
                offset: Offset(0, isActive ? 2 : 1),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(SizeConfig.spaceSmall),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with icon and title
                Row(
                  children: [
                    // Animated icon container
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.all(SizeConfig.spaceXSmall),
                      decoration: BoxDecoration(
                        color: color.withOpacity(isActive ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
                      ),
                      child: Icon(
                        icon,
                        color: isActive ? color : color.withOpacity(0.5),
                        size: SizeConfig.iconSizeSmall,
                      ),
                    ),
                    SizedBox(width: SizeConfig.spaceXSmall),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: SizeConfig.fontSizeXSmall,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondaryColor,
                          letterSpacing: 0.5,
                        ),
                        softWrap: true,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Animated value
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: isActive ? SizeConfig.fontSizeMedium : SizeConfig.fontSizeRegular,
                    fontWeight: FontWeight.w800,
                    color: isActive
                        ? color
                        : context.textSecondaryColor,
                  ),
                  child: Text(
                    type == InfoChipType.milkType
                        ? value
                        : (type == InfoChipType.temp
                              ? '${animatedValue.toStringAsFixed(1)}°C'
                              : '${animatedValue.toStringAsFixed(2)}%'),
                  ),
                ),
                SizedBox(height: SizeConfig.spaceXSmall),
                // Animated line progress indicator
                Stack(
                  children: [
                    // Background track
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Animated progress bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      height: 4,
                      width: double.infinity,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: type == InfoChipType.milkType
                            ? 1.0
                            : progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withOpacity(0.7)],
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.5),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
