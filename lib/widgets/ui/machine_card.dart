import 'package:flutter/material.dart';
import '../../utils/utils.dart';
import '../../models/models.dart';
import 'flower_spinner.dart';

/// MachineCard widget - Professional responsive design
/// Displays machine information with prominent image, status badges, and details
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

class _MachineCardState extends State<MachineCard>
    with SingleTickerProviderStateMixin {
  bool _isImagePressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Map<String, dynamic> _machineData;

  @override
  void initState() {
    super.initState();
    _machineData = Map<String, dynamic>.from(widget.machineData);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onImageTapDown(TapDownDetails details) {
    setState(() => _isImagePressed = true);
    _animationController.forward();
  }

  void _onImageTapUp(TapUpDetails details) {
    setState(() => _isImagePressed = false);
    _animationController.reverse();
  }

  void _onImageTapCancel() {
    setState(() => _isImagePressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final machine = Machine.fromJson(_machineData);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth < 400;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppTheme.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: machine.isMasterMachine
              ? AppTheme.primaryAmber.withOpacity(0.3)
              : AppTheme.borderDark.withOpacity(0.5),
          width: machine.isMasterMachine ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: widget.onView,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Section: Image + Header
            _buildTopSection(context, machine, isSmallScreen, isMediumScreen),

            // Status Badges Row
            _buildStatusBadges(context, machine, isSmallScreen),

            // Details Section
            _buildDetailsSection(context, machine, isSmallScreen),

            // Statistics Section
            if (!widget.isCompact &&
                (machine.totalCollections30d > 0 || machine.totalQuantity30d > 0))
              _buildStatisticsSection(context, machine, isSmallScreen),

            // Actions Section
            if (widget.showActions && widget.onDelete != null)
              _buildActionsSection(context),
          ],
        ),
      ),
    );
  }

  /// Build top section with image and header info
  Widget _buildTopSection(
    BuildContext context,
    Machine machine,
    bool isSmallScreen,
    bool isMediumScreen,
  ) {
    final hasImage = machine.imageUrl != null && machine.imageUrl!.isNotEmpty;
    final imageSize = isSmallScreen ? 80.0 : (isMediumScreen ? 100.0 : 120.0);

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.cardDark,
            AppTheme.cardDark2.withOpacity(0.3),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Machine Image or Icon
          _buildMachineImage(machine, imageSize, hasImage),

          SizedBox(width: isSmallScreen ? 10 : 14),

          // Header Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Machine ID and Master Badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        machine.machineId,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (machine.isMasterMachine)
                      _buildMasterBadge(isSmallScreen),
                  ],
                ),

                const SizedBox(height: 6),

                // Status Badge
                _buildStatusBadge(machine.status, isSmallScreen),

                const SizedBox(height: 8),

                // Society Info
                if (machine.societyName != null)
                  _buildInfoRow(
                    Icons.business_rounded,
                    '${machine.societyName}${machine.societyId != null ? ' (${machine.societyId})' : ''}',
                    isSmallScreen,
                  ),

                // Location
                if (machine.location != null && machine.location!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _buildInfoRow(
                      Icons.location_on_rounded,
                      machine.location!,
                      isSmallScreen,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build machine image with animation
  Widget _buildMachineImage(Machine machine, double size, bool hasImage) {
    if (!hasImage) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryGreen.withOpacity(0.15),
              AppTheme.primaryTeal.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.2),
          ),
        ),
        child: Icon(
          Icons.precision_manufacturing_rounded,
          color: AppTheme.primaryGreen,
          size: size * 0.5,
        ),
      );
    }

    return GestureDetector(
      onTapDown: _onImageTapDown,
      onTapUp: _onImageTapUp,
      onTapCancel: _onImageTapCancel,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(
                    _isImagePressed ? 0.3 : 0.15,
                  ),
                  blurRadius: _isImagePressed ? 16 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                machine.imageUrl!.startsWith('http')
                    ? machine.imageUrl!
                    : '${const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://192.168.1.68:3000')}${machine.imageUrl}',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppTheme.cardDark2,
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    color: AppTheme.textSecondary,
                    size: size * 0.4,
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppTheme.cardDark2,
                    child: Center(child: FlowerSpinner(size: size * 0.3)),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build master badge
  Widget _buildMasterBadge(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 2 : 3,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryAmber.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: isSmallScreen ? 10 : 12,
            color: Colors.white,
          ),
          SizedBox(width: isSmallScreen ? 2 : 4),
          Text(
            'MASTER',
            style: TextStyle(
              fontSize: isSmallScreen ? 8 : 9,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Build status badge
  Widget _buildStatusBadge(String status, bool isSmallScreen) {
    final statusInfo = _getStatusInfo(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 10,
        vertical: isSmallScreen ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusInfo.color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusInfo.icon, size: isSmallScreen ? 10 : 12, color: statusInfo.color),
          SizedBox(width: isSmallScreen ? 4 : 5),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: isSmallScreen ? 9 : 10,
              fontWeight: FontWeight.w600,
              color: statusInfo.color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Build info row with icon and text
  Widget _buildInfoRow(IconData icon, String text, bool isSmallScreen) {
    return Row(
      children: [
        Icon(
          icon,
          size: isSmallScreen ? 12 : 14,
          color: AppTheme.textSecondary,
        ),
        SizedBox(width: isSmallScreen ? 4 : 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              color: AppTheme.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Build status badges row (password, rate chart, corrections)
  Widget _buildStatusBadges(BuildContext context, Machine machine, bool isSmallScreen) {
    final userPwdStatus = machine.statusU == 1 ? 'pending' : 'not set';
    final supervisorPwdStatus = machine.statusS == 1 ? 'pending' : 'not set';
    final hasRateCharts = machine.activeChartsCount > 0;
    final hasCorrections = machine.activeCorrectionsCount > 0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.darkBg.withOpacity(0.5),
        border: Border(
          top: BorderSide(color: AppTheme.borderDark.withOpacity(0.3)),
          bottom: BorderSide(color: AppTheme.borderDark.withOpacity(0.3)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Password Status
            _buildSmallBadge(
              'User: ${_getPasswordStatusText(userPwdStatus)}',
              _getPasswordStatusColor(userPwdStatus),
              isSmallScreen,
            ),
            SizedBox(width: isSmallScreen ? 6 : 8),
            _buildSmallBadge(
              'Supervisor: ${_getPasswordStatusText(supervisorPwdStatus)}',
              _getPasswordStatusColor(supervisorPwdStatus),
              isSmallScreen,
            ),

            // Rate Chart Status
            if (hasRateCharts) ...[
              SizedBox(width: isSmallScreen ? 6 : 8),
              _buildSmallBadge(
                'Charts: ${machine.activeChartsCount}',
                AppTheme.primaryBlue,
                isSmallScreen,
                icon: Icons.show_chart_rounded,
              ),
            ],

            // Corrections Status
            if (hasCorrections) ...[
              SizedBox(width: isSmallScreen ? 6 : 8),
              _buildSmallBadge(
                'Corrections: ${machine.activeCorrectionsCount}',
                AppTheme.primaryPurple,
                isSmallScreen,
                icon: Icons.tune_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build small status badge
  Widget _buildSmallBadge(String text, Color color, bool isSmallScreen, {IconData? icon}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isSmallScreen ? 10 : 12, color: color),
            SizedBox(width: isSmallScreen ? 3 : 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: isSmallScreen ? 9 : 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build details section
  Widget _buildDetailsSection(BuildContext context, Machine machine, bool isSmallScreen) {
    final List<Widget> details = [];

    // Operator
    if (machine.operatorName != null && machine.operatorName!.isNotEmpty) {
      details.add(_buildDetailItem(
        Icons.person_rounded,
        'Operator',
        machine.operatorName!,
        isSmallScreen,
      ));
    }

    // Contact
    if (machine.contactPhone != null && machine.contactPhone!.isNotEmpty) {
      details.add(_buildDetailItem(
        Icons.phone_rounded,
        'Contact',
        machine.contactPhone!,
        isSmallScreen,
      ));
    }

    // Installation Date
    if (machine.formattedInstallationDate != null) {
      details.add(_buildDetailItem(
        Icons.calendar_today_rounded,
        'Installed',
        machine.formattedInstallationDate!,
        isSmallScreen,
      ));
    }

    // BMC
    if (machine.bmcName != null && machine.bmcName!.isNotEmpty) {
      details.add(_buildDetailItem(
        Icons.store_rounded,
        'BMC',
        machine.bmcName!,
        isSmallScreen,
      ));
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 8 : 10,
      ),
      child: Wrap(
        spacing: isSmallScreen ? 8 : 12,
        runSpacing: isSmallScreen ? 6 : 8,
        children: details,
      ),
    );
  }

  /// Build detail item
  Widget _buildDetailItem(IconData icon, String label, String value, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 10,
        vertical: isSmallScreen ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardDark2.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmallScreen ? 12 : 14, color: AppTheme.textSecondary),
          SizedBox(width: isSmallScreen ? 4 : 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 8 : 9,
                  color: AppTheme.textTertiary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build statistics section
  Widget _buildStatisticsSection(BuildContext context, Machine machine, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 6 : 8,
      ),
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen.withOpacity(0.1),
            AppTheme.primaryTeal.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Collections
          Expanded(
            child: _buildStatItem(
              Icons.receipt_long_rounded,
              '${machine.totalCollections30d}',
              'Collections',
              AppTheme.primaryGreen,
              isSmallScreen,
            ),
          ),
          Container(
            height: isSmallScreen ? 30 : 36,
            width: 1,
            color: AppTheme.borderDark.withOpacity(0.3),
          ),
          // Quantity
          Expanded(
            child: _buildStatItem(
              Icons.water_drop_rounded,
              '${machine.totalQuantity30d.toStringAsFixed(1)}L',
              '30-Day Total',
              AppTheme.primaryTeal,
              isSmallScreen,
            ),
          ),
        ],
      ),
    );
  }

  /// Build stat item
  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
    bool isSmallScreen,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: isSmallScreen ? 14 : 16, color: color),
            SizedBox(width: isSmallScreen ? 4 : 6),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 2 : 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 9 : 10,
            color: AppTheme.textTertiary,
          ),
        ),
      ],
    );
  }

  /// Build actions section
  Widget _buildActionsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkBg.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.onDelete != null)
            _buildActionButton(
              icon: Icons.delete_outline_rounded,
              color: AppTheme.errorColor,
              onTap: widget.onDelete!,
              tooltip: 'Delete',
            ),
        ],
      ),
    );
  }

  /// Build action button
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  /// Get password status text
  String _getPasswordStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'downloaded':
        return 'Downloaded';
      default:
        return 'Not Set';
    }
  }

  /// Get password status color
  Color _getPasswordStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.primaryAmber;
      case 'downloaded':
        return AppTheme.primaryGreen;
      default:
        return AppTheme.textSecondary;
    }
  }

  /// Get status info
  _StatusInfo _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'online':
        return _StatusInfo(color: AppTheme.primaryGreen, icon: Icons.check_circle_rounded);
      case 'inactive':
      case 'offline':
        return _StatusInfo(color: AppTheme.errorColor, icon: Icons.cancel_rounded);
      case 'maintenance':
        return _StatusInfo(color: AppTheme.primaryAmber, icon: Icons.build_circle_rounded);
      case 'suspended':
        return _StatusInfo(color: Colors.orange, icon: Icons.pause_circle_filled_rounded);
      default:
        return _StatusInfo(color: AppTheme.textSecondary, icon: Icons.help_outline_rounded);
    }
  }
}

/// Helper class for status info
class _StatusInfo {
  final Color color;
  final IconData icon;

  _StatusInfo({required this.color, required this.icon});
}
