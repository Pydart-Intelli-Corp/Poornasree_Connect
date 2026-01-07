import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../utils/utils.dart';
import '../../l10n/l10n.dart';
import '../../providers/providers.dart';
import '../common/common.dart';
import '../profile/profile.dart';
import '../dialogs/dialogs.dart';

/// A full-screen profile menu that slides in from the right
class ProfileMenuScreen extends StatefulWidget {
  final UserModel? user;
  final bool isDarkMode;
  final bool isAutoConnectEnabled;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<AppLocale> onLanguageChanged;
  final ValueChanged<bool> onAutoConnectChanged;
  final VoidCallback onLogout;
  final VoidCallback? onProfileUpdated;

  const ProfileMenuScreen({
    super.key,
    this.user,
    required this.isDarkMode,
    required this.isAutoConnectEnabled,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.onAutoConnectChanged,
    required this.onLogout,
    this.onProfileUpdated,
  });

  /// Show the profile menu with slide animation
  static Future<void> show(
    BuildContext context, {
    UserModel? user,
    required bool isDarkMode,
    required bool isAutoConnectEnabled,
    required ValueChanged<bool> onThemeChanged,
    required ValueChanged<AppLocale> onLanguageChanged,
    required ValueChanged<bool> onAutoConnectChanged,
    required VoidCallback onLogout,
    VoidCallback? onProfileUpdated,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ProfileMenuScreen(
            user: user,
            isDarkMode: isDarkMode,
            isAutoConnectEnabled: isAutoConnectEnabled,
            onThemeChanged: onThemeChanged,
            onLanguageChanged: onLanguageChanged,
            onAutoConnectChanged: onAutoConnectChanged,
            onLogout: onLogout,
            onProfileUpdated: onProfileUpdated,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<ProfileMenuScreen> createState() => _ProfileMenuScreenState();
}

class _ProfileMenuScreenState extends State<ProfileMenuScreen> {
  late bool _isDarkMode;
  late bool _isAutoConnectEnabled;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _isAutoConnectEnabled = widget.isAutoConnectEnabled;
  }

  void _handleEditProfile() {
    Navigator.pop(context);
    EditProfileDialog.show(
      context,
      user: widget.user,
      onSuccess: widget.onProfileUpdated,
    );
  }

  void _handleLogout() {
    Navigator.pop(context);
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations();
    
    return Material(
      color: Colors.transparent,
      child: Container(
        color: context.backgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile Header
                      ProfileHeader(user: widget.user),
                      const SizedBox(height: 32),

                      // Profile Details Card
                      ProfileDetailsCard(
                        user: widget.user,
                        onEditPressed: _handleEditProfile,
                      ),
                      const SizedBox(height: 24),

                      // Settings Card
                      _buildSettingsCard(),
                      const SizedBox(height: 32),

                      // Logout Button
                      _buildLogoutButton(),
                      const SizedBox(height: 16),

                      // App Version
                      Text(
                        '${l10n.tr('app_name')} v1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryGreen.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.tr('profile'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: context.textSecondaryColor),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    final l10n = AppLocalizations();
    
    return SectionCard(
      title: l10n.tr('settings'),
      child: Column(
        children: [
          LanguageSelector(
            onLocaleChanged: (locale) {
              widget.onLanguageChanged(locale);
              // Force rebuild to update all localized text
              if (mounted) {
                setState(() {});
              }
            },
          ),
          const SizedBox(height: 12),
          ThemeToggle(
            isDarkMode: _isDarkMode,
            onChanged: (value) async {
              setState(() => _isDarkMode = value);
              final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
              await themeProvider.setDarkMode(value);
              widget.onThemeChanged(value);
            },
          ),
          const SizedBox(height: 12),
          AutoConnectToggle(
            isAutoConnectEnabled: _isAutoConnectEnabled,
            onChanged: (value) {
              setState(() => _isAutoConnectEnabled = value);
              widget.onAutoConnectChanged(value);
            },
          ),
          const SizedBox(height: 12),
          const ShiftSettingsWidget(),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    final l10n = AppLocalizations();
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout, size: 20),
        label: Text(l10n.tr('logout')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.15),
          foregroundColor: Colors.red,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }
}
