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
    SizeConfig.init(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: PremiumGradientBackground(
        child: SafeArea(
          child: Column(
            children: [

              // Content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.spaceRegular + 4,
                      vertical: SizeConfig.spaceRegular + 4,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: SizeConfig.normalize(400),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon
                              Container(
                                width: SizeConfig.normalize(140),
                                height: SizeConfig.normalize(140),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.darkBg2 : AppTheme.cardLight,
                                  borderRadius: BorderRadius.circular(SizeConfig.radiusLarge + 4),
                                  border: Border.all(
                                    color: AppTheme.primaryGreen.withOpacity(0.3),
                                    width: SizeConfig.normalize(3),
                                  ),
                                ),
                                child: Icon(
                                  Icons.mark_email_read_rounded,
                                  size: SizeConfig.iconSizeHuge + 20,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              SizedBox(height: SizeConfig.spaceHuge + 8),

                              // Title
                              Text(
                                AppLocalizations().tr('verify_otp'),
                                style: TextStyle(
                                  fontSize: SizeConfig.fontSizeXLarge + 8,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: SizeConfig.spaceSmall + 4),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: SizeConfig.radiusLarge + 4),
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: SizeConfig.fontSizeRegular + 2,
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
                              SizedBox(height: SizeConfig.spaceHuge + 8),

                              // Premium OTP Card
                              PremiumCard(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: SizeConfig.spaceRegular,
                                    vertical: SizeConfig.spaceSmall,
                                  ),
                                  child: Column(
                                    children: [
                                      // OTP Label
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(SizeConfig.spaceSmall),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [AppTheme.primaryGreen, AppTheme.primaryTeal],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(SizeConfig.radiusSmall + 2),
                                            ),
                                            child: Icon(
                                              Icons.pin_rounded,
                                              size: SizeConfig.iconSizeSmall + 4,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: SizeConfig.spaceSmall + 2),
                                          Text(
                                            AppLocalizations().tr('enter_6_digit_code'),
                                            style: TextStyle(
                                              fontSize: SizeConfig.fontSizeRegular + 2,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: SizeConfig.spaceRegular + 8),
                                      
                                      // Modern OTP Input
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final availableWidth = constraints.maxWidth;
                                          final spacing = SizeConfig.spaceSmall;
                                          final totalSpacing = spacing * 5;
                                          final fieldWidth = ((availableWidth - totalSpacing) / 6)
                                              .clamp(SizeConfig.normalize(52), SizeConfig.normalize(68));
                                          final fieldHeight = fieldWidth * 1.18;
                                          
                                          return PinCodeTextField(
                                            appContext: context,
                                            length: 6,
                                            controller: _otpController,
                                            keyboardType: TextInputType.number,
                                            animationType: AnimationType.fade,
                                            enabled: !_isDisposed && !_isNavigating,
                                            animationDuration: const Duration(milliseconds: 300),
                                            enableActiveFill: true,
                                            cursorColor: AppTheme.primaryGreen,
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            textStyle: TextStyle(
                                              fontSize: SizeConfig.fontSizeXLarge + 4,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.primaryGreen,
                                              letterSpacing: 0.5,
                                            ),
                                            pinTheme: PinTheme(
                                              shape: PinCodeFieldShape.box,
                                              borderRadius: BorderRadius.circular(SizeConfig.radiusRegular + 4),
                                              fieldHeight: fieldHeight,
                                              fieldWidth: fieldWidth,
                                              borderWidth: SizeConfig.normalize(2.5),
                                              // Active state (currently typing)
                                              activeColor: AppTheme.primaryGreen,
                                              activeFillColor: isDark 
                                                  ? AppTheme.primaryGreen.withOpacity(0.08)
                                                  : AppTheme.primaryGreen.withOpacity(0.05),
                                              // Selected state (focused)
                                              selectedColor: AppTheme.primaryGreen,
                                              selectedFillColor: isDark 
                                                  ? AppTheme.primaryGreen.withOpacity(0.12)
                                                  : AppTheme.primaryGreen.withOpacity(0.08),
                                              // Inactive state (empty)
                                              inactiveColor: isDark 
                                                  ? AppTheme.primaryGreen.withOpacity(0.15)
                                                  : AppTheme.borderLight,
                                              inactiveFillColor: isDark 
                                                  ? AppTheme.darkBg2
                                                  : AppTheme.cardLight,
                                            ),
                                            boxShadows: [
                                              BoxShadow(
                                                color: AppTheme.primaryGreen.withOpacity(0.1),
                                                blurRadius: SizeConfig.normalize(8),
                                                offset: Offset(0, SizeConfig.normalize(2)),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              if (!mounted || _isDisposed) return;
                                            },
                                          );
                                        },
                                      ),
                                      SizedBox(height: SizeConfig.spaceRegular + 8),

                                      // Verify Button
                                      PremiumGradientButton(
                                        text: AppLocalizations().tr('verify_continue'),
                                        icon: Icons.check_circle_rounded,
                                        onPressed: _verifyOtp,
                                        isLoading: _isLoading,
                                      ),
                                      SizedBox(height: SizeConfig.radiusLarge + 4),

                                      // Resend OTP
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              '${AppLocalizations().tr('didnt_receive_code')} ',
                                              style: TextStyle(
                                                color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                                                fontSize: SizeConfig.fontSizeRegular + 1,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ),
                                          if (_canResend)
                                            InkWell(
                                              onTap: _resendOtp,
                                              borderRadius: BorderRadius.circular(SizeConfig.radiusSmall),
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: SizeConfig.spaceSmall + 2,
                                                  vertical: SizeConfig.spaceTiny + 2,
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.refresh_rounded,
                                                      size: SizeConfig.iconSizeMedium + 2,
                                                      color: AppTheme.primaryGreen,
                                                    ),
                                                    SizedBox(width: SizeConfig.spaceTiny + 1),
                                                    Text(
                                                      AppLocalizations().tr('resend'),
                                                      style: TextStyle(
                                                        color: AppTheme.primaryGreen,
                                                        fontSize: SizeConfig.fontSizeRegular + 1,
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
                                              padding: EdgeInsets.symmetric(
                                                horizontal: SizeConfig.spaceSmall + 2,
                                                vertical: SizeConfig.spaceTiny + 2,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.timer_outlined,
                                                    size: SizeConfig.iconSizeMedium + 2,
                                                    color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                                                  ),
                                                  SizedBox(width: SizeConfig.spaceTiny + 1),
                                                  Text(
                                                    '${_resendTimer}s',
                                                    style: TextStyle(
                                                      color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                                                      fontSize: SizeConfig.fontSizeRegular + 1,
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
                              SizedBox(height: SizeConfig.spaceRegular + 4),

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
