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

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _canResend = false;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
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
    
    if (_otpController.text.length != 6) {
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
    final success = await authProvider.verifyOtp(widget.email, _otpController.text);

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
        PageTransition(
          child: nextScreen,
          type: TransitionType.slideAndFade,
        ),
        (route) => false,
      );
    } else if (mounted) {
      // Show error message
      CustomSnackbar.showError(
        context,
        message: authProvider.errorMessage ?? 'Invalid OTP',
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
      _startResendTimer();
      CustomSnackbar.showSuccess(
        context,
        message: 'OTP sent successfully',
      );
    } else if (mounted) {
      CustomSnackbar.showError(
        context,
        message: authProvider.errorMessage ?? 'Failed to resend OTP',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryGreen,
              AppTheme.primaryTeal,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/flower.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.mail_outline,
                                size: 40,
                                color: AppTheme.primaryGreen,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      const Text(
                        'Enter OTP',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We sent a code to ${widget.email}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // OTP Form Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // PIN Code Fields
                            PinCodeTextField(
                              appContext: context,
                              length: 6,
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              animationType: AnimationType.fade,
                              pinTheme: PinTheme(
                                shape: PinCodeFieldShape.box,
                                borderRadius: BorderRadius.circular(12),
                                fieldHeight: 56,
                                fieldWidth: 45,
                                activeFillColor: Colors.white,
                                selectedFillColor: Colors.white,
                                inactiveFillColor: Colors.white,
                                activeColor: AppTheme.primaryGreen,
                                selectedColor: AppTheme.primaryGreen,
                                inactiveColor: Colors.grey.shade300,
                              ),
                              animationDuration: const Duration(milliseconds: 200),
                              backgroundColor: Colors.transparent,
                              enableActiveFill: true,
                              onCompleted: (code) {
                                _verifyOtp();
                              },
                              onChanged: (value) {},
                            ),
                            const SizedBox(height: 24),

                            // Verify Button
                            CustomButton(
                              text: 'Verify OTP',
                              onPressed: _isLoading ? null : _verifyOtp,
                              isLoading: _isLoading,
                              isFullWidth: true,
                            ),
                            const SizedBox(height: 16),

                            // Resend OTP
                            CustomButton(
                              text: _canResend
                                  ? 'Resend OTP'
                                  : 'Resend OTP in $_resendTimer seconds',
                              onPressed: _canResend && !_isLoading ? _resendOtp : null,
                            ),
                          ],
                        ),
                      ),
                    ],
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
