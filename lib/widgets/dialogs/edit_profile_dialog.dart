import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/helpers/size_config.dart';
import '../../utils/utils.dart';
import '../../l10n/l10n.dart';
import '../ui/buttons/custom_button.dart';
import 'form_field_widget.dart';
import 'package:provider/provider.dart';

/// A dialog for editing profile details
class EditProfileDialog extends StatefulWidget {
  final UserModel? user;
  final VoidCallback? onSuccess;

  const EditProfileDialog({super.key, this.user, this.onSuccess});

  /// Static method to show the dialog
  static Future<void> show(
    BuildContext context, {
    UserModel? user,
    VoidCallback? onSuccess,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditProfileDialog(user: user, onSuccess: onSuccess),
    );
  }

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _phoneController;
  late final TextEditingController _presidentController;
  late final TextEditingController _addressController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _ifscController;

  bool _isLoading = false;
  String get _role => (widget.user?.role ?? '').toLowerCase();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _locationController = TextEditingController(
      text: widget.user?.location ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.user?.phone ?? widget.user?.contactPhone ?? '',
    );
    _presidentController = TextEditingController(
      text: widget.user?.presidentName ?? '',
    );
    _addressController = TextEditingController(
      text: widget.user?.address ?? '',
    );
    _bankNameController = TextEditingController(
      text: widget.user?.bankName ?? '',
    );
    _accountNumberController = TextEditingController(
      text: widget.user?.bankAccountNumber ?? '',
    );
    _ifscController = TextEditingController(
      text: widget.user?.ifscCode ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _presidentController.dispose();
    _addressController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  String _getNameLabel() {
    switch (_role) {
      case 'society':
        return 'Society Name';
      case 'farmer':
        return 'Farmer Name';
      case 'bmc':
        return 'BMC Name';
      case 'dairy':
        return 'Dairy Name';
      default:
        return 'Name';
    }
  }

  Map<String, dynamic> _buildProfileData() {
    final profileData = <String, dynamic>{'name': _nameController.text.trim()};

    switch (_role) {
      case 'society':
        profileData['location'] = _locationController.text.trim();
        profileData['president_name'] = _presidentController.text.trim();
        profileData['contact_phone'] = _phoneController.text.trim();
        break;
      case 'farmer':
        profileData['phone'] = _phoneController.text.trim();
        profileData['address'] = _addressController.text.trim();
        profileData['bank_name'] = _bankNameController.text.trim();
        profileData['bank_account_number'] = _accountNumberController.text
            .trim();
        profileData['ifsc_code'] = _ifscController.text.trim();
        break;
      case 'bmc':
        profileData['location'] = _locationController.text.trim();
        profileData['contact_phone'] = _phoneController.text.trim();
        break;
      case 'dairy':
        profileData['location'] = _locationController.text.trim();
        profileData['contact_phone'] = _phoneController.text.trim();
        profileData['president_name'] = _presidentController.text.trim();
        break;
    }

    return profileData;
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar(AppLocalizations().tr('name_required'), isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileData = _buildProfileData();
    final success = await authProvider.updateProfile(profileData);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      _showSnackBar(AppLocalizations().tr('profile_updated'));
      widget.onSuccess?.call();
    } else if (mounted) {
      _showSnackBar(
        authProvider.errorMessage ??
            AppLocalizations().tr('failed_update_profile'),
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    SizeConfig.init(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
              size: SizeConfig.iconSizeMedium,
            ),
            SizedBox(width: SizeConfig.spaceSmall),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SizeConfig.spaceSmall + 2),
        ),
      ),
    );
  }

  bool get _showLocationField =>
      _role == 'society' || _role == 'bmc' || _role == 'dairy';

  bool get _showPresidentField => _role == 'society' || _role == 'dairy';

  bool get _showFarmerFields => _role == 'farmer';

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final isDark = context.isDarkMode;

    return Dialog(
      backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.spaceLarge),
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: EdgeInsets.all(SizeConfig.spaceXLarge),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              SizedBox(height: SizeConfig.spaceSmall),
              Text(
                'Update your profile details below. Email cannot be changed.',
                style: TextStyle(
                  fontSize: SizeConfig.fontSizeSmall,
                  color: context.textSecondaryColor.withOpacity(0.8),
                ),
              ),
              SizedBox(height: SizeConfig.spaceXLarge),

              // Email (Read-only)
              FormFieldWidget(
                label: AppLocalizations().tr('email'),
                controller: TextEditingController(
                  text: widget.user?.email ?? '',
                ),
                icon: Icons.email_outlined,
                enabled: false,
                hint: AppLocalizations().tr('cannot_change_email'),
              ),
              SizedBox(height: SizeConfig.spaceRegular),

              // Name
              FormFieldWidget(
                label: _getNameLabel(),
                controller: _nameController,
                icon: Icons.person_outline,
                enabled: !_isLoading,
              ),
              SizedBox(height: SizeConfig.spaceRegular),

              // Location (for society, bmc, dairy)
              if (_showLocationField) ...[
                FormFieldWidget(
                  label: AppLocalizations().tr('location'),
                  controller: _locationController,
                  icon: Icons.location_on_outlined,
                  enabled: !_isLoading,
                ),
                SizedBox(height: SizeConfig.spaceRegular),
              ],

              // Phone
              FormFieldWidget(
                label: AppLocalizations().tr('phone'),
                controller: _phoneController,
                icon: Icons.phone_outlined,
                enabled: !_isLoading,
                keyboardType: TextInputType.phone,
              ),

              // President (for society and dairy)
              if (_showPresidentField) ...[
                SizedBox(height: SizeConfig.spaceRegular),
                FormFieldWidget(
                  label: AppLocalizations().tr('president_name'),
                  controller: _presidentController,
                  icon: Icons.person_pin_outlined,
                  enabled: !_isLoading,
                ),
              ],

              // Farmer fields
              if (_showFarmerFields) ...[
                SizedBox(height: SizeConfig.spaceRegular),
                FormFieldWidget(
                  label: AppLocalizations().tr('address'),
                  controller: _addressController,
                  icon: Icons.home_outlined,
                  enabled: !_isLoading,
                  maxLines: 2,
                ),
                SizedBox(height: SizeConfig.spaceRegular),
                FormFieldWidget(
                  label: AppLocalizations().tr('bank_name'),
                  controller: _bankNameController,
                  icon: Icons.account_balance_outlined,
                  enabled: !_isLoading,
                ),
                SizedBox(height: SizeConfig.spaceRegular),
                FormFieldWidget(
                  label: AppLocalizations().tr('account_number'),
                  controller: _accountNumberController,
                  icon: Icons.credit_card_outlined,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: SizeConfig.spaceRegular),
                FormFieldWidget(
                  label: AppLocalizations().tr('ifsc_code'),
                  controller: _ifscController,
                  icon: Icons.pin_outlined,
                  enabled: !_isLoading,
                ),
              ],

              SizedBox(height: SizeConfig.spaceLarge + 4),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(SizeConfig.spaceSmall + 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(SizeConfig.radiusRegular),
                ),
                child: Icon(
                  Icons.edit,
                  color: AppTheme.primaryGreen,
                  size: SizeConfig.iconSizeLarge,
                ),
              ),
              SizedBox(width: SizeConfig.spaceMedium),
              Flexible(
                child: Text(
                  l10n.tr('edit_profile'),
                  style: TextStyle(
                    fontSize: SizeConfig.fontSizeXLarge,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                  softWrap: true,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          icon: Icon(Icons.close, color: context.textSecondaryColor),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final l10n = AppLocalizations();
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: l10n.tr('cancel'),
            type: CustomButtonType.outline,
            onPressed: _isLoading ? null : () => Navigator.pop(context),
          ),
        ),
        SizedBox(width: SizeConfig.spaceMedium),
        Expanded(
          child: CustomButton(
            text: l10n.tr('save_changes'),
            type: CustomButtonType.primary,
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ),
      ],
    );
  }
}
