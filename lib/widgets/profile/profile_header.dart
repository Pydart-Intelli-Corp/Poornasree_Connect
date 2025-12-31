import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/utils.dart';
import '../common/common.dart';
import 'profile_avatar.dart';

/// A reusable profile header widget displaying user info
class ProfileHeader extends StatelessWidget {
  final UserModel? user;
  final VoidCallback? onEditPressed;

  const ProfileHeader({super.key, this.user, this.onEditPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar
        ProfileAvatar(name: user?.name),
        const SizedBox(height: 16),

        // Name
        Text(
          user?.name ?? 'User',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),

        // Email
        Text(
          user?.email ?? '',
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),

        // Role Badge
        RoleBadge(role: user?.role ?? 'user'),
      ],
    );
  }
}

/// Profile details card showing user information
class ProfileDetailsCard extends StatelessWidget {
  final UserModel? user;
  final VoidCallback? onEditPressed;

  const ProfileDetailsCard({super.key, this.user, this.onEditPressed});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Profile Details',
      trailing: onEditPressed != null
          ? TextButton.icon(
              onPressed: onEditPressed,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
            )
          : null,
      child: Column(
        children: [
          DetailRow(
            icon: Icons.badge_outlined,
            label: 'ID',
            value: user?.id ?? '-',
          ),
          DetailRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user?.email ?? '-',
          ),
          DetailRow(
            icon: Icons.person_outline,
            label: 'Name',
            value: user?.name ?? '-',
          ),
          DetailRow(
            icon: Icons.security_outlined,
            label: 'Role',
            value: (user?.role ?? '-').toUpperCase(),
          ),
          if (user?.societyName != null)
            DetailRow(
              icon: Icons.business_outlined,
              label: 'Society',
              value: user?.societyName ?? '-',
            ),
          if (user?.societyId != null)
            DetailRow(
              icon: Icons.tag_outlined,
              label: 'Society ID',
              value: user?.societyId ?? '-',
            ),
          if (user?.bmcName != null)
            DetailRow(
              icon: Icons.warehouse_outlined,
              label: 'BMC',
              value: user?.bmcName ?? '-',
            ),
          if (user?.dairyName != null)
            DetailRow(
              icon: Icons.factory_outlined,
              label: 'Dairy',
              value: user?.dairyName ?? '-',
            ),
          if (user?.location != null)
            DetailRow(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: user?.location ?? '-',
            ),
          if (user?.phone != null || user?.contactPhone != null)
            DetailRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: user?.phone ?? user?.contactPhone ?? '-',
            ),
          if (user?.presidentName != null)
            DetailRow(
              icon: Icons.person_pin_outlined,
              label: 'President',
              value: user?.presidentName ?? '-',
            ),
          if (user?.adminName != null)
            DetailRow(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Admin',
              value: user?.adminName ?? '-',
            ),
        ],
      ),
    );
  }
}
