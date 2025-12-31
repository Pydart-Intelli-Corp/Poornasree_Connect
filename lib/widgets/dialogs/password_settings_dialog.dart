import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/utils.dart';
import '../ui/custom_button.dart';
import '../ui/custom_snackbar.dart';
import '../ui/info_container.dart';
import 'otp_verification_dialog.dart';

/// Password Settings Dialog for updating machine passwords
/// Similar to web app's Password Settings Modal
class PasswordSettingsDialog extends StatefulWidget {
  final Map<String, dynamic> machine;
  final Future<bool> Function(
    String machineId,
    String? userPassword,
    String? supervisorPassword,
  )
  onSave;
  final Future<Map<String, dynamic>?> Function(String machineId)? onGetStatus;

  /// User's email for OTP verification
  final String? userEmail;

  /// Callback to send OTP for password viewing
  final Future<bool> Function(String email)? onSendOtp;

  /// Callback to verify OTP for password viewing
  final Future<bool> Function(String email, String otp)? onVerifyOtp;

  /// List of other machines in the same society for applying passwords
  final List<Map<String, dynamic>>? societyMachines;

  /// Callback to apply passwords to selected machines
  final Future<bool> Function(
    List<String> machineIds,
    String? userPassword,
    String? supervisorPassword,
  )?
  onApplyToOthers;

  const PasswordSettingsDialog({
    super.key,
    required this.machine,
    required this.onSave,
    this.onGetStatus,
    this.userEmail,
    this.onSendOtp,
    this.onVerifyOtp,
    this.societyMachines,
    this.onApplyToOthers,
  });

  /// Show the dialog and return true if passwords were updated
  static Future<bool?> show(
    BuildContext context, {
    required Map<String, dynamic> machine,
    required Future<bool> Function(
      String machineId,
      String? userPassword,
      String? supervisorPassword,
    )
    onSave,
    Future<Map<String, dynamic>?> Function(String machineId)? onGetStatus,
    String? userEmail,
    Future<bool> Function(String email)? onSendOtp,
    Future<bool> Function(String email, String otp)? onVerifyOtp,
    List<Map<String, dynamic>>? societyMachines,
    Future<bool> Function(
      List<String> machineIds,
      String? userPassword,
      String? supervisorPassword,
    )?
    onApplyToOthers,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasswordSettingsDialog(
        machine: machine,
        onSave: onSave,
        onGetStatus: onGetStatus,
        userEmail: userEmail,
        onSendOtp: onSendOtp,
        onVerifyOtp: onVerifyOtp,
        societyMachines: societyMachines,
        onApplyToOthers: onApplyToOthers,
      ),
    );
  }

  @override
  State<PasswordSettingsDialog> createState() => _PasswordSettingsDialogState();
}

class _PasswordSettingsDialogState extends State<PasswordSettingsDialog> {
  // Controllers
  final _userPasswordController = TextEditingController();
  final _confirmUserPasswordController = TextEditingController();
  final _supervisorPasswordController = TextEditingController();
  final _confirmSupervisorPasswordController = TextEditingController();

  // State
  bool _isLoading = false;
  bool _isLoadingStatus = false;

  // Password status from API
  String? _userPasswordStatus; // 'none', 'pending', 'downloaded'
  String? _supervisorPasswordStatus; // 'none', 'pending', 'downloaded'

  // Current passwords from API (for display only)
  String? _currentUserPassword;
  String? _currentSupervisorPassword;

  String get _machineId =>
      widget.machine['machineId']?.toString() ??
      widget.machine['machine_id']?.toString() ??
      'Machine';

  bool get _isMasterMachine =>
      widget.machine['isMaster'] == true ||
      widget.machine['is_master'] == true ||
      widget.machine['isMasterMachine'] == true;

  @override
  void initState() {
    super.initState();
    // Check if status is already available in machine data
    _initializeStatusFromMachine();
    // Fetch fresh status and passwords from API
    _fetchPasswordStatus();
  }

  void _initializeStatusFromMachine() {
    // Try to get status from machine data (statusU, statusS)
    final statusU = widget.machine['statusU'];
    final statusS = widget.machine['statusS'];

    // statusU/statusS: 0 = no pending, 1 = pending download
    // We can infer: if statusU == 1, password is pending download
    if (statusU != null) {
      _userPasswordStatus = statusU == 1 ? 'pending' : null;
    }
    if (statusS != null) {
      _supervisorPasswordStatus = statusS == 1 ? 'pending' : null;
    }
  }

