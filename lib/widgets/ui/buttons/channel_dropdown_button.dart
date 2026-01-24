import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../utils/utils.dart';

/// Channel dropdown button for milk type selection
/// Displays current channel with dropdown menu
class ChannelDropdownButton extends StatelessWidget {
  final String selectedChannel;
  final Function(String) onChannelChanged;
  final bool compact;

  const ChannelDropdownButton({
    super.key,
    required this.selectedChannel,
    required this.onChannelChanged,
    this.compact = true,
  });

  Color _getChannelColor(String channel) {
    switch (channel) {
      case 'CH1':
        return const Color(0xFF10B981); // Green for Cow
      case 'CH2':
        return const Color(0xFF3b82f6); // Blue for Buffalo
      case 'CH3':
        return const Color(0xFFf59e0b); // Amber for Mixed
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getChannelIcon(String channel) {
    switch (channel) {
      case 'CH1':
        return Icons.pets_rounded; // Cow
      case 'CH2':
        return Icons.water_drop_rounded; // Buffalo
      case 'CH3':
        return Icons.merge_type_rounded; // Mixed
      default:
        return Icons.category_rounded;
    }
  }

  String _getChannelName(String channel) {
    final l10n = AppLocalizations();
    switch (channel) {
      case 'CH1':
        return l10n.tr('cow');
      case 'CH2':
        return l10n.tr('buffalo');
      case 'CH3':
        return l10n.tr('mixed');
      default:
        return l10n.tr('all');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getChannelColor(selectedChannel);

    if (compact) {
      return PopupMenuButton<String>(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SizeConfig.spaceMedium),
        ),
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF),
        elevation: 8,
        offset: Offset(0, SizeConfig.spaceXLarge + SizeConfig.spaceXSmall),
        onSelected: onChannelChanged,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.spaceXSmall,
            vertical: SizeConfig.spaceTiny,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(SizeConfig.spaceMedium),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(SizeConfig.spaceTiny),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
                ),
                child: Icon(
                  _getChannelIcon(selectedChannel),
                  size: SizeConfig.iconSizeSmall,
                  color: color,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.spaceXSmall,
                  vertical: 1,
                ),
                child: Text(
                  selectedChannel,
                  style: TextStyle(
                    fontSize: SizeConfig.fontSizeXSmall,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        itemBuilder: (context) => [
          _buildMenuItem(context, 'CH1', isDark),
          _buildMenuItem(context, 'CH2', isDark),
          _buildMenuItem(context, 'CH3', isDark),
        ],
      );
    } else {
      // Full-width button version
      return PopupMenuButton<String>(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SizeConfig.spaceMedium),
        ),
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF),
        elevation: 8,
        offset: Offset(0, SizeConfig.spaceHuge + SizeConfig.spaceXSmall),
        onSelected: onChannelChanged,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.spaceMedium + 4,
            vertical: SizeConfig.spaceMedium,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(SizeConfig.spaceMedium),
            border: Border.all(
              color: color.withOpacity(isDark ? 0.4 : 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _getChannelIcon(selectedChannel),
                    color: color,
                    size: SizeConfig.iconSizeMedium,
                  ),
                  SizedBox(width: SizeConfig.spaceMedium),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations().tr('milk_type'),
                        style: TextStyle(
                          fontSize: SizeConfig.fontSizeSmall,
                          fontWeight: FontWeight.w500,
                          color: context.textSecondaryColor,
                        ),
                      ),
                      SizedBox(height: SizeConfig.spaceTiny),
                      Text(
                        _getChannelName(selectedChannel),
                        style: TextStyle(
                          fontSize: SizeConfig.fontSizeMedium,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Icon(
                Icons.expand_more_rounded,
                color: color,
                size: SizeConfig.iconSizeMedium,
              ),
            ],
          ),
        ),
        itemBuilder: (context) => [
          _buildMenuItem(context, 'CH1', isDark),
          _buildMenuItem(context, 'CH2', isDark),
          _buildMenuItem(context, 'CH3', isDark),
        ],
      );
    }
  }

  PopupMenuItem<String> _buildMenuItem(
    BuildContext context,
    String channel,
    bool isDark,
  ) {
    final color = _getChannelColor(channel);
    final isSelected = channel == selectedChannel;

    return PopupMenuItem<String>(
      value: channel,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.spaceMedium + 4,
        vertical: SizeConfig.spaceSmall,
      ),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.spaceMedium),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
          border: Border.all(
            color: isSelected
                ? color.withOpacity(0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: SizeConfig.iconSizeLarge + 8,
              height: SizeConfig.iconSizeLarge + 8,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Icon(
                _getChannelIcon(channel),
                color: color,
                size: SizeConfig.iconSizeSmall + 4,
              ),
            ),
            SizedBox(width: SizeConfig.spaceMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getChannelName(channel),
                    style: TextStyle(
                      fontSize: SizeConfig.fontSizeMedium,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: SizeConfig.spaceTiny),
                  Text(
                    channel,
                    style: TextStyle(
                      fontSize: SizeConfig.fontSizeSmall,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: EdgeInsets.all(SizeConfig.spaceXSmall),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: color,
                  size: SizeConfig.iconSizeSmall + 4,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
