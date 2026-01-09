import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'dart:async';
import '../../providers/providers.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';
import '../../l10n/l10n.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/farmer_dashboard_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _canResend = false;
  int _resendTimer = 60;
  Timer? _timer;
  bool _isDisposed = false;
  bool _isNavigating = false; // Add navigation lock
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    // Set disposal flag first to stop all operations
    _isDisposed = true;
    _isNavigating = false;
    
    // Cancel timer
    _timer?.cancel();
    _timer = null;
    
    // Dispose animation controller
    _animationController.dispose();
    
    // Safely dispose text controller
    try {
      _otpController.dispose();
    } catch (e) {
      print('Controller disposal error: $e');
    }
    
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();

    if (!mounted || _isDisposed) return;

    setState(() {
      _canResend = false;
      _resendTimer = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isDisposed) {
        timer.cancel();
        return;
      }

      if (_resendTimer > 0) {
        if (mounted && !_isDisposed) {
          setState(() {
            _resendTimer--;
          });
        }
      } else {
        timer.cancel();
        if (mounted && !_isDisposed) {
          setState(() {
            _canResend = true;
          });
        }
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (!mounted || _isDisposed || _isNavigating) return;

    // Store OTP value before any async operations - check if controller is disposed
    String otpText = '';
    try {
      if (!_isDisposed && _otpController.text.isNotEmpty) {
        otpText = _otpController.text;
      }
    } catch (e) {
      print('Controller access error: $e');
      return;
    }

    if (otpText.length != 6) {
      CustomSnackbar.showError(
        context,
        message: 'Please enter a valid 6-digit OTP',
      );
      return;
    }

    // Print OTP for debugging
    print('🔐 DEBUG - User entered OTP: $otpText');
    print('📧 DEBUG - Email being verified: ${widget.email}');
    print('⏰ DEBUG - Current time: ${DateTime.now()}');

    if (!mounted || _isDisposed || _isNavigating) return;
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyOtp(widget.email, otpText);

    if (!mounted || _isDisposed || _isNavigating) return;
    setState(() {
      _isLoading = false;
    });

    if (success && mounted && !_isDisposed && !_isNavigating) {
      // Set navigation lock to prevent multiple navigation attempts
      _isNavigating = true;
      
      // Navigate to appropriate dashboard based on role
      final user = authProvider.user;
      
      // Cancel timer before navigation
      _timer?.cancel();
      
      // Use immediate navigation instead of postFrameCallback
      try {
        if (user?.role == 'farmer') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const FarmerDashboardScreen()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        print('Navigation error: $e');
        // Reset navigation lock on error
        if (mounted && !_isDisposed) {
          setState(() {
            _isNavigating = false;
          });
        }
      }
    } else if (mounted && !_isDisposed) {
      // Show detailed error message
      final errorMsg = authProvider.errorMessage ?? 'Verification failed';
      String submessage = 'Please check your OTP and try again';
      
      if (errorMsg.toLowerCase().contains('network')) {
        submessage = 'Check your internet connection';
      } else if (errorMsg.toLowerCase().contains('expired')) {
        submessage = 'Request a new OTP to continue';
      } else if (errorMsg.toLowerCase().contains('invalid')) {
        submessage = 'The OTP you entered is incorrect';
      } else if (errorMsg.toLowerCase().contains('server')) {
        submessage = 'Server temporarily unavailable';
      }
      
      CustomSnackbar.showError(
        context,
        message: errorMsg,
        submessage: submessage,
      );
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend || !mounted || _isDisposed) return;

    print('🔄 DEBUG - Resending OTP to: ${widget.email}');
    print('⏰ DEBUG - Resend requested at: ${DateTime.now()}');

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendOtp(widget.email);

    if (!mounted || _isDisposed) return;
    setState(() {
      _isLoading = false;
    });

    if (success && mounted && !_isDisposed) {
      // Clear the OTP field safely
      try {
        if (!_isDisposed) {
          _otpController.clear();
        }
      } catch (e) {
        print('Controller clear error: $e');
      }
      _startResendTimer();
      CustomSnackbar.showSuccess(
        context,
        message: 'OTP sent successfully',
        submessage: 'Check your email for the verification code',
      );
    } else if (mounted && !_isDisposed) {
      final errorMsg = authProvider.errorMessage ?? 'Failed to resend OTP';
      String submessage = 'Please try again';
      
      if (errorMsg.toLowerCase().contains('network')) {
        submessage = 'Check your internet connection';
      } else if (errorMsg.toLowerCase().contains('not found')) {
        submessage = 'Email address not registered';
      } else if (errorMsg.toLowerCase().contains('limit')) {
        submessage = 'Too many attempts, wait before retrying';
      }
      
      CustomSnackbar.showError(
        context,
        message: errorMsg,
        submessage: submessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: PremiumGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Premium App Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    TransparentBackButton(
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 400,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.darkBg2 : AppTheme.cardLight,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.primaryGreen.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.mark_email_read_rounded,
                                  size: 50,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 40),

                              // Title
                              Text(
                                AppLocalizations().tr('verify_otp'),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                                      fontWeight: FontWeight.w400,
                                      height: 1.4,
                                      letterSpacing: 0.3,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '${AppLocalizations().tr('otp_sent_to_email')}\n',
                                      ),
                                      TextSpan(
                                        text: widget.email,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primaryGreen,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),

                              // Premium OTP Card
                              PremiumCard(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Column(
                                    children: [
                                      // OTP Input
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final availableWidth = constraints.maxWidth;
                                          const spacing = 8.0;
                                          const totalSpacing = spacing * 5;
                                          final fieldWidth = ((availableWidth - totalSpacing) / 6).clamp(40.0, 52.0);
                                          final fieldHeight = (fieldWidth * 1.2).clamp(50.0, 62.0);
                                          
                                          final fillColor = isDark ? AppTheme.darkBg2 : AppTheme.cardLight;
                                          const textColor = AppTheme.primaryGreen;
                                          final borderColor = isDark 
                                              ? AppTheme.primaryGreen.withOpacity(0.2)
                                              : AppTheme.borderLight;
                                          
                                          return PinCodeTextField(
                                            appContext: context,
                                            length: 6,
                                            controller: _otpController,
                                            keyboardType: TextInputType.number,
                                            animationType: AnimationType.scale,
                                            enabled: !_isDisposed && !_isNavigating,
                                            animationDuration: const Duration(milliseconds: 200),
                                            enableActiveFill: true,
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            textStyle: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: textColor,
                                              letterSpacing: 0.5,
                                            ),
                                            pinTheme: PinTheme(
                                              shape: PinCodeFieldShape.box,
                                              borderRadius: BorderRadius.circular(12),
                                              fieldHeight: fieldHeight,
                                              fieldWidth: fieldWidth,
                                              borderWidth: 1.5,
                                              activeColor: AppTheme.primaryGreen,
                                              selectedColor: AppTheme.primaryGreen.withOpacity(0.6),
                                              inactiveColor: borderColor,
                                              activeFillColor: fillColor,
                                              selectedFillColor: fillColor,
                                              inactiveFillColor: fillColor,
                                            ),
                                            onChanged: (value) {
                                              if (!mounted || _isDisposed) return;
                                            },
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 24),

                                      // Verify Button
                                      PremiumGradientButton(
                                        text: AppLocalizations().tr('verify_continue'),
                                        icon: Icons.check_circle_rounded,
                                        onPressed: _verifyOtp,
                                        isLoading: _isLoading,
                                      ),
                                      const SizedBox(height: 20),

                                      // Resend OTP
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              '${AppLocalizations().tr('didnt_receive_code')} ',
                                              style: TextStyle(
                                                color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ),
                                          if (_canResend)
                                            InkWell(
                                              onTap: _resendOtp,
                                              borderRadius: BorderRadius.circular(8),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.refresh_rounded,
                                                      size: 16,
                                                      color: AppTheme.primaryGreen,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      AppLocalizations().tr('resend'),
                                                      style: const TextStyle(
                                                        color: AppTheme.primaryGreen,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: 0.3,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          else
                                            Padding(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.timer_outlined,
                                                    size: 16,
                                                    color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${_resendTimer}s',
                                                    style: TextStyle(
                                                      color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 0.2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Security Info
                              InfoContainer(
                                icon: Icons.shield_outlined,
                                text: AppLocalizations().tr('info_encrypted'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
