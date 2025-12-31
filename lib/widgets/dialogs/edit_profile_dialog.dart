import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/utils.dart';
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
    _addressController = TextEditingController();
    _bankNameController = TextEditingController();
    _accountNumberController = TextEditingController();
    _ifscController = TextEditingController();
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
      _showSnackBar('Name is required', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileData = _buildProfileData();
    final success = await authProvider.updateProfile(profileData);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      _showSnackBar('Profile updated successfully');
      widget.onSuccess?.call();
    } else if (mounted) {
      _showSnackBar(
        authProvider.errorMessage ?? 'Failed to update profile',
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  bool get _showLocationField =>
      _role == 'society' || _role == 'bmc' || _role == 'dairy';

  bool get _showPresidentField => _role == 'society' || _role == 'dairy';

  bool get _showFarmerFields => _role == 'farmer';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 8),
              Text(
                'Update your profile details below. Email cannot be changed.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 24),

              // Email (Read-only)
              FormFieldWidget(
                label: 'Email',
                controller: TextEditingController(
                  text: widget.user?.email ?? '',
                ),
                icon: Icons.email_outlined,
                enabled: false,
                hint: 'Email cannot be changed',
              ),
              const SizedBox(height: 16),

              // Name
              FormFieldWidget(
                label: _getNameLabel(),
                controller: _nameController,
                icon: Icons.person_outline,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              // Location (for society, bmc, dairy)
              if (_showLocationField) ...[
                FormFieldWidget(
                  label: 'Location',
                  controller: _locationController,
                  icon: Icons.location_on_outlined,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
              ],

              // Phone
              FormFieldWidget(
                label: 'Phone',
                controller: _phoneController,
                icon: Icons.phone_outlined,
                enabled: !_isLoading,
                keyboardType: TextInputType.phone,
              ),

              // President (for society and dairy)
              if (_showPresidentField) ...[
                const SizedBox(height: 16),
                FormFieldWidget(
                  label: 'President Name',
                  controller: _presidentController,
                  icon: Icons.person_pin_outlined,
                  enabled: !_isLoading,
                ),
              ],

              // Farmer fields
              if (_showFarmerFields) ...[
                const SizedBox(height: 16),
                FormFieldWidget(
                  label: 'Address',
                  controller: _addressController,
                  icon: Icons.home_outlined,
                  enabled: !_isLoading,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                FormFieldWidget(
                  label: 'Bank Name',
                  controller: _bankNameController,
                  icon: Icons.account_balance_outlined,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                FormFieldWidget(
                  label: 'Account Number',
                  controller: _accountNumberController,
                  icon: Icons.credit_card_outlined,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                FormFieldWidget(
                  label: 'IFSC Code',
                  controller: _ifscController,
                  icon: Icons.pin_outlined,
                  enabled: !_isLoading,
                ),
              ],

              const SizedBox(height: 28),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.edit,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              side: const BorderSide(color: AppTheme.borderDark),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Save Changes'),
          ),
        ),
      ],
    );
  }
}
