import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/utils.dart';
import '../../l10n/l10n.dart';

/// Compact dashboard header widget - minimal info, full details in profile
class DashboardHeader extends StatelessWidget {
  final UserModel? user;
  final Map<String, dynamic>? statistics;
  final VoidCallback onRefresh;

  const DashboardHeader({
    super.key,
    this.user,
    this.statistics,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize SizeConfig
    SizeConfig.init(context);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.spaceSmall),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryGreen.withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildCompactUserInfo(context),
          SizedBox(height: SizeConfig.spaceSmall - 2),
          _buildStatisticsRow(context),
        ],
      ),
    );
  }

  Widget _buildCompactUserInfo(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.spaceSmall),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(SizeConfig.radiusMedium),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 36.0,
            height: 36.0,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(SizeConfig.radiusMedium),
            ),
            child: Center(
              child: Text(
                (user?.name != null && user!.name.isNotEmpty)
                    ? user!.name.substring(0, 1).toUpperCase()
                    : 'U',
                style: SizeConfig.getTextStyle(
                  fontSize: SizeConfig.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ),
          SizedBox(width: SizeConfig.spaceSmall),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user?.name ?? 'User',
                        style: SizeConfig.getTextStyle(
                          fontSize: SizeConfig.fontSizeRegular,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                      ),
                    ),
                    SizedBox(width: SizeConfig.spaceSmall - 2),
                    // Role Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.spaceSmall - 2,
                        vertical: 1.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(SizeConfig.radiusSmall + 1),
                      ),
                      child: Text(
                        (user?.role ?? 'user').toUpperCase(),
                        style: SizeConfig.getTextStyle(
                          fontSize: SizeConfig.fontSizeXSmall,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.spaceTiny),
                // Show hierarchy in one line
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _getHierarchyText(),
                    style: SizeConfig.getTextStyle(
                      fontSize: SizeConfig.fontSizeSmall - 1,
                      color: context.textSecondaryColor,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getHierarchyText() {
    List<String> parts = [];

    if (user?.societyName != null) {
      parts.add(user!.societyName!);
    }
    if (user?.presidentName != null && user!.presidentName!.isNotEmpty) {
      parts.add(user!.presidentName!);
    }

    if (parts.isEmpty) {
      return user?.email ?? '';
    }

    return parts.join(' • ');
  }

  Widget _buildStatisticsRow(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return Container(
      padding: EdgeInsets.all(SizeConfig.spaceSmall),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen.withValues(alpha: isDark ? 0.08 : 0.05),
            AppTheme.primaryGreen.withValues(alpha: isDark ? 0.03 : 0.01),
          ],
        ),
        borderRadius: BorderRadius.circular(SizeConfig.radiusMedium),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: SizeConfig.iconSizeSmall - 2,
                color: AppTheme.primaryGreen,
              ),
              SizedBox(width: SizeConfig.spaceXSmall),
              Text(
                AppLocalizations().tr('last_30_days'),
                style: SizeConfig.getTextStyle(
                  fontSize: SizeConfig.fontSizeXSmall,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onRefresh,
                borderRadius: BorderRadius.circular(SizeConfig.radiusSmall),
                child: Padding(
                  padding: EdgeInsets.all(SizeConfig.spaceTiny + 1),
                  child: Icon(
                    Icons.refresh,
                    size: SizeConfig.iconSizeXSmall,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.spaceSmall - 2),
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  AppLocalizations().tr('revenue'),
                  '₹${_formatNumber(statistics?['totalRevenue30Days'] ?? 0)}',
                  Icons.currency_rupee,
                ),
              ),
              _buildDivider(context),
              Expanded(
                child: _buildStatItem(
                  context,
                  AppLocalizations().tr('collection'),
                  '${_formatNumber(statistics?['totalCollection30Days'] ?? 0)} L',
                  Icons.water_drop_outlined,
                ),
              ),
              _buildDivider(context),
              Expanded(
                child: _buildStatItem(
                  context,
                  AppLocalizations().tr('fat'),
                  '${(statistics?['avgFat'] ?? 0).toStringAsFixed(1)}%',
                  Icons.opacity,
                ),
              ),
              _buildDivider(context),
              Expanded(
                child: _buildStatItem(
                  context,
                  AppLocalizations().tr('snf'),
                  '${(statistics?['avgSnf'] ?? 0).toStringAsFixed(1)}%',
                  Icons.water,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1.0,
      height: 24.0,
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.spaceXSmall),
      color: context.borderColor,
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: SizeConfig.iconSizeXSmall,
          color: AppTheme.primaryGreen.withValues(alpha: 0.7),
        ),
        SizedBox(height: 1.0),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: SizeConfig.getTextStyle(
              fontSize: SizeConfig.fontSizeSmall - 1,
              fontWeight: FontWeight.w700,
              color: context.textPrimaryColor,
            ),
            maxLines: 1,
          ),
        ),
        Text(
          label,
          style: SizeConfig.getTextStyle(
            fontSize: 8.0,
            color: context.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    double num = (value is double)
        ? value
        : double.tryParse(value.toString()) ?? 0;

    if (num >= 100000) {
      return '${(num / 100000).toStringAsFixed(1)}L';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return num.toStringAsFixed(0);
  }
}
