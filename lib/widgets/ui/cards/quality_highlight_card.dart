import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../stats/stat_widgets.dart';

/// A card highlighting quality metrics (Best/Worst quality)
/// Used in statistics summary to show top/bottom performers
class QualityHighlightCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String? farmerLabel;
  final String? farmerId;
  final double? fatValue;
  final double? snfValue;
  final String? machineId;
  final String? emptyMessage;

  const QualityHighlightCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.farmerLabel,
    this.farmerId,
    this.fatValue,
    this.snfValue,
    this.machineId,
    this.emptyMessage,
  });

  bool get hasData => farmerId != null && farmerId!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayEmptyMessage = emptyMessage ?? AppLocalizations().tr('no_data_yet');

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            if (hasData) ...[
              const SizedBox(height: 8),
              // Farmer info row
              Row(
                children: [
                  Icon(
                    Icons.person_rounded,
                    size: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      farmerLabel ?? '${AppLocalizations().tr('farmer')} $farmerId',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // FAT/SNF mini stats
              Row(
                children: [
                  if (fatValue != null)
                    MiniStat(
                      label: AppLocalizations().tr('fat').toUpperCase(),
                      value: fatValue!.toStringAsFixed(1),
                      color: const Color(0xFFf59e0b),
                    ),
                  if (fatValue != null && snfValue != null)
                    const SizedBox(width: 8),
                  if (snfValue != null)
                    MiniStat(
                      label: AppLocalizations().tr('snf').toUpperCase(),
                      value: snfValue!.toStringAsFixed(1),
                      color: const Color(0xFF8b5cf6),
                    ),
                ],
              ),
              if (machineId != null && machineId!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  machineId!,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                ),
              ],
            ] else ...[
              const SizedBox(height: 8),
              Text(
                displayEmptyMessage,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
