import 'package:flutter/material.dart';
import '../../utils/utils.dart';

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
        color: AppTheme.darkBg2,
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
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

/// Language selector widget
class LanguageSelector extends StatelessWidget {
  final String selectedLanguage;
  final ValueChanged<String> onChanged;
  final List<String> languages;

  const LanguageSelector({
    super.key,
    required this.selectedLanguage,
    required this.onChanged,
    this.languages = const ['English', 'हिंदी', 'தமிழ்', 'తెలుగు', 'ಕನ್ನಡ'],
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: Icons.language,
      title: 'Language',
      subtitle: 'Select app language',
      iconBackgroundColor: AppTheme.primaryBlue.withOpacity(0.15),
      iconColor: AppTheme.primaryBlue,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedLanguage,
            isDense: true,
            dropdownColor: AppTheme.cardDark,
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            items: languages
                .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                .toList(),
            onChanged: (value) {
              if (value != null) onChanged(value);
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
    return SettingsTile(
      icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
      title: 'Theme',
      subtitle: isDarkMode ? 'Dark Mode' : 'Light Mode',
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
