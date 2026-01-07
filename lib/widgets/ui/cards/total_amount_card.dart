import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// A total amount card with animated value and status badge
class TotalAmountCard extends StatelessWidget {
  final double totalAmount;

  const TotalAmountCard({super.key, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = totalAmount > 0;
    const color = Color(0xFF10B981);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: totalAmount),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isActive
                  ? (isDark
                        ? [
                            const Color(0xFF1E293B),
                            color.withValues(alpha: 0.15),
                          ]
                        : [const Color(0xFFFFFFFF), color.withValues(alpha: 0.06)])
                  : (isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFF7F9FB), const Color(0xFFEEF2F6)]),
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? (isDark ? color.withValues(alpha: 0.6) : color.withValues(alpha: 0.4))
                  : (isDark ? Colors.grey.shade700 : const Color(0xFFD1D8E0)),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: isDark ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.15),
                      blurRadius: isDark ? 16 : 8,
                      offset: Offset(0, isDark ? 4 : 2),
                      spreadRadius: isDark ? 2 : 0,
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
              // Glowing accent bar at top (only when active)
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
                        colors: [color, color.withValues(alpha: 0.6), color],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title with icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isActive
                                ? color.withValues(alpha: 0.2)
                                : (isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.account_balance_wallet,
                              key: ValueKey(isActive),
                              color: isActive
                                  ? color
                                  : (isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade500),
                              size: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontSize: 10,
                            color: isActive
                                ? (isDark
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade600)
                                : (isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade400),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                          child: Text(
                            AppLocalizations().tr('total').toUpperCase(),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Animated amount
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontSize: isActive ? 24 : 20,
                          fontWeight: FontWeight.w900,
                          color: isActive
                              ? color
                              : (isDark
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade400),
                        ),
                        child: Text('₹${animatedValue.toStringAsFixed(2)}'),
                      ),
                    ),
                    const Spacer(),
                    // Status badge
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.symmetric(
                        horizontal: isActive ? 10 : 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? color.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: isActive ? 8 : 6,
                            height: isActive ? 8 : 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? color : Colors.grey,
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.6),
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isActive
                                ? AppLocalizations().tr('paid').toUpperCase()
                                : AppLocalizations()
                                      .tr('pending')
                                      .toUpperCase(),
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: isActive ? color : Colors.grey,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
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
