import 'package:flutter/material.dart';

/// Transaction card types for icon and max value determination
enum TransactionType { quantity, rate }

/// A transaction card with animated value and progress bar
/// Used for displaying Quantity and Rate
class TransactionCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color color;
  final double maxValue;
  final TransactionType type;

  const TransactionCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
    this.maxValue = 50.0,
    this.type = TransactionType.quantity,
  });

  @override
  Widget build(BuildContext context) {
    final numericStr = value.replaceAll(RegExp(r'[^0-9.]'), '');
    final double numValue = double.tryParse(numericStr) ?? 0.0;
    final double effectiveMaxValue = type == TransactionType.quantity
        ? 50
        : 100;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = numValue > 0;

    // Icon based on type
    IconData icon = type == TransactionType.quantity
        ? Icons.water_drop_rounded
        : Icons.currency_rupee_rounded;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: numValue),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        final progress = (animatedValue / effectiveMaxValue).clamp(0.0, 1.0);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isActive
                  ? [
                      color.withValues(alpha: isDark ? 0.2 : 0.08),
                      color.withValues(alpha: isDark ? 0.1 : 0.03),
                    ]
                  : isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFFFAFBFC), const Color(0xFFF1F5F9)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? (isDark ? color.withValues(alpha: 0.6) : color.withValues(alpha: 0.35))
                  : (isDark ? color.withValues(alpha: 0.2) : const Color(0xFFD1D5DB)),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: isDark ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.12),
                      blurRadius: isDark ? 12 : 6,
                      offset: Offset(0, isDark ? 4 : 2),
                      spreadRadius: 0,
                    ),
                  ]
                : isDark ? null : [
                    BoxShadow(
                      color: const Color(0xFF000000).withOpacity(0.03),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              // Glow effect at top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isActive ? 1.0 : 0.0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          color.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title with icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            icon,
                            key: ValueKey(isActive),
                            size: 10,
                            color: isActive
                                ? color
                                : (isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade400),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          title.toUpperCase(),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? color
                                : (isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade500),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Large centered value
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            value.contains('₹')
                                ? '₹${animatedValue.toStringAsFixed(2)}'
                                : animatedValue.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: isActive
                                  ? (isDark ? Colors.white : color)
                                  : (isDark
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade400),
                              letterSpacing: -0.5,
                              shadows: isActive
                                  ? [
                                      Shadow(
                                        color: color.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          if (unit.isNotEmpty)
                            Text(
                              unit,
                              style: TextStyle(
                                fontSize: 11,
                                color: isActive
                                    ? color.withValues(alpha: 0.8)
                                    : (isDark
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade500),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Progress indicator with percentage
                    Column(
                      children: [
                        // Progress bar
                        Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF374151)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Stack(
                              children: [
                                FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: progress,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          color.withValues(alpha: 0.6),
                                          color,
                                        ],
                                      ),
                                      boxShadow: isActive
                                          ? [
                                              BoxShadow(
                                                color: color.withValues(
                                                  alpha: 0.5,
                                                ),
                                                blurRadius: 6,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
