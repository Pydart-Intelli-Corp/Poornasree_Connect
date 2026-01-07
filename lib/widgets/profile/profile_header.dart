import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/utils.dart';
import '../../l10n/l10n.dart';
import '../common/common.dart';
import 'profile_avatar.dart';

/// A reusable profile header widget displaying user info
class ProfileHeader extends StatelessWidget {
  final UserModel? user;
  final VoidCallback? onEditPressed;

  const ProfileHeader({super.key, this.user, this.onEditPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations();
    return Column(
      children: [
        // Avatar
        ProfileAvatar(name: user?.name),
        const SizedBox(height: 16),

        // Name
        Text(
          user?.name ?? l10n.tr('user'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 4),

        // Email
        Text(
          user?.email ?? '',
          style: TextStyle(fontSize: 14, color: context.textSecondaryColor),
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
    final l10n = AppLocalizations();
    return SectionCard(
      title: l10n.tr('profile_details'),
      trailing: onEditPressed != null
          ? TextButton.icon(
              onPressed: onEditPressed,
              icon: const Icon(Icons.edit, size: 16),
              label: Text(l10n.tr('edit')),
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
            label: l10n.tr('id'),
            value: user?.id ?? '-',
          ),
          DetailRow(
            icon: Icons.email_outlined,
            label: l10n.tr('email'),
            value: user?.email ?? '-',
          ),
          DetailRow(
            icon: Icons.person_outline,
            label: l10n.tr('name'),
            value: user?.name ?? '-',
          ),
          DetailRow(
            icon: Icons.security_outlined,
            label: l10n.tr('role'),
            value: (user?.role ?? '-').toUpperCase(),
          ),
          if (user?.societyName != null)
            DetailRow(
              icon: Icons.business_outlined,
              label: l10n.tr('society'),
              value: user?.societyName ?? '-',
            ),
          if (user?.societyId != null)
            DetailRow(
              icon: Icons.tag_outlined,
              label: l10n.tr('society_id'),
              value: user?.societyId ?? '-',
            ),
          if (user?.bmcName != null)
            DetailRow(
              icon: Icons.warehouse_outlined,
              label: l10n.tr('bmc'),
              value: user?.bmcName ?? '-',
            ),
          if (user?.dairyName != null)
            DetailRow(
              icon: Icons.factory_outlined,
              label: l10n.tr('dairy'),
              value: user?.dairyName ?? '-',
            ),
          if (user?.location != null)
            DetailRow(
              icon: Icons.location_on_outlined,
              label: l10n.tr('location'),
              value: user?.location ?? '-',
            ),
          if (user?.phone != null || user?.contactPhone != null)
            DetailRow(
              icon: Icons.phone_outlined,
              label: l10n.tr('phone'),
              value: user?.phone ?? user?.contactPhone ?? '-',
            ),
          if (user?.presidentName != null)
            DetailRow(
              icon: Icons.person_pin_outlined,
              label: l10n.tr('president'),
              value: user?.presidentName ?? '-',
            ),
          if (user?.adminName != null)
            DetailRow(
              icon: Icons.admin_panel_settings_outlined,
              label: l10n.tr('admin'),
              value: user?.adminName ?? '-',
            ),
        ],
      ),
    );
  }
}