  Future<void> _fetchPasswordStatus() async {
    if (widget.onGetStatus == null) return;

    final machineDbId = widget.machine['id']?.toString() ?? '';
    if (machineDbId.isEmpty) return;

    setState(() => _isLoadingStatus = true);

    try {
      final status = await widget.onGetStatus!(machineDbId);
      if (status != null && mounted) {
        setState(() {
          _userPasswordStatus = status['userPasswordStatus'] as String?;
          _supervisorPasswordStatus =
              status['supervisorPasswordStatus'] as String?;
          // Store current passwords
          _currentUserPassword = status['userPassword'] as String?;
          _currentSupervisorPassword = status['supervisorPassword'] as String?;
          _isLoadingStatus = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingStatus = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStatus = false);
      }
    }
  }

  @override
  void dispose() {
    _userPasswordController.dispose();
    _confirmUserPasswordController.dispose();
    _supervisorPasswordController.dispose();
    _confirmSupervisorPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.borderDark.withOpacity(0.5)),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(theme),

                const SizedBox(height: 24),

                // Info Card
                InfoContainer(
                  icon: Icons.info_outline,
                  text:
                      'View or change machine passwords. Passwords are 6 digits and will be synced to the machine.',
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                  iconColor: AppTheme.primaryBlue,
                  textColor: AppTheme.primaryBlue,
                ),

                const SizedBox(height: 24),

                // User Password Section
                _buildSectionTitle(
                  'User Password',
                  Icons.person_outline,
                  theme,
                  status: _userPasswordStatus,
                ),
                const SizedBox(height: 8),
                // Current Password Display with View/Change buttons
                _buildCurrentPasswordDisplay(
                  currentPassword: _currentUserPassword,
                  isLoading: _isLoadingStatus,
                  passwordType: 'User',
                ),

                const SizedBox(height: 24),

                // Supervisor Password Section
                _buildSectionTitle(
                  'Supervisor Password',
                  Icons.admin_panel_settings_outlined,
                  theme,
                  status: _supervisorPasswordStatus,
                ),
                const SizedBox(height: 8),
                // Current Password Display with View/Change buttons
                _buildCurrentPasswordDisplay(
                  currentPassword: _currentSupervisorPassword,
                  isLoading: _isLoadingStatus,
                  passwordType: 'Supervisor',
                ),

                const SizedBox(height: 28),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Close',
                    type: CustomButtonType.outline,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.lock_outline,
            color: AppTheme.primaryBlue,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Password Settings',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _machineId,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textSecondary),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
    ThemeData theme, {
    String? status,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        if (status != null) ...[const Spacer(), _buildStatusBadge(status)],
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'pending':
        bgColor = AppTheme.primaryAmber.withOpacity(0.15);
        textColor = AppTheme.primaryAmber;
        label = 'Pending';
        icon = Icons.schedule;
        break;
      case 'downloaded':
        bgColor = AppTheme.primaryGreen.withOpacity(0.15);
        textColor = AppTheme.primaryGreen;
        label = 'Downloaded';
        icon = Icons.check_circle_outline;
        break;
      case 'none':
      default:
        bgColor = AppTheme.textSecondary.withOpacity(0.1);
        textColor = AppTheme.textSecondary;
        label = 'Not Set';
        icon = Icons.remove_circle_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPasswordDisplay({
    required String? currentPassword,
    required bool isLoading,
    required String passwordType,
  }) {
    final machineDbId = widget.machine['id']?.toString() ?? '';

    return _CurrentPasswordWidget(
      currentPassword: currentPassword,
      isLoading: isLoading,
      passwordType: passwordType,
      machineId: _machineId,
      userEmail: widget.userEmail,
      onSendOtp: widget.onSendOtp,
      onVerifyOtp: widget.onVerifyOtp,
      isMasterMachine: _isMasterMachine,
      societyMachines: widget.societyMachines,
      onApplyToOthers: widget.onApplyToOthers != null
          ? (machineIds, newPassword) async {
              if (passwordType == 'User') {
                return await widget.onApplyToOthers!(
                  machineIds,
                  newPassword,
                  null,
                );
              } else {
                return await widget.onApplyToOthers!(
                  machineIds,
                  null,
                  newPassword,
                );
              }
            }
          : null,
      onChangePassword: (newPassword) async {
        // Call the onSave with only the specific password type
        bool success;
        if (passwordType == 'User') {
          success = await widget.onSave(machineDbId, newPassword, null);
        } else {
          success = await widget.onSave(machineDbId, null, newPassword);
        }

        return success;
      },
      onPasswordChanged: () {
        // Refresh the password status after change
        _fetchPasswordStatus();
      },
    );
  }
}

/// Widget to display current password with OTP verification before showing
class _CurrentPasswordWidget extends StatefulWidget {
  final String? currentPassword;
  final bool isLoading;
  final String passwordType;
  final String machineId;
  final String? userEmail;
  final Future<bool> Function(String email)? onSendOtp;
  final Future<bool> Function(String email, String otp)? onVerifyOtp;
  final Future<bool> Function(String newPassword)? onChangePassword;
  final VoidCallback? onPasswordChanged;
  final bool isMasterMachine;
  final List<Map<String, dynamic>>? societyMachines;
  final Future<bool> Function(List<String> machineIds, String newPassword)?
  onApplyToOthers;

  const _CurrentPasswordWidget({
    required this.currentPassword,
    required this.isLoading,
    required this.passwordType,
    required this.machineId,
    this.userEmail,
    this.onSendOtp,
    this.onVerifyOtp,
    this.onChangePassword,
    this.onPasswordChanged,
    this.isMasterMachine = false,
    this.societyMachines,
    this.onApplyToOthers,
  });

  @override
  State<_CurrentPasswordWidget> createState() => _CurrentPasswordWidgetState();
}

class _CurrentPasswordWidgetState extends State<_CurrentPasswordWidget> {
  Future<void> _handleViewPassword() async {
    final hasPassword =
        widget.currentPassword != null && widget.currentPassword!.isNotEmpty;

    if (!hasPassword) {
      CustomSnackbar.show(
        context,
        message: 'No Password Set',
        submessage:
            'This machine does not have a ${widget.passwordType.toLowerCase()} password configured.',
        isError: true,
      );
      return;
    }

    // Check if OTP verification is available
    if (widget.userEmail == null ||
        widget.onSendOtp == null ||
        widget.onVerifyOtp == null) {
      // Fallback: show password directly if OTP is not configured
      _showPasswordAlert();
      return;
    }

    // Show OTP verification dialog
    final verified = await OtpVerificationDialog.show(
      context,
      email: widget.userEmail!,
      title: 'Verify Identity',
      description:
          'For security, please verify your identity with OTP to view the ${widget.passwordType.toLowerCase()} password.',
      onSendOtp: widget.onSendOtp!,
      onVerifyOtp: widget.onVerifyOtp!,
    );

    if (verified == true && mounted) {
      _showPasswordAlert();
    }
  }

  void _showPasswordAlert() {
    PasswordRevealDialog.show(
      context,
      title: '${widget.passwordType} Password',
      password: widget.currentPassword!,
      label: 'Machine: ${widget.machineId}',
    );
  }

  Future<void> _handleChangePassword() async {
    if (widget.onChangePassword == null) return;

    final result = await ChangePasswordDialog.show(
      context,
      passwordType: widget.passwordType,
      machineId: widget.machineId,
      onSave: widget.onChangePassword!,
      isMasterMachine: widget.isMasterMachine,
      societyMachines: widget.societyMachines,
      onApplyToOthers: widget.onApplyToOthers,
    );

    if (result == true && mounted) {
      widget.onPasswordChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPassword =
        widget.currentPassword != null && widget.currentPassword!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.key_outlined, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(
            'Current: ',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          Expanded(
            child: widget.isLoading
                ? Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  )
                : Text(
                    !hasPassword ? 'Not set' : '••••••',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: hasPassword
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: hasPassword
                          ? Colors.white70
                          : AppTheme.textSecondary,
                    ),
                  ),
          ),
          if (!widget.isLoading) ...[
            // View button (only if password exists)
            if (hasPassword)
              GestureDetector(
                onTap: _handleViewPassword,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'View',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 8),
            // Change button
            if (widget.onChangePassword != null)
              GestureDetector(
                onTap: _handleChangePassword,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasPassword ? 'Change' : 'Set',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
