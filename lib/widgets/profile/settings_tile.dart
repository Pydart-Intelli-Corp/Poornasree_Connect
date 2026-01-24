import 'package:flutter/material.dart';
import '../../utils/utils.dart';
import '../../l10n/l10n.dart';

/// A reusable settings tile widget for settings sections
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final Color? iconBackgroundColor;
  final Color? iconColor;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.iconBackgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final bgColor =
        iconBackgroundColor ?? AppTheme.primaryBlue.withOpacity(0.15);
    final iColor = iconColor ?? AppTheme.primaryBlue;

    return Container(
      padding: EdgeInsets.all(SizeConfig.spaceMedium),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(SizeConfig.radiusRegular),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(SizeConfig.spaceSmall),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
            ),
            child: Icon(icon, color: iColor, size: SizeConfig.iconSizeMedium),
          ),
          SizedBox(width: SizeConfig.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: SizeConfig.fontSizeRegular,
                    fontWeight: FontWeight.w500,
                    color: context.textPrimaryColor,
                  ),
                  softWrap: true,
                  maxLines: 2,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: SizeConfig.fontSizeXSmall,
                    color: context.textSecondaryColor,
                  ),
                  softWrap: true,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

/// Language selector widget - Updated to use AppLocalizations
class LanguageSelector extends StatefulWidget {
  final ValueChanged<AppLocale>? onLocaleChanged;

  const LanguageSelector({super.key, this.onLocaleChanged});

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  late AppLocale _selectedLocale;

  @override
  void initState() {
    super.initState();
    _selectedLocale = AppLocalizations().currentLocale;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations();

    return SettingsTile(
      icon: Icons.language,
      title: l10n.tr('language'),
      subtitle: l10n.tr('select_language'),
      iconBackgroundColor: AppTheme.primaryBlue.withOpacity(0.15),
      iconColor: AppTheme.primaryBlue,
      trailing: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.spaceMedium,
          vertical: SizeConfig.spaceXSmall + 2,
        ),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
          border: Border.all(color: context.borderColor),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<AppLocale>(
            value: _selectedLocale,
            isDense: true,
            dropdownColor: context.cardColor,
            style: TextStyle(
              fontSize: SizeConfig.fontSizeSmall,
              color: context.textPrimaryColor,
            ),
            items: AppLocale.values
                .map(
                  (locale) => DropdownMenuItem(
                    value: locale,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          locale.nativeName,
                          style: TextStyle(
                            fontSize: SizeConfig.fontSizeSmall,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        if (locale != AppLocale.english) ...[
                          SizedBox(width: SizeConfig.spaceXSmall + 2),
                          Text(
                            '(${locale.englishName})',
                            style: TextStyle(
                              fontSize: SizeConfig.fontSizeXSmall,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (locale) async {
              if (locale != null) {
                await AppLocalizations().setLocale(locale);
                setState(() => _selectedLocale = locale);
                widget.onLocaleChanged?.call(locale);
              }
            },
          ),
        ),
      ),
    );
  }
}

/// Theme toggle widget
class ThemeToggle extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  const ThemeToggle({
    super.key,
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final l10n = AppLocalizations();

    return SettingsTile(
      icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
      title: l10n.tr('theme'),
      subtitle: isDarkMode ? l10n.tr('dark_mode') : l10n.tr('light_mode'),
      iconBackgroundColor: AppTheme.primaryAmber.withOpacity(0.15),
      iconColor: AppTheme.primaryAmber,
      trailing: Transform.scale(
        scale: SizeConfig.userScale * 0.7,
        child: Switch(
          value: isDarkMode,
          onChanged: onChanged,
          activeColor: AppTheme.primaryGreen,
          activeTrackColor: AppTheme.primaryGreen.withOpacity(0.3),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

/// Auto-connect toggle widget for Bluetooth
class AutoConnectToggle extends StatelessWidget {
  final bool isAutoConnectEnabled;
  final ValueChanged<bool> onChanged;

  const AutoConnectToggle({
    super.key,
    required this.isAutoConnectEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final l10n = AppLocalizations();

    return SettingsTile(
      icon: Icons.bluetooth_connected,
      title: l10n.tr('auto_connect'),
      subtitle: isAutoConnectEnabled
          ? l10n.tr('auto_connect_desc')
          : l10n.tr('auto_connect_desc'),
      iconBackgroundColor: AppTheme.primaryBlue.withOpacity(0.15),
      iconColor: AppTheme.primaryBlue,
      trailing: Transform.scale(
        scale: SizeConfig.userScale * 0.7,
        child: Switch(
          value: isAutoConnectEnabled,
          onChanged: onChanged,
          activeColor: AppTheme.primaryGreen,
          activeTrackColor: AppTheme.primaryGreen.withOpacity(0.3),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
