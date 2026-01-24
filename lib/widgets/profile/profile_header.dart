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
    SizeConfig.init(context);
    final l10n = AppLocalizations();
    return Column(
      children: [
        // Avatar
        ProfileAvatar(name: user?.name),
        SizedBox(height: SizeConfig.spaceRegular),

        // Name
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            user?.name ?? l10n.tr('user'),
            style: TextStyle(
              fontSize: SizeConfig.fontSizeHuge,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
            maxLines: 1,
          ),
        ),
        SizedBox(height: SizeConfig.spaceXSmall),

        // Email
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            user?.email ?? '',
            style: TextStyle(
              fontSize: SizeConfig.fontSizeRegular,
              color: context.textSecondaryColor,
            ),
            maxLines: 1,
          ),
        ),
        SizedBox(height: SizeConfig.spaceMedium),

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
              icon: Icon(Icons.edit, size: SizeConfig.iconSizeMedium),
              label: Text(
                l10n.tr('edit'),
                style: TextStyle(fontSize: SizeConfig.fontSizeRegular),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.spaceRegular,
                  vertical: SizeConfig.spaceSmall,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
          if (user?.societyId != null || user?.societyIdentifier != null)
            DetailRow(
              icon: Icons.tag_outlined,
              label: l10n.tr('society_id'),
              value: user?.societyIdentifier ?? user?.societyId ?? '-',
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
          if (user?.address != null)
            DetailRow(
              icon: Icons.home_outlined,
              label: l10n.tr('address'),
              value: user?.address ?? '-',
            ),
          if (user?.bankName != null)
            DetailRow(
              icon: Icons.account_balance_outlined,
              label: l10n.tr('bank_name'),
              value: user?.bankName ?? '-',
            ),
          if (user?.bankAccountNumber != null)
            DetailRow(
              icon: Icons.credit_card_outlined,
              label: l10n.tr('account_number'),
              value: user?.bankAccountNumber ?? '-',
            ),
          if (user?.ifscCode != null)
            DetailRow(
              icon: Icons.pin_outlined,
              label: l10n.tr('ifsc_code'),
              value: user?.ifscCode ?? '-',
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
