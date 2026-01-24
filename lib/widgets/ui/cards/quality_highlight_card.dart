import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../stats/stat_widgets.dart';
import '../../../utils/utils.dart';

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

  String _formatFarmerId(String id) {
    final result = id.replaceFirst(RegExp(r'^0+'), '');
    return result.isEmpty ? '0' : result;
  }

  @override
  Widget build(BuildContext context) {
    final displayEmptyMessage = emptyMessage ?? AppLocalizations().tr('no_data_yet');
    final isDark = context.isDarkMode;

    return Expanded(
      child: Container(
        padding: EdgeInsets.all(SizeConfig.spaceRegular),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(isDark ? 0.15 : 0.08),
              color.withOpacity(isDark ? 0.08 : 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(SizeConfig.spaceRegular),
          border: Border.all(
            color: color.withOpacity(isDark ? 0.4 : 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge with title
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(SizeConfig.spaceSmall),
                  decoration: BoxDecoration(
                    color: color.withOpacity(isDark ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: SizeConfig.iconSizeMedium,
                    color: color,
                  ),
                ),
                SizedBox(width: SizeConfig.spaceSmall),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: SizeConfig.fontSizeSmall,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.fade,
                  ),
                ),
              ],
            ),
            if (hasData) ...[
              SizedBox(height: SizeConfig.spaceRegular),
              // Farmer info with prominent display
              Container(
                padding: EdgeInsets.all(SizeConfig.spaceSmall),
                decoration: BoxDecoration(
                  color: context.surfaceColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(SizeConfig.spaceXSmall),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: SizeConfig.iconSizeSmall,
                        color: color,
                      ),
                    ),
                    SizedBox(width: SizeConfig.spaceSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations().tr('farmer').toUpperCase(),
                            style: TextStyle(
                              fontSize: SizeConfig.fontSizeXSmall - 1,
                              fontWeight: FontWeight.w600,
                              color: context.textSecondaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: SizeConfig.spaceTiny),
                          Text(
                            farmerId != null ? _formatFarmerId(farmerId!) : '--',
                            style: TextStyle(
                              fontSize: SizeConfig.fontSizeMedium,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.spaceSmall),
              // FAT & SNF values in modern cards
              Row(
                children: [
                  if (fatValue != null)
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.spaceSmall,
                          vertical: SizeConfig.spaceXSmall,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFf59e0b).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
                          border: Border.all(
                            color: const Color(0xFFf59e0b).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              AppLocalizations().tr('fat').toUpperCase(),
                              style: TextStyle(
                                fontSize: SizeConfig.fontSizeXSmall - 1,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFf59e0b),
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: SizeConfig.spaceTiny),
                            Text(
                              '${fatValue!.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: SizeConfig.fontSizeMedium,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFf59e0b),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (fatValue != null && snfValue != null)
                    SizedBox(width: SizeConfig.spaceSmall),
                  if (snfValue != null)
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.spaceSmall,
                          vertical: SizeConfig.spaceXSmall,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8b5cf6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
                          border: Border.all(
                            color: const Color(0xFF8b5cf6).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              AppLocalizations().tr('snf').toUpperCase(),
                              style: TextStyle(
                                fontSize: SizeConfig.fontSizeXSmall - 1,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF8b5cf6),
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: SizeConfig.spaceTiny),
                            Text(
                              '${snfValue!.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: SizeConfig.fontSizeMedium,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF8b5cf6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              if (machineId != null && machineId!.isNotEmpty) ...[
                SizedBox(height: SizeConfig.spaceSmall),
                Row(
                  children: [
                    Icon(
                      Icons.precision_manufacturing_rounded,
                      size: SizeConfig.iconSizeXSmall,
                      color: context.textSecondaryColor,
                    ),
                    SizedBox(width: SizeConfig.spaceTiny),
                    Text(
                      machineId!,
                      style: TextStyle(
                        fontSize: SizeConfig.fontSizeXSmall,
                        fontWeight: FontWeight.w600,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ] else ...[
              SizedBox(height: SizeConfig.spaceRegular),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: SizeConfig.iconSizeLarge,
                      color: context.textSecondaryColor.withOpacity(0.5),
                    ),
                    SizedBox(height: SizeConfig.spaceSmall),
                    Text(
                      displayEmptyMessage,
                      style: TextStyle(
                        fontSize: SizeConfig.fontSizeSmall,
                        color: context.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}