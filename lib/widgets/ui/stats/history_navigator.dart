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
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.spaceSmall, vertical: SizeConfig.spaceXSmall),
      decoration: BoxDecoration(
        color: isViewingHistory
            ? const Color(0xFF3b82f6).withOpacity(0.15)
            : context.surfaceColor,
        borderRadius: BorderRadius.circular(SizeConfig.spaceMedium),
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
              padding: EdgeInsets.all(SizeConfig.spaceXSmall),
              decoration: BoxDecoration(
                color: historyIndex < historyCount - 1
                    ? const Color(0xFF3b82f6).withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                size: SizeConfig.iconSizeSmall,
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
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.spaceSmall, vertical: 1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isViewingHistory) ...[
                    Icon(
                      Icons.history_rounded,
                      size: SizeConfig.iconSizeSmall,
                      color: Color(0xFF3b82f6),
                    ),
                    SizedBox(width: SizeConfig.spaceXSmall),
                  ],
                  Text(
                    isViewingHistory
                        ? '$currentPosition/$historyCount'
                        : AppLocalizations().tr('live'),
                    style: TextStyle(
                      fontSize: SizeConfig.fontSizeXSmall,
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
              padding: EdgeInsets.all(SizeConfig.spaceXSmall),
              decoration: BoxDecoration(
                color: historyIndex > 0
                    ? const Color(0xFF3b82f6).withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: SizeConfig.iconSizeSmall,
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
