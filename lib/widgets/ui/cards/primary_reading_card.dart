import 'package:flutter/material.dart';
import 'package:poornasree_connect/l10n/app_localizations.dart';

/// A primary reading card with circular progress indicator
/// Used for displaying FAT, SNF, CLR values
class PrimaryReadingCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color color;
  final double maxValue;
  final bool isViewingHistory;

  const PrimaryReadingCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
    this.maxValue = 15.0,
    this.isViewingHistory = false,
  });

  @override
  Widget build(BuildContext context) {
    final double numValue = double.tryParse(value) ?? 0.0;
    final double effectiveMaxValue = title == 'CLR' ? 100 : maxValue;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = numValue > 0;

    // Icon based on title
    IconData icon = title == 'FAT'
        ? Icons.opacity_rounded
        : title == 'SNF'
        ? Icons.grain_rounded
        : Icons.colorize_rounded;

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
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isActive
                  ? [
                      color.withValues(alpha: isDark ? 0.25 : 0.12),
                      color.withValues(alpha: isDark ? 0.1 : 0.04),
                    ]
                  : isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? (isDark ? color.withValues(alpha: 0.7) : color.withValues(alpha: 0.4))
                  : (isDark ? color.withValues(alpha: 0.2) : const Color(0xFFCBD5E1)),
              width: isActive ? 2.5 : 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: isDark ? color.withValues(alpha: 0.4) : color.withValues(alpha: 0.15),
                      blurRadius: isDark ? 16 : 8,
                      offset: Offset(0, isDark ? 6 : 3),
                      spreadRadius: 0,
                    ),
                  ]
                : isDark ? null : [
                    BoxShadow(
                      color: const Color(0xFF000000).withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              // Top glow bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isActive ? 1.0 : 0.0,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, color, Colors.transparent],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                  ),
                ),
              ),
              // Main content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title with icon badge
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? (isActive
                                    ? color.withValues(alpha: 0.3)
                                    : const Color(0xFF374151))
                              : (isActive
                                    ? color.withValues(alpha: 0.2)
                                    : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? color.withValues(alpha: 0.5)
                                : (isDark
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade300),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 12,
                              color: isActive
                                  ? (isDark ? Colors.white : color)
                                  : (isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade600),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              unit.isNotEmpty ? '$title($unit)' : title,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isActive
                                    ? (isDark ? Colors.white : color)
                                    : (isDark
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade600),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Large centered value with circular progress
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer glow ring when active
                            if (isActive)
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      color.withValues(alpha: 0.15),
                                      color.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            // Background ring
                            SizedBox(
                              width: 75,
                              height: 75,
                              child: CircularProgressIndicator(
                                value: 1.0,
                                strokeWidth: 6,
                                backgroundColor: isDark
                                    ? const Color(0xFF374151)
                                    : Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark
                                      ? const Color(0xFF374151)
                                      : Colors.grey.shade200,
                                ),
                              ),
                            ),
                            // Progress ring
                            SizedBox(
                              width: 75,
                              height: 75,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 6,
                                strokeCap: StrokeCap.round,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  color,
                                ),
                              ),
                            ),
                            // Center value
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  animatedValue.toStringAsFixed(2),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: isActive
                                        ? (isDark ? Colors.white : color)
                                        : (isDark
                                              ? Colors.grey.shade600
                                              : Colors.grey.shade400),
                                    letterSpacing: -1,
                                    shadows: isActive
                                        ? [
                                            Shadow(
                                              color: color.withValues(
                                                alpha: 0.4,
                                              ),
                                              blurRadius: 10,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isViewingHistory
                              ? const Color(0xFFf59e0b).withValues(alpha: 0.2)
                              : (isActive
                                    ? const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.2)
                                    : Colors.grey.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isViewingHistory
                                    ? const Color(0xFFf59e0b)
                                    : (isActive
                                          ? const Color(0xFF10B981)
                                          : Colors.grey),
                                boxShadow: isViewingHistory || isActive
                                    ? [
                                        BoxShadow(
                                          color:
                                              (isViewingHistory
                                                      ? const Color(0xFFf59e0b)
                                                      : const Color(0xFF10B981))
                                                  .withValues(alpha: 0.6),
                                          blurRadius: 6,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isViewingHistory
                                  ? AppLocalizations().tr('past').toUpperCase()
                                  : (isActive
                                        ? AppLocalizations()
                                              .tr('live')
                                              .toUpperCase()
                                        : AppLocalizations()
                                              .tr('idle')
                                              .toUpperCase()),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: isViewingHistory
                                    ? const Color(0xFFf59e0b)
                                    : (isActive
                                          ? const Color(0xFF10B981)
                                          : Colors.grey),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
