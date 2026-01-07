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
    final bgColor =
        iconBackgroundColor ?? AppTheme.primaryBlue.withOpacity(0.15);
    final iColor = iconColor ?? AppTheme.primaryBlue;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.textPrimaryColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondaryColor,
                  ),
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

  const LanguageSelector({
    super.key,
    this.onLocaleChanged,
  });

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.borderColor),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<AppLocale>(
            value: _selectedLocale,
            isDense: true,
            dropdownColor: context.cardColor,
            style: TextStyle(fontSize: 13, color: context.textPrimaryColor),
            items: AppLocale.values.map((locale) => DropdownMenuItem(
              value: locale,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    locale.nativeName,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  if (locale != AppLocale.english) ...[
                    const SizedBox(width: 6),
                    Text(
                      '(${locale.englishName})',
                      style: TextStyle(
                        fontSize: 10,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            )).toList(),
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
    final l10n = AppLocalizations();
    
    return SettingsTile(
      icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
      title: l10n.tr('theme'),
      subtitle: isDarkMode ? l10n.tr('dark_mode') : l10n.tr('light_mode'),
      iconBackgroundColor: AppTheme.primaryAmber.withOpacity(0.15),
      iconColor: AppTheme.primaryAmber,
      trailing: Switch(
        value: isDarkMode,
        onChanged: onChanged,
        activeColor: AppTheme.primaryGreen,
        activeTrackColor: AppTheme.primaryGreen.withOpacity(0.3),
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
    final l10n = AppLocalizations();
    
    return SettingsTile(
      icon: Icons.bluetooth_connected,
      title: l10n.tr('auto_connect'),
      subtitle: isAutoConnectEnabled
          ? l10n.tr('auto_connect_desc')
          : l10n.tr('auto_connect_desc'),
      iconBackgroundColor: AppTheme.primaryBlue.withOpacity(0.15),
      iconColor: AppTheme.primaryBlue,
      trailing: Switch(
        value: isAutoConnectEnabled,
        onChanged: onChanged,
        activeColor: AppTheme.primaryGreen,
        activeTrackColor: AppTheme.primaryGreen.withOpacity(0.3),
      ),
    );
  }
}
