import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/utils.dart';

/// A history navigator widget with previous/next buttons and position indicator
class HistoryNavigator extends StatelessWidget {
  final int historyCount;
  final int historyIndex;
  final bool isViewingHistory;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onGoToLive;

  const HistoryNavigator({
    super.key,
    required this.historyCount,
    required this.historyIndex,
    required this.isViewingHistory,
    required this.onPrevious,
    required this.onNext,
    required this.onGoToLive,
  });

  @override
  Widget build(BuildContext context) {
    final currentPosition =
        historyCount - historyIndex; // 1-based position from oldest

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isViewingHistory
            ? const Color(0xFF3b82f6).withOpacity(0.15)
            : context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isViewingHistory
              ? const Color(0xFF3b82f6).withOpacity(0.5)
              : context.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Previous button (go to older)
          GestureDetector(
            onTap: historyIndex < historyCount - 1 ? onPrevious : null,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: historyIndex < historyCount - 1
                    ? const Color(0xFF3b82f6).withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 14,
                color: historyIndex < historyCount - 1
                    ? const Color(0xFF3b82f6)
                    : context.textSecondaryColor,
              ),
            ),
          ),

          // Position indicator
          GestureDetector(
            onTap: isViewingHistory ? onGoToLive : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isViewingHistory) ...[
                    const Icon(
                      Icons.history_rounded,
                      size: 10,
                      color: Color(0xFF3b82f6),
                    ),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    isViewingHistory
                        ? '$currentPosition/$historyCount'
                        : AppLocalizations().tr('live'),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isViewingHistory
                          ? const Color(0xFF3b82f6)
                          : const Color(0xFF10B981),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Next button (go to newer / live)
          GestureDetector(
            onTap: historyIndex > 0 ? onNext : null,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: historyIndex > 0
                    ? const Color(0xFF3b82f6).withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: historyIndex > 0
                    ? const Color(0xFF3b82f6)
                    : context.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
