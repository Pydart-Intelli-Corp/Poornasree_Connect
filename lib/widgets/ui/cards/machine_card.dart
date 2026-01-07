import 'dart:io';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/utils.dart';
import '../../../models/models.dart';
import '../../../utils/config/theme.dart';
import '../../../services/services.dart';
import '../../machine/bluetooth_status_button.dart';
import '../feedback/flower_spinner.dart';

/// MachineCard - Google Material Design 3 Style
/// Clean, minimal, elevated surfaces with proper visual hierarchy
class MachineCard extends StatefulWidget {
  final Map<String, dynamic> machineData;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onView;
  final VoidCallback? onPasswordSettings;
  final VoidCallback? onStatusChanged;
  final VoidCallback? onMasterBadgeClick;
  final bool showActions;
  final bool isCompact;

  const MachineCard({
    super.key,
    required this.machineData,
    this.onEdit,
    this.onDelete,
    this.onView,
    this.onPasswordSettings,
    this.onStatusChanged,
    this.onMasterBadgeClick,
    this.showActions = true,
    this.isCompact = false,
  });

  @override
  State<MachineCard> createState() => _MachineCardState();
}

class _MachineCardState extends State<MachineCard> {
  bool _isHovered = false;
  late Map<String, dynamic> _machineData;

  @override
  void initState() {
    super.initState();
    _machineData = Map<String, dynamic>.from(widget.machineData);
  }

  @override
  Widget build(BuildContext context) {
    final machine = Machine.fromJson(_machineData);
    final isDark = context.isDarkMode;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: machine.isMasterMachine
                ? AppTheme.primaryAmber.withOpacity(0.4)
                : (isDark ? AppTheme.borderDark : AppTheme.borderLight)
                    .withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered ? 0.3 : 0.2),
              blurRadius: _isHovered ? 12 : 8,
              offset: Offset(0, _isHovered ? 4 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onView,
            borderRadius: BorderRadius.circular(12),
            splashColor: AppTheme.primaryGreen.withOpacity(0.05),
            highlightColor: AppTheme.primaryGreen.withOpacity(0.03),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(machine),
                _buildContent(machine),
                if (widget.showActions) _buildFooter(machine),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Header with image and core info - Google style horizontal layout
  Widget _buildHeader(Machine machine) {
    final hasImage = machine.imageUrl != null && machine.imageUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Machine Image - Left side with master badge below
          Column(
            children: [
              _buildImage(machine, hasImage),
              // Master badge under image
              if (machine.isMasterMachine) ...[
                const SizedBox(height: 8),
                _buildMasterChip(),
              ],
            ],
          ),
          const SizedBox(width: 16),

          // Core Info - Center
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with update indicator
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        machine.machineId,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Update Available indicator
                    if (_hasUpdateAvailable(machine)) ...[
                      const SizedBox(width: 8),
                      _buildUpdateAvailableIndicator(machine),
                    ],
                  ],
                ),
                const SizedBox(height: 4),

                // Machine type
                Text(
                  machine.machineType,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 12),

