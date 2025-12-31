import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/utils.dart';

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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context, 16)),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryGreen.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildCompactUserInfo(context),
          const SizedBox(height: 16),
          _buildStatisticsRow(context),
        ],
      ),
    );
  }

  Widget _buildCompactUserInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                (user?.name != null && user!.name.isNotEmpty)
                    ? user!.name.substring(0, 1).toUpperCase()
                    : 'U',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(context, 20),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

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
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getFontSize(context, 16),
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (user?.role ?? 'user').toUpperCase(),
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getFontSize(context, 10),
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Show hierarchy in one line
                Text(
                  _getHierarchyText(),
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(context, 12),
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen.withValues(alpha: 0.08),
            AppTheme.primaryGreen.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 16,
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(width: 6),
              Text(
                'Last 30 Days',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(context, 12),
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onRefresh,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.refresh,
                    size: 16,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Revenue',
                  '₹${_formatNumber(statistics?['totalRevenue30Days'] ?? 0)}',
                  Icons.currency_rupee,
                ),
              ),
              _buildDivider(),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Collection',
                  '${_formatNumber(statistics?['totalCollection30Days'] ?? 0)} L',
                  Icons.water_drop_outlined,
                ),
              ),
              _buildDivider(),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Fat',
                  '${(statistics?['avgFat'] ?? 0).toStringAsFixed(1)}%',
                  Icons.opacity,
                ),
              ),
              _buildDivider(),
              Expanded(
                child: _buildStatItem(
                  context,
                  'SNF',
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

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppTheme.borderDark,
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
          size: 16,
          color: AppTheme.primaryGreen.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveHelper.getFontSize(context, 13),
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveHelper.getFontSize(context, 9),
            color: AppTheme.textTertiary,
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
