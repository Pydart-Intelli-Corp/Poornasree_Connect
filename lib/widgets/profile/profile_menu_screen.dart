import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/utils.dart';
import '../common/common.dart';
import '../profile/profile.dart';
import '../dialogs/dialogs.dart';

/// A full-screen profile menu that slides in from the right
class ProfileMenuScreen extends StatefulWidget {
  final UserModel? user;
  final bool isDarkMode;
  final String selectedLanguage;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onLogout;
  final VoidCallback? onProfileUpdated;

  const ProfileMenuScreen({
    super.key,
    this.user,
    required this.isDarkMode,
    required this.selectedLanguage,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.onLogout,
    this.onProfileUpdated,
  });

  /// Show the profile menu with slide animation
  static Future<void> show(
    BuildContext context, {
    UserModel? user,
    required bool isDarkMode,
    required String selectedLanguage,
    required ValueChanged<bool> onThemeChanged,
    required ValueChanged<String> onLanguageChanged,
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
            selectedLanguage: selectedLanguage,
            onThemeChanged: onThemeChanged,
            onLanguageChanged: onLanguageChanged,
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
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _selectedLanguage = widget.selectedLanguage;
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
    return Material(
      color: Colors.transparent,
      child: Container(
        color: AppTheme.darkBg,
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
                      const Text(
                        'Poornasree Connect v1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textTertiary,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
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
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return SectionCard(
      title: 'Settings',
      child: Column(
        children: [
          LanguageSelector(
            selectedLanguage: _selectedLanguage,
            onChanged: (value) {
              setState(() => _selectedLanguage = value);
              widget.onLanguageChanged(value);
            },
          ),
          const SizedBox(height: 12),
          ThemeToggle(
            isDarkMode: _isDarkMode,
            onChanged: (value) {
              setState(() => _isDarkMode = value);
              widget.onThemeChanged(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout, size: 20),
        label: const Text('Logout'),
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