                // Status chip
                _buildStatusChip(machine.status),
              ],
            ),
          ),

          // Bluetooth status button - Right side (machine-specific)
          BluetoothStatusButton(
            machineId: machine.machineId,
            showLabel: true,
            iconSize: 18,
            fontSize: 12,
          ),
        ],
      ),
    );
  }

  /// Clean circular image with subtle border - supports cached images for offline
  Widget _buildImage(Machine machine, bool hasImage) {
    const double size = 72;
    final isDark = context.isDarkMode;

    if (!hasImage) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.precision_manufacturing_outlined,
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
          size: 32,
        ),
      );
    }

    final machineId = machine.id.toString();
    final networkUrl = machine.imageUrl!.startsWith('http')
        ? machine.imageUrl!
        : '${const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://192.168.1.68:3000')}${machine.imageUrl}';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: context.surfaceColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FutureBuilder<String?>(
          future: OfflineCacheService().getCachedImagePath(machineId),
          builder: (context, snapshot) {
            // If we have a cached image, use it
            if (snapshot.hasData && snapshot.data != null) {
              final file = File(snapshot.data!);
              return Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildNetworkImage(networkUrl),
              );
            }
            // Otherwise use network image
            return _buildNetworkImage(networkUrl);
          },
        ),
      ),
    );
  }

  /// Network image with loading and error handling
  Widget _buildNetworkImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Icon(
        Icons.image_not_supported_outlined,
        color: Colors.white.withOpacity(0.3),
        size: 28,
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(child: FlowerSpinner(size: 20));
      },
    );
  }

  /// Minimal master chip - Google style
  Widget _buildMasterChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryAmber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 12, color: AppTheme.primaryAmber),
          const SizedBox(width: 4),
          Text(
            AppLocalizations().tr('master'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryAmber,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Check if machine has any pending updates (corrections, charts, passwords)
  bool _hasUpdateAvailable(Machine machine) {
    // Check password status
    final userPwdStatus = machine.getUserPasswordStatus();
    final supervisorPwdStatus = machine.getSupervisorPasswordStatus();
    final hasPendingPassword =
        userPwdStatus.statusType == 'pending' ||
        supervisorPwdStatus.statusType == 'pending';

    // Check chart status
    final chartInfo = machine.parseChartDetails();
    final hasPendingCharts = chartInfo.pending.isNotEmpty;

    // Check correction status
    final correctionInfo = machine.parseCorrectionDetails();
    final hasPendingCorrections = correctionInfo.pending.isNotEmpty;

    return hasPendingPassword || hasPendingCharts || hasPendingCorrections;
  }

  /// Get update available details for the dialog
  Map<String, dynamic> _getUpdateDetails(Machine machine) {
    final List<String> pendingItems = [];

    // Check password status
    final userPwdStatus = machine.getUserPasswordStatus();
    final supervisorPwdStatus = machine.getSupervisorPasswordStatus();
    if (userPwdStatus.statusType == 'pending') {
      pendingItems.add(AppLocalizations().tr('user_password'));
    }
    if (supervisorPwdStatus.statusType == 'pending') {
      pendingItems.add(AppLocalizations().tr('supervisor_password'));
    }

    // Check chart status
    final chartInfo = machine.parseChartDetails();
    if (chartInfo.pending.isNotEmpty) {
      final chartTypes = chartInfo.pending.map((c) => c.channel).join(', ');
      pendingItems.add('${AppLocalizations().tr('rate_charts')} ($chartTypes)');
    }

    // Check correction status
    final correctionInfo = machine.parseCorrectionDetails();
    if (correctionInfo.pending.isNotEmpty) {
      final correctionTypes = correctionInfo.pending
          .map((c) => c.channel)
          .join(', ');
      pendingItems.add('${AppLocalizations().tr('corrections')} ($correctionTypes)');
    }

    return {'count': pendingItems.length, 'items': pendingItems};
  }

  /// Build update available indicator with tap to show instructions
  Widget _buildUpdateAvailableIndicator(Machine machine) {
    return GestureDetector(
      onTap: () => _showUpdateInstructionsDialog(context, machine),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.primaryAmber.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: AppTheme.primaryAmber.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.system_update_alt_rounded,
              size: 12,
              color: AppTheme.primaryAmber,
            ),
            const SizedBox(width: 4),
            Text(
              AppLocalizations().tr('update_available'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryAmber,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show update instructions dialog
  void _showUpdateInstructionsDialog(BuildContext context, Machine machine) {
    final updateDetails = _getUpdateDetails(machine);
    final pendingItems = updateDetails['items'] as List<String>;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryAmber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.system_update_alt_rounded,
                color: AppTheme.primaryAmber,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations().tr('update_available'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${pendingItems.length} ${AppLocalizations().tr('items_ready_download')}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pending items list
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppLocalizations().tr('pending_updates')}:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...pendingItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.pending_outlined,
                            size: 14,
                            color: AppTheme.primaryAmber,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Instructions header
            Text(
              '${AppLocalizations().tr('how_to_update')}:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // Step 1
            _buildInstructionStep(
              stepNumber: 1,
              icon: Icons.wifi,
              title: AppLocalizations().tr('wifi_instruction').split('.').first,
              description: AppLocalizations().tr('wifi_instruction'),
            ),
            const SizedBox(height: 12),

            // Step 2
            _buildInstructionStep(
              stepNumber: 2,
              icon: Icons.arrow_upward_rounded,
              title: AppLocalizations()
                  .tr('find_update_instruction')
                  .split('.')
                  .first,
              description: AppLocalizations().tr('find_update_instruction'),
            ),
            const SizedBox(height: 12),

            // Step 3
            _buildInstructionStep(
              stepNumber: 3,
              icon: Icons.check_circle_outline,
              title: AppLocalizations()
                  .tr('confirm_update_instruction')
                  .split('.')
                  .first,
              description: AppLocalizations().tr('confirm_update_instruction'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizations().tr('got_it'),
              style: TextStyle(
                color: AppTheme.successColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build instruction step widget
  Widget _buildInstructionStep({
    required int stepNumber,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step number circle
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.successColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: context.textPrimaryColor.withOpacity(0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondaryColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Clean status chip - Google style minimal
  Widget _buildStatusChip(String status) {
    final config = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: config.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: config.color,
            ),
          ),
        ],
      ),
    );
  }

  /// Content section - ESP32 Machine statistics in clean list format
  Widget _buildContent(Machine machine) {
    final details = <_DetailItem>[];

    // ESP32 Machine Statistics
    details.add(
      _DetailItem(
        icon: Icons.science_outlined,
        label: AppLocalizations().tr('total_tests'),
        value: machine.totalTests.toString(),
      ),
    );

    details.add(
      _DetailItem(
        icon: Icons.cleaning_services_outlined,
        label: AppLocalizations().tr('daily_clean'),
        value: machine.dailyCleaning.toString(),
      ),
    );

    details.add(
      _DetailItem(
        icon: Icons.event_repeat_outlined,
        label: AppLocalizations().tr('weekly_clean'),
        value: machine.weeklyCleaning.toString(),
      ),
    );

    details.add(
      _DetailItem(
        icon: Icons.skip_next_outlined,
        label: AppLocalizations().tr('skip_clean'),
        value: machine.cleaningSkip.toString(),
      ),
    );

    details.add(
      _DetailItem(
        icon: Icons.tune_outlined,
        label: AppLocalizations().tr('gain'),
        value: machine.gain.toString(),
      ),
    );

    // Auto Channel if available
    if (machine.autoChannel != null && machine.autoChannel!.isNotEmpty) {
      details.add(
        _DetailItem(
          icon: Icons.swap_horiz_outlined,
          label: AppLocalizations().tr('auto_channel'),
          value: machine.autoChannel!,
        ),
      );
    }

    // Machine Version if available
    if (machine.machineVersion != null && machine.machineVersion!.isNotEmpty) {
      details.add(
        _DetailItem(
          icon: Icons.info_outline,
          label: AppLocalizations().tr('version'),
          value: machine.machineVersion!,
        ),
      );
    }

    // Last sync date/time if available
    if (machine.statisticsDate != null) {
      final syncInfo = _formatSyncDateTime(
        machine.statisticsDate,
        machine.statisticsTime,
      );
      details.add(
        _DetailItem(
          icon: Icons.sync_outlined,
          label: AppLocalizations().tr('last_sync'),
          value: syncInfo,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Divider
          Container(
              height: 1,
              color: (context.isDarkMode
                      ? AppTheme.borderDark
                      : AppTheme.borderLight)
                  .withOpacity(0.3)),
          const SizedBox(height: 12),

          // Details grid - 2 columns
          ...List.generate((details.length / 2).ceil(), (rowIndex) {
            final startIndex = rowIndex * 2;
            final endIndex = (startIndex + 2).clamp(0, details.length);
            final rowItems = details.sublist(startIndex, endIndex);

            return Padding(
              padding: EdgeInsets.only(
                bottom: rowIndex < (details.length / 2).ceil() - 1 ? 12 : 0,
              ),
              child: Row(
                children: [
                  Expanded(child: _buildDetailTile(rowItems[0])),
                  if (rowItems.length > 1) ...[
                    const SizedBox(width: 16),
                    Expanded(child: _buildDetailTile(rowItems[1])),
                  ] else
                    const Expanded(child: SizedBox()),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Format sync date and time for display
  String _formatSyncDateTime(String? date, String? time) {
    if (date == null) return '-';
    try {
      final dateObj = DateTime.parse(date);
      final formattedDate = '${dateObj.day}/${dateObj.month}/${dateObj.year}';
      if (time != null && time.isNotEmpty) {
        // Parse time (format: HH:MM:SS)
        final timeParts = time.split(':');
        if (timeParts.length >= 2) {
          return '$formattedDate ${timeParts[0]}:${timeParts[1]}';
        }
      }
      return formattedDate;
    } catch (e) {
      return date;
    }
  }

  /// Single detail tile - Clean Google style
  Widget _buildDetailTile(_DetailItem item) {
    return Row(
      children: [
        Icon(
          item.icon,
          size: 16,
          color: AppTheme.primaryGreen.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: context.textSecondaryColor,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: context.textPrimaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Stats section - Google style metric cards (unused)
  // Widget _buildStats(Machine machine) {
  //   return Container(
  //     margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
  //     padding: const EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       color: Colors.white.withOpacity(0.04),
  //       borderRadius: BorderRadius.circular(8),
  //     ),
  //     child: Row(
  //       children: [
  //         Expanded(
  //           child: _buildStatItem(
  //             value: machine.totalCollections30d.toString(),
  //             label: AppLocalizations().tr('collections_label'),
  //             icon: Icons.receipt_long_outlined,
  //           ),
  //         ),
  //         Container(
  //           width: 1,
  //           height: 40,
  //           color: Colors.white.withOpacity(0.08),
  //         ),
  //         Expanded(
  //           child: _buildStatItem(
  //             value: '${machine.totalQuantity30d.toStringAsFixed(1)}L',
  //             label: AppLocalizations().tr('quantity_label'),
  //             icon: Icons.water_drop_outlined,
  //           ),
  //         ),
  //         Container(
  //           width: 1,
  //           height: 40,
  //           color: Colors.white.withOpacity(0.08),
  //         ),
  //         Expanded(
  //           child: _buildStatItem(
  //             value: '${machine.avgFat30d.toStringAsFixed(1)}%',
  //             label: AppLocalizations().tr('avg_fat'),
  //             icon: Icons.analytics_outlined,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// Single stat item - Minimal (unused)
  // Widget _buildStatItem({
  //   required String value,
  //   required String label,
  //   required IconData icon,
  // }) {
  //   return Column(
  //     children: [
  //       Text(
  //         value,
  //         style: const TextStyle(
  //           fontSize: 16,
  //           fontWeight: FontWeight.w600,
  //           color: Colors.white,
  //         ),
  //       ),
  //       const SizedBox(height: 2),
  //       Text(
  //         label,
  //         style: TextStyle(
  //           fontSize: 11,
  //           fontWeight: FontWeight.w400,
  //           color: Colors.white.withOpacity(0.5),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  /// Footer with 3 sections: Password, Rate Chart, Correction
  Widget _buildFooter(Machine machine) {
    // Get password status using the new logic
    final userPwdStatus = machine.getUserPasswordStatus();
    final supervisorPwdStatus = machine.getSupervisorPasswordStatus();

    // Parse chart details to get pending (Ready) and downloaded charts
    final chartInfo = machine.parseChartDetails();
    final hasPendingCharts = chartInfo.pending.isNotEmpty;
    final hasDownloadedCharts = chartInfo.downloaded.isNotEmpty;
    final hasAnyCharts = hasPendingCharts || hasDownloadedCharts;

    // Parse correction details to get pending (Ready) and downloaded corrections
    final correctionInfo = machine.parseCorrectionDetails();
    final hasPendingCorrections = correctionInfo.pending.isNotEmpty;
    final hasDownloadedCorrections = correctionInfo.downloaded.isNotEmpty;
    final hasAnyCorrections = hasPendingCorrections || hasDownloadedCorrections;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
        ),
      ),
      child: Row(
        children: [
          // 3 Sections with separators
          Expanded(
            child: Row(
              children: [
                // Section 1: Password Status
                Expanded(
                  flex: 3,
                  child: _buildFooterSection(
                    title: AppLocalizations().tr('password'),
                    icon: Icons.lock_outline,
                    children: [
                      _buildMiniStatusDot(
                        label: 'U',
                        statusType: userPwdStatus.statusType,
                        tooltip: userPwdStatus.text,
                      ),
                      const SizedBox(width: 6),
                      _buildMiniStatusDot(
                        label: 'S',
                        statusType: supervisorPwdStatus.statusType,
                        tooltip: supervisorPwdStatus.text,
                      ),
                    ],
                  ),
                ),

                // Separator
                _buildVerticalSeparator(),

                // Section 2: Rate Charts - Shows Ready (Yellow) and Downloaded (Green)
                Expanded(
                  flex: 4,
                  child: _buildChartSection(
                    chartInfo: chartInfo,
                    hasAnyCharts: hasAnyCharts,
                  ),
                ),

                // Separator
                _buildVerticalSeparator(),

                // Section 3: Corrections - Shows Ready (Yellow) and Downloaded (Green)
                Expanded(
                  flex: 4,
                  child: _buildCorrectionSection(
                    correctionInfo: correctionInfo,
                    hasAnyCorrections: hasAnyCorrections,
                  ),
                ),
              ],
            ),
          ),

          // Delete action
          if (widget.onDelete != null) ...[
            const SizedBox(width: 8),
            _buildIconButton(
              icon: Icons.delete_outline,
              onTap: widget.onDelete!,
              color: AppTheme.errorColor.withOpacity(0.8),
            ),
          ],
        ],
      ),
    );
  }

  /// Footer section with title and content
  Widget _buildFooterSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Section header
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 10, color: Colors.white.withOpacity(0.4)),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.4),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Section content
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ],
    );
  }

  /// Mini status dot for password (U = User, S = Supervisor)
  Widget _buildMiniStatusDot({
    required String label,
    required PasswordStatusType statusType,
    required String tooltip,
  }) {
    late Color color;
    switch (statusType) {
      case PasswordStatusType.downloaded:
      case PasswordStatusType.both:
      case PasswordStatusType.userOnly:
      case PasswordStatusType.supervisorOnly:
        color = AppTheme.successColor; // Green - Downloaded
        break;
      case PasswordStatusType.pending:
        color = AppTheme.primaryAmber; // Amber/Yellow - Pending
        break;
      case PasswordStatusType.none:
        color = AppTheme.errorColor; // Red - Not set
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section status label
  Widget _buildSectionStatus({
    required String label,
    required bool isActive,
    required Color activeColor,
  }) {
    final color = isActive ? activeColor : Colors.white.withOpacity(0.35);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Vertical separator between sections
  Widget _buildVerticalSeparator() {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  /// Chart section showing Ready (Yellow) and Downloaded (Green) status
  Widget _buildChartSection({
    required RateChartInfo chartInfo,
    required bool hasAnyCharts,
  }) {
    if (!hasAnyCharts) {
      return _buildFooterSection(
        title: AppLocalizations().tr('charts'),
        icon: Icons.show_chart,
        children: [
          _buildSectionStatus(
            label: AppLocalizations().tr('none'),
            isActive: false,
            activeColor: AppTheme.primaryBlue,
          ),
        ],
      );
    }

    // Get channel types for pending and downloaded
    final pendingTypes = _getChartTypesFromList(chartInfo.pending);
    final downloadedTypes = _getChartTypesFromList(chartInfo.downloaded);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Section header
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 10,
              color: Colors.white.withOpacity(0.4),
            ),
            const SizedBox(width: 4),
            Text(
              AppLocalizations().tr('charts'),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.4),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Chart status pills
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ready (Pending) - Yellow
            if (chartInfo.pending.isNotEmpty)
              _buildChartStatusPill(
                label: pendingTypes,
                isReady: true, // Yellow - Ready to download
              ),
            if (chartInfo.pending.isNotEmpty && chartInfo.downloaded.isNotEmpty)
              const SizedBox(width: 4),
            // Downloaded - Green
            if (chartInfo.downloaded.isNotEmpty)
              _buildChartStatusPill(
                label: downloadedTypes,
                isReady: false, // Green - Downloaded
              ),
          ],
        ),
      ],
    );
  }

  /// Chart status pill - Ready (Yellow) or Downloaded (Green)
  Widget _buildChartStatusPill({required String label, required bool isReady}) {
    final color = isReady
        ? AppTheme.primaryAmber
        : AppTheme.successColor; // Yellow or Green

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated pulse dot for Ready status
          if (isReady)
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            )
          else
            Icon(Icons.check, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Get chart types from a list of chart items
  String _getChartTypesFromList(List<ChartItem> charts) {
    final Set<String> types = {};
    for (final chart in charts) {
      final channel = chart.channel.toLowerCase();
      if (channel.contains('cow') || channel == '1' || channel == 'c') {
        types.add('Cow');
      } else if (channel.contains('buf') || channel == '2' || channel == 'b') {
        types.add('Buf');
      } else if (channel.contains('mix') || channel == '3' || channel == 'm') {
        types.add('Mix');
      }
    }
    return types.isEmpty ? 'Chart' : types.join(', ');
  }

  /// Correction section showing Ready (Yellow) and Downloaded (Green) status
  Widget _buildCorrectionSection({
    required CorrectionInfo correctionInfo,
    required bool hasAnyCorrections,
  }) {
    if (!hasAnyCorrections) {
      return _buildFooterSection(
        title: AppLocalizations().tr('corrections'),
        icon: Icons.tune,
        children: [
          _buildSectionStatus(
            label: AppLocalizations().tr('none'),
            isActive: false,
            activeColor: AppTheme.primaryPurple,
          ),
        ],
      );
    }

    // Get channel types for pending and downloaded
    final pendingTypes = _getCorrectionTypesFromList(correctionInfo.pending);
    final downloadedTypes = _getCorrectionTypesFromList(
      correctionInfo.downloaded,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Section header
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tune, size: 10, color: Colors.white.withOpacity(0.4)),
            const SizedBox(width: 4),
            Text(
              AppLocalizations().tr('corrections'),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.4),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Correction status pills
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ready (Pending) - Yellow
            if (correctionInfo.pending.isNotEmpty)
              _buildCorrectionStatusPill(
                label: pendingTypes,
                isReady: true, // Yellow - Ready to download
              ),
            if (correctionInfo.pending.isNotEmpty &&
                correctionInfo.downloaded.isNotEmpty)
              const SizedBox(width: 4),
            // Downloaded - Green
            if (correctionInfo.downloaded.isNotEmpty)
              _buildCorrectionStatusPill(
                label: downloadedTypes,
                isReady: false, // Green - Downloaded
              ),
          ],
        ),
      ],
    );
  }

  /// Correction status pill - Ready (Yellow) or Downloaded (Green)
  Widget _buildCorrectionStatusPill({
    required String label,
    required bool isReady,
  }) {
    final color = isReady
        ? AppTheme.primaryAmber
        : AppTheme.successColor; // Yellow or Green

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated pulse dot for Ready status
          if (isReady)
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            )
          else
            Icon(Icons.check, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Get correction types from a list of correction items
  String _getCorrectionTypesFromList(List<CorrectionItem> corrections) {
    final Set<String> types = {};
    for (final correction in corrections) {
      types.add(correction.channel);
    }
    return types.isEmpty ? 'Correction' : types.join(', ');
  }

  /// Password status pill with 3 states: Downloaded (green), Pending (yellow), None (red/gray) (unused)
  // Widget _buildPasswordStatusPill({
  //   required IconData icon,
  //   required String label,
  //   required PasswordStatusType statusType,
  // }) {
  //   late Color color;
  //   switch (statusType) {
  //     case PasswordStatusType.downloaded:
  //     case PasswordStatusType.both:
  //     case PasswordStatusType.userOnly:
  //     case PasswordStatusType.supervisorOnly:
  //       color = AppTheme.successColor; // Green - Downloaded
  //       break;
  //     case PasswordStatusType.pending:
  //       color = AppTheme.primaryAmber; // Amber/Yellow - Pending
  //       break;
  //     case PasswordStatusType.none:
  //       color = AppTheme.errorColor; // Red - Not set
  //       break;
  //   }
  //
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
  //     decoration: BoxDecoration(
  //       color: color.withOpacity(0.12),
  //       borderRadius: BorderRadius.circular(6),
  //       border: Border.all(color: color.withOpacity(0.25), width: 1),
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Icon(icon, size: 12, color: color),
  //         const SizedBox(width: 4),
  //         Text(
  //           label,
  //           style: TextStyle(
  //             fontSize: 10,
  //             fontWeight: FontWeight.w500,
  //             color: color,
  //             letterSpacing: 0.1,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// Extract chart types from chart info (Cow, Buffalo, Mix) (unused)
  // String _getChartTypes(RateChartInfo chartInfo) {
  //   final Set<String> types = {};
  //
  //   // Get types from both pending and downloaded charts
  //   for (final chart in [...chartInfo.pending, ...chartInfo.downloaded]) {
  //     final channel = chart.channel.toLowerCase();
  //     if (channel.contains('cow') || channel == '1' || channel == 'c') {
  //       types.add('Cow');
  //     } else if (channel.contains('buf') || channel == '2' || channel == 'b') {
  //       types.add('Buf');
  //     } else if (channel.contains('mix') || channel == '3' || channel == 'm') {
  //       types.add('Mix');
  //     }
  //   }
  //
  //   if (types.isEmpty) {
  //     return 'Active';
  //   }
  //
  //   return types.join(', ');
  // }

  /// Status pill indicator - compact design (unused)
  // Widget _buildStatusPill({
  //   required IconData icon,
  //   required String label,
  //   required bool isActive,
  //   required Color activeColor,
  //   required Color inactiveColor,
  // }) {
  //   final color = isActive ? activeColor : inactiveColor;
  //
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
  //     decoration: BoxDecoration(
  //       color: color.withOpacity(0.12),
  //       borderRadius: BorderRadius.circular(6),
  //       border: Border.all(color: color.withOpacity(0.25), width: 1),
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Icon(icon, size: 12, color: color),
  //         const SizedBox(width: 4),
  //         Text(
  //           label,
  //           style: TextStyle(
  //             fontSize: 10,
  //             fontWeight: FontWeight.w500,
  //             color: color,
  //             letterSpacing: 0.1,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// Clean icon button
  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  /// Get status configuration
  _StatusConfig _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'online':
        return _StatusConfig(color: AppTheme.successColor);
      case 'inactive':
      case 'offline':
        return _StatusConfig(color: AppTheme.errorColor);
      case 'maintenance':
        return _StatusConfig(color: AppTheme.primaryAmber);
      default:
        return _StatusConfig(color: Colors.white.withOpacity(0.5));
    }
  }
}

/// Helper classes
class _DetailItem {
  final IconData icon;
  final String label;
  final String value;

  _DetailItem({required this.icon, required this.label, required this.value});
}

class _StatusConfig {
  final Color color;
  _StatusConfig({required this.color});
}
