import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'dart:async';
import '../../l10n/app_localizations.dart';
import '../../utils/utils.dart';
import '../ui/ui.dart';

/// OTP Verification Dialog for sensitive operations like viewing passwords
/// Sends OTP to user's email and verifies before proceeding
class OtpVerificationDialog extends StatefulWidget {
  final String email;
  final String title;
  final String description;
  final Future<bool> Function(String email) onSendOtp;
  final Future<bool> Function(String email, String otp) onVerifyOtp;
  final VoidCallback? onSuccess;

  const OtpVerificationDialog({
    super.key,
    required this.email,
    required this.title,
    required this.description,
    required this.onSendOtp,
    required this.onVerifyOtp,
    this.onSuccess,
  });

  /// Show the dialog and return true if OTP was verified successfully
  static Future<bool?> show(
    BuildContext context, {
    required String email,
    required String title,
    required String description,
    required Future<bool> Function(String email) onSendOtp,
    required Future<bool> Function(String email, String otp) onVerifyOtp,
    VoidCallback? onSuccess,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => OtpVerificationDialog(
        email: email,
        title: title,
        description: description,
        onSendOtp: onSendOtp,
        onVerifyOtp: onVerifyOtp,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog>
    with SingleTickerProviderStateMixin {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isSendingOtp = false;
  bool _otpSent = false;
  bool _canResend = false;
  int _resendTimer = 60;
  Timer? _timer;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    // Auto-send OTP when dialog opens
    _sendOtp();
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Don't dispose controllers if already disposed
    try {
      _otpController.dispose();
    } catch (_) {}
    try {
      _animationController.dispose();
    } catch (_) {}
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _canResend = false;
      _resendTimer = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        timer.cancel();
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  Future<void> _sendOtp() async {
    if (_isSendingOtp) return;

    setState(() {
      _isSendingOtp = true;
      _errorMessage = null;
    });

    try {
      final success = await widget.onSendOtp(widget.email);

      if (mounted) {
        setState(() {
          _isSendingOtp = false;
          _otpSent = success;
        });

        if (success) {
          _startResendTimer();
          CustomSnackbar.showSuccess(
            context,
            message: AppLocalizations().tr('otp_sent_msg'),
            submessage: AppLocalizations().tr('check_email'),
          );
        } else {
          setState(() {
            _errorMessage = 'Failed to send OTP. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await widget.onVerifyOtp(widget.email, otp);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          widget.onSuccess?.call();
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _errorMessage = 'Invalid OTP. Please try again.';
          });
          _otpController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Verification failed: ${e.toString()}';
        });
      }
    }
  }

  String _getMaskedEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final name = parts[0];
    final domain = parts[1];

    if (name.length <= 2) {
      return '${'*' * name.length}@$domain';
    }

    final visibleStart = name.substring(0, 2);
    final visibleEnd = name.length > 4 ? name.substring(name.length - 1) : '';
    final maskedMiddle = '*' * (name.length - 3).clamp(1, 5);

    return '$visibleStart$maskedMiddle$visibleEnd@$domain';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.borderDark.withOpacity(0.5)),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header
                  _buildHeader(theme),

                  const SizedBox(height: 20),

                  // Info
                  InfoContainer(
                    icon: Icons.security_outlined,
                    text: widget.description,
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                    iconColor: AppTheme.primaryBlue,
                    textColor: AppTheme.primaryBlue,
                  ),

                  const SizedBox(height: 20),

                  // Email display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: context.borderColor,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getMaskedEmail(widget.email),
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // OTP Input
                  if (_otpSent) ...[
                    Text(
                      'Enter 6-digit verification code',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PinCodeTextField(
                      appContext: context,
                      length: 6,
                      controller: _otpController,
                      obscureText: false,
                      animationType: AnimationType.fade,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(10),
                        fieldHeight: 50,
                        fieldWidth: 45,
                        activeFillColor: context.cardColor,
                        inactiveFillColor: context.surfaceColor,
                        selectedFillColor: context.cardColor,
                        activeColor: AppTheme.primaryGreen,
                        inactiveColor: AppTheme.borderDark,
                        selectedColor: AppTheme.primaryGreen,
                      ),
                      animationDuration: const Duration(milliseconds: 200),
                      enableActiveFill: true,
                      onCompleted: (value) {
                        if (!_isLoading) {
                          _verifyOtp();
                        }
                      },
                      onChanged: (value) {
                        if (_errorMessage != null) {
                          setState(() {
                            _errorMessage = null;
                          });
                        }
                      },
                    ),
                  ] else if (_isSendingOtp) ...[
                    const SizedBox(height: 20),
                    FlowerSpinner(size: 40),
                    const SizedBox(height: 16),
                    Text(
                      'Sending OTP...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: AppTheme.errorColor,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: AppTheme.errorColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Resend OTP
                  if (_otpSent) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive the code? ",
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        if (_canResend)
                          GestureDetector(
                            onTap: _isSendingOtp ? null : _sendOtp,
                            child: Text(
                              'Resend OTP',
                              style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          Text(
                            'Resend in ${_resendTimer}s',
                            style: TextStyle(
                              color: AppTheme.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Cancel',
                          type: CustomButtonType.outline,
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Verify',
                          type: CustomButtonType.primary,
                          isLoading: _isLoading,
                          onPressed: (_isLoading || !_otpSent)
                              ? null
                              : _verifyOtp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.verified_user_outlined,
            color: AppTheme.primaryGreen,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.close, color: AppTheme.textSecondary, size: 20),
              onPressed: _isLoading
                  ? null
                  : () => Navigator.of(context).pop(false),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }
}

/// Alert dialog to show the password after OTP verification
class PasswordRevealDialog extends StatelessWidget {
  final String title;
  final String password;
  final String? label;

  const PasswordRevealDialog({
    super.key,
    required this.title,
    required this.password,
    this.label,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String password,
    String? label,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          PasswordRevealDialog(title: title, password: password, label: label),
    );
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
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_open_outlined,
                color: AppTheme.primaryGreen,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            if (label != null) ...[
              const SizedBox(height: 4),
              Text(
                label!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Password Display Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Password',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    password,
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Copy button
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: password));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations().tr('password_copied')),
                    backgroundColor: AppTheme.primaryGreen,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(Icons.copy, size: 16, color: AppTheme.primaryGreen),
              label: Text(
                'Copy to clipboard',
                style: TextStyle(color: AppTheme.primaryGreen),
              ),
            ),

            const SizedBox(height: 16),

            // Warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryAmber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    size: 18,
                    color: AppTheme.primaryAmber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Keep this password secure and do not share it.',
                      style: TextStyle(
                        color: AppTheme.primaryAmber,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Close button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: AppLocalizations().tr('close'),
                type: CustomButtonType.primary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog to change/update password (User or Supervisor)
class ChangePasswordDialog extends StatefulWidget {
  final String passwordType; // 'User' or 'Supervisor'
  final String machineId;
  final Future<bool> Function(String newPassword) onSave;
  final bool isMasterMachine;
  final List<Map<String, dynamic>>? societyMachines;
  final Future<bool> Function(List<String> machineIds, String newPassword)?
  onApplyToOthers;

  const ChangePasswordDialog({
    super.key,
    required this.passwordType,
    required this.machineId,
    required this.onSave,
    this.isMasterMachine = false,
    this.societyMachines,
    this.onApplyToOthers,
  });

  /// Show the dialog and return true if password was updated
  static Future<bool?> show(
    BuildContext context, {
    required String passwordType,
    required String machineId,
    required Future<bool> Function(String newPassword) onSave,
    bool isMasterMachine = false,
    List<Map<String, dynamic>>? societyMachines,
    Future<bool> Function(List<String> machineIds, String newPassword)?
    onApplyToOthers,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChangePasswordDialog(
        passwordType: passwordType,
        machineId: machineId,
        onSave: onSave,
        isMasterMachine: isMasterMachine,
        societyMachines: societyMachines,
        onApplyToOthers: onApplyToOthers,
      ),
    );
  }

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _passwordError;
  String? _confirmPasswordError;

  // Apply to other machines state
  bool _applyToOthers = false;
  Set<String> _selectedMachineIds = {};
  bool _selectAllMachines = false;

  bool get _canApplyToOthers =>
      widget.isMasterMachine &&
      widget.societyMachines != null &&
      widget.societyMachines!.isNotEmpty &&
      widget.onApplyToOthers != null;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length != 6) {
      return 'Password must be exactly 6 digits';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Only digits allowed';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  bool _validateForm() {
    setState(() {
      _passwordError = _validatePassword(_passwordController.text);
      _confirmPasswordError = _validateConfirmPassword(
        _confirmPasswordController.text,
      );
    });
    return _passwordError == null && _confirmPasswordError == null;
  }

  Future<void> _handleSave() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final newPassword = _passwordController.text;
      final success = await widget.onSave(newPassword);

      if (success &&
          _applyToOthers &&
          _selectedMachineIds.isNotEmpty &&
          widget.onApplyToOthers != null) {
        await widget.onApplyToOthers!(
          _selectedMachineIds.toList(),
          newPassword,
        );
      }

      if (mounted) {
        if (success) {
          CustomSnackbar.showSuccess(
            context,
            message: AppLocalizations().tr('password_updated'),
            submessage: _applyToOthers && _selectedMachineIds.isNotEmpty
                ? '${widget.passwordType} ${AppLocalizations().tr('password')} ${AppLocalizations().tr('updated')} ${AppLocalizations().tr('for')} ${_selectedMachineIds.length + 1} ${AppLocalizations().tr('machines')}'
                : '${widget.passwordType} ${AppLocalizations().tr('password')} ${AppLocalizations().tr('will_be_synced')}',
          );
          Navigator.of(context).pop(true);
        } else {
          setState(() => _isLoading = false);
          CustomSnackbar.showError(
            context,
            message: AppLocalizations().tr('update_failed'),
            submessage: AppLocalizations().tr('failed_update_password'),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackbar.showError(
          context,
          message: 'Error',
          submessage: 'Failed to update password: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = widget.passwordType == 'User';

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.borderDark.withOpacity(0.5)),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            (isUser
                                    ? AppTheme.primaryBlue
                                    : AppTheme.primaryPurple)
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isUser
                            ? Icons.person_outline
                            : Icons.admin_panel_settings_outlined,
                        color: isUser
                            ? AppTheme.primaryBlue
                            : AppTheme.primaryPurple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Change ${widget.passwordType} Password',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.machineId,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Info
                InfoContainer(
                  icon: Icons.info_outline,
                  text:
                      'Enter a new 6-digit ${widget.passwordType.toLowerCase()} password. It will be synced to the machine.',
                  backgroundColor:
                      (isUser ? AppTheme.primaryBlue : AppTheme.primaryPurple)
                          .withOpacity(0.1),
                  iconColor: isUser
                      ? AppTheme.primaryBlue
                      : AppTheme.primaryPurple,
                  textColor: isUser
                      ? AppTheme.primaryBlue
                      : AppTheme.primaryPurple,
                ),

                const SizedBox(height: 24),

                // New Password Field
                _buildLabel(AppLocalizations().tr('new_password')),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: _passwordController,
                  hintText: AppLocalizations().tr('enter_6_digit_password'),
                  obscure: _obscurePassword,
                  onToggleObscure: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  error: _passwordError,
                  onChanged: (value) {
                    if (_passwordError != null) {
                      setState(() => _passwordError = _validatePassword(value));
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Confirm Password Field
                _buildLabel(AppLocalizations().tr('confirm_password')),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  hintText: AppLocalizations().tr('reenter_6_digit_password'),
                  obscure: _obscureConfirmPassword,
                  onToggleObscure: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                  error: _confirmPasswordError,
                  onChanged: (value) {
                    if (_confirmPasswordError != null) {
                      setState(
                        () => _confirmPasswordError = _validateConfirmPassword(
                          value,
                        ),
                      );
                    }
                  },
                ),

                const SizedBox(height: 24),

                // Apply to other machines section (only for master machines)
                if (_canApplyToOthers) ...[
                  _buildApplyToOthersSection(),
                  const SizedBox(height: 24),
                ],

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Cancel',
                        type: CustomButtonType.outline,
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Update',
                        type: CustomButtonType.primary,
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _handleSave,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscure,
    required VoidCallback onToggleObscure,
    String? error,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: error != null
                  ? AppTheme.errorColor
                  : AppTheme.borderDark.withOpacity(0.5),
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 18,
              letterSpacing: 8,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.5),
                fontSize: 14,
                letterSpacing: 0,
                fontWeight: FontWeight.normal,
              ),
              counterText: '',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
                onPressed: onToggleObscure,
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.error_outline, size: 14, color: AppTheme.errorColor),
              const SizedBox(width: 4),
              Text(
                error,
                style: TextStyle(color: AppTheme.errorColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildApplyToOthersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _applyToOthers,
                activeColor: AppTheme.primaryGreen,
                onChanged: (value) {
                  setState(() {
                    _applyToOthers = value ?? false;
                    if (!_applyToOthers) {
                      _selectedMachineIds.clear();
                      _selectAllMachines = false;
                    }
                  });
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apply password to other machines',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Update this password for other machines in this society',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_applyToOthers && widget.societyMachines!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardDark.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Machines (${_selectedMachineIds.length} selected)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_selectAllMachines) {
                              _selectedMachineIds.clear();
                              _selectAllMachines = false;
                            } else {
                              _selectedMachineIds = widget.societyMachines!
                                  .map(
                                    (m) =>
                                        (m['id'] ?? m['machine_id']).toString(),
                                  )
                                  .toSet();
                              _selectAllMachines = true;
                            }
                          });
                        },
                        child: Text(
                          _selectAllMachines ? 'Deselect All' : 'Select All',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: Column(
                        children: widget.societyMachines!.map((machine) {
                          final machineId =
                              (machine['id'] ?? machine['machine_id'])
                                  .toString();
                          final machineName =
                              machine['machineId'] ??
                              machine['machine_id'] ??
                              'Unknown';
                          final machineType =
                              machine['machineType'] ??
                              machine['machine_type'] ??
                              '';

                          return CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            value: _selectedMachineIds.contains(machineId),
                            activeColor: AppTheme.primaryGreen,
                            title: Row(
                              children: [
                                Icon(
                                  Icons.cable,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        machineName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      if (machineType.isNotEmpty)
                                        Text(
                                          machineType,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textTertiary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedMachineIds.add(machineId);
                                } else {
                                  _selectedMachineIds.remove(machineId);
                                  _selectAllMachines = false;
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
