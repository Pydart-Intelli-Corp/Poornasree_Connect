import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendOtp(_emailController.text.trim());

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      Navigator.push(
        context,
        PageTransition(
          child: OtpScreen(email: _emailController.text.trim()),
          type: TransitionType.slideAndFade,
        ),
      );
    } else if (mounted) {
      final errorMsg = authProvider.errorMessage ?? 'Failed to send OTP';
      String submessage = 'Please try again';
      
      if (errorMsg.toLowerCase().contains('network')) {
        submessage = 'Check your internet connection and retry';
      } else if (errorMsg.toLowerCase().contains('not found') || 
                 errorMsg.toLowerCase().contains('not registered')) {
        submessage = 'This email is not registered in the system';
      } else if (errorMsg.toLowerCase().contains('invalid email')) {
        submessage = 'Please enter a valid email address';
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > UIConstants.breakpointTablet;

    return Scaffold(
      body: PremiumGradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isLargeScreen ? UIConstants.spacing3XL : UIConstants.spacingL,
                vertical: UIConstants.spacingXL,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isLargeScreen ? UIConstants.maxWidthMobile : double.infinity,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Premium Logo Container
                        PremiumIconContainer(
                          size: UIConstants.iconContainerLarge,
                          borderRadius: UIConstants.radius3XL,
                          heroTag: 'app_logo',
                          child: Image.asset(
                            'assets/images/fulllogo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.agriculture_rounded,
                                size: 70,
                                color: AppTheme.primaryGreen,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: UIConstants.spacingXXL),

                        // Welcome Text
                        const GradientText(
                          text: 'Welcome Back',
                          fontSize: UIConstants.fontSize7XL,
                        ),
                        SizedBox(height: UIConstants.spacingS),
                        Text(
                          'Sign in to continue to ${AppConstants.appName}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: UIConstants.fontSizeL,
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: UIConstants.spacing4XL),

                        // Premium Login Card
                        PremiumCard(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Email Field
                                PremiumTextField(
                                  controller: _emailController,
                                  labelText: 'Email Address',
                                  hintText: 'your.email@example.com',
                                  icon: Icons.email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: UIConstants.spacingXL),

                                // Premium Send OTP Button
                                PremiumGradientButton(
                                  text: 'Send OTP',
                                  icon: Icons.arrow_forward_rounded,
                                  onPressed: _sendOtp,
                                  isLoading: _isLoading,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: UIConstants.spacingXL),

                        // Info Container
                        const InfoContainer(
                          icon: Icons.info_outline_rounded,
                          text: 'A one-time password will be sent to your email address',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
