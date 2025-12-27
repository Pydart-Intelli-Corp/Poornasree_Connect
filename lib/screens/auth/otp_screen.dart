import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'dart:async';
import '../../providers/providers.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';
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
    _animationController.dispose();
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();

    if (!mounted) return;

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
        if (mounted) {
          setState(() {
            _canResend = true;
          });
        }
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (!mounted) return;

    // Store OTP value before any async operations
    final otpText = _otpController.text;

    if (otpText.length != 6) {
      CustomSnackbar.showError(
        context,
        message: 'Please enter a valid 6-digit OTP',
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyOtp(widget.email, otpText);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      // Navigate to appropriate dashboard based on role
      final user = authProvider.user;
      Widget nextScreen;

      if (user?.role == 'farmer') {
        nextScreen = const FarmerDashboardScreen();
      } else {
        nextScreen = const DashboardScreen();
      }

      Navigator.pushAndRemoveUntil(
        context,
        PageTransition(child: nextScreen, type: TransitionType.slideAndFade),
        (route) => false,
      );
    } else if (mounted) {
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
    if (!_canResend || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendOtp(widget.email);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      if (mounted) _otpController.clear(); // Clear the OTP field
      _startResendTimer();
      CustomSnackbar.showSuccess(
        context,
        message: 'OTP sent successfully',
        submessage: 'Check your email for the verification code',
      );
    } else if (mounted) {
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
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > UIConstants.breakpointTablet;

    return Scaffold(
      body: PremiumGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Premium App Bar
              Padding(
                padding: const EdgeInsets.all(UIConstants.spacingM),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen
                          ? UIConstants.spacing3XL
                          : UIConstants.spacingL,
                      vertical: UIConstants.spacingL,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isLargeScreen
                                ? UIConstants.maxWidthMobile
                                : double.infinity,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Premium Icon Container
                              PremiumIconContainer(
                                size: UIConstants.iconContainerMedium,
                                borderRadius: UIConstants.radiusXXL,
                                shadowColor: AppTheme.primaryTeal,
                                heroTag: 'otp_icon',
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGreen
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(
                                          UIConstants.radiusXL,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.mark_email_read_rounded,
                                      size: 45,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: UIConstants.spacingXXL),

                              // Title
                              const GradientText(
                                text: 'Verify OTP',
                                fontSize: UIConstants.fontSize6XL,
                              ),
                              const SizedBox(height: UIConstants.spacingS),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: UIConstants.radiusXL,
                                ),
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: UIConstants.fontSizeL,
                                      color: Colors.white.withOpacity(0.85),
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text:
                                            'We sent a verification code to\n',
                                      ),
                                      TextSpan(
                                        text: widget.email,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: UIConstants.spacing4XL),

                              // Premium OTP Card
                              PremiumCard(
                                child: Column(
                                  children: [
                                    // OTP Input
                                    PinCodeTextField(
                                      appContext: context,
                                      length: 6,
                                      controller: _otpController,
                                      keyboardType: TextInputType.number,
                                      animationType: AnimationType.scale,
                                      animationDuration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      enableActiveFill: true,
                                      textStyle: const TextStyle(
                                        fontSize: UIConstants.fontSize3XL,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryGreen,
                                      ),
                                      pinTheme: PinTheme(
                                        shape: PinCodeFieldShape.box,
                                        borderRadius: BorderRadius.circular(
                                          UIConstants.radiusM,
                                        ),
                                        fieldHeight: 60,
                                        fieldWidth: 50,
                                        borderWidth: 2,
                                        activeColor: AppTheme.primaryGreen,
                                        selectedColor: AppTheme.primaryTeal,
                                        inactiveColor: Colors.grey[300]!,
                                        activeFillColor: AppTheme.primaryGreen
                                            .withOpacity(0.05),
                                        selectedFillColor: AppTheme.primaryTeal
                                            .withOpacity(0.05),
                                        inactiveFillColor: Colors.grey[50]!,
                                      ),
                                      onChanged: (value) {},
                                    ),
                                    const SizedBox(
                                      height: UIConstants.spacingXL,
                                    ),

                                    // Verify Button
                                    PremiumGradientButton(
                                      text: 'Verify & Continue',
                                      icon: Icons.check_circle_rounded,
                                      onPressed: _verifyOtp,
                                      isLoading: _isLoading,
                                    ),
                                    const SizedBox(
                                      height: UIConstants.spacingL,
                                    ),

                                    // Resend OTP
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Didn\'t receive code? ',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: UIConstants.fontSizeM,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (_canResend)
                                          InkWell(
                                            onTap: _resendOtp,
                                            borderRadius: BorderRadius.circular(
                                              UIConstants.radiusS,
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal:
                                                        UIConstants.radiusS,
                                                    vertical: 4,
                                                  ),
                                              child: ShaderMask(
                                                shaderCallback: (bounds) =>
                                                    const LinearGradient(
                                                      colors: [
                                                        AppTheme.primaryGreen,
                                                        AppTheme.primaryTeal,
                                                      ],
                                                    ).createShader(bounds),
                                                child: const Text(
                                                  'Resend',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        UIConstants.fontSizeM,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: UIConstants.spacingS,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    UIConstants.radiusS,
                                                  ),
                                            ),
                                            child: Text(
                                              'Resend in $_resendTimer s',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: UIConstants.fontSizeS,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: UIConstants.spacingXL),

                              // Security Info
                              const InfoContainer(
                                icon: Icons.shield_outlined,
                                text:
                                    'Your information is secured with end-to-end encryption',
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
