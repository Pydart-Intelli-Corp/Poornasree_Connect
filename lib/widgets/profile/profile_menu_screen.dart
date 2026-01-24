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
    SizeConfig.init(context);
    final l10n = AppLocalizations();
    final authProvider = Provider.of<AuthProvider>(context); // Listen to changes
    final user = authProvider.user; // Get latest user data

    return Material(
      color: Colors.transparent,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(SizeConfig.appBarHeight),
          child: AppBar(
            toolbarHeight: SizeConfig.appBarHeight,
            titleSpacing: SizeConfig.appBarTitleSpacing,
            title: Text(
              l10n.tr('profile'),
              style: SizeConfig.appBarTitleStyle,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.spaceLarge),
          child: Column(
            children: [
              // Profile Header
              ProfileHeader(user: user),
              SizedBox(height: SizeConfig.spaceHuge),

              // Profile Details Card
              ProfileDetailsCard(
                user: user,
                onEditPressed: _handleEditProfile,
              ),
              SizedBox(height: SizeConfig.spaceXLarge),

              // Settings Card
              _buildSettingsCard(),
              SizedBox(height: SizeConfig.spaceHuge),

              // Logout Button
              _buildLogoutButton(),
              SizedBox(height: SizeConfig.spaceRegular),

              // App Version
              Text(
                '${l10n.tr('app_name')} v1.0.0',
                style: TextStyle(
                  fontSize: SizeConfig.fontSizeSmall,
                  color: context.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    final l10n = AppLocalizations();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final isFarmer = user?.role?.toLowerCase() == 'farmer';

    return SectionCard(
      title: l10n.tr('settings'),
      child: Column(
        children: [
          SizeScaleSlider(
            onChanged: (scale) {
              // Trigger a rebuild to apply new sizes
              if (mounted) {
                setState(() {});
              }
            },
          ),
          SizedBox(height: SizeConfig.spaceMedium),
          LanguageSelector(
            onLocaleChanged: (locale) {
              widget.onLanguageChanged(locale);
              // Force rebuild to update all localized text
              if (mounted) {
                setState(() {});
              }
            },
          ),
          SizedBox(height: SizeConfig.spaceMedium),
          ThemeToggle(
            isDarkMode: _isDarkMode,
            onChanged: (value) async {
              setState(() => _isDarkMode = value);
              final themeProvider = Provider.of<ThemeProvider>(
                context,
                listen: false,
              );
              await themeProvider.setDarkMode(value);
              widget.onThemeChanged(value);
            },
          ),
          if (!isFarmer) ...[
            SizedBox(height: SizeConfig.spaceMedium),
            AutoConnectToggle(
              isAutoConnectEnabled: _isAutoConnectEnabled,
              onChanged: (value) {
                setState(() => _isAutoConnectEnabled = value);
                widget.onAutoConnectChanged(value);
              },
            ),
            SizedBox(height: SizeConfig.spaceMedium),
            const ShiftSettingsWidget(),
          ],
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
        icon: Icon(Icons.logout, size: SizeConfig.iconSizeSmall),
        label: Text(
          l10n.tr('logout'),
          style: TextStyle(fontSize: SizeConfig.fontSizeSmall),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.15),
          foregroundColor: Colors.red,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            vertical: SizeConfig.spaceSmall + 4,
            horizontal: SizeConfig.spaceRegular,
          ),
          minimumSize: Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SizeConfig.spaceSmall),
            side: BorderSide(color: Colors.red.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }
}
