import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';
import '../../l10n/l10n.dart';
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
      String message = 'Error Occurred';
      String submessage = 'Please try again';
      
      if (errorMsg.toLowerCase().contains('network') || 
          errorMsg.toLowerCase().contains('connection')) {
        message = 'Connection Failed';
        submessage = 'Check your internet connection and retry';
      } else if (errorMsg.toLowerCase().contains('not found') || 
                 errorMsg.toLowerCase().contains('not registered') ||
                 (errorMsg.toLowerCase().contains('contact') && 
                  errorMsg.toLowerCase().contains('supervisor'))) {
        message = 'Email Not Registered';
        submessage = 'Your email address is not registered in the system. Please contact your admin or supervisor to add your account';
      } else if (errorMsg.toLowerCase().contains('invalid email')) {
        message = 'Invalid Email';
        submessage = 'Please enter a valid email address';
      } else if (errorMsg.toLowerCase().contains('server') || 
                 errorMsg.toLowerCase().contains('failed to send')) {
        message = 'Server Error';
        submessage = 'Server is temporarily unavailable. Please try again later';
      } else if (errorMsg.toLowerCase().contains('try again')) {
        message = 'Request Failed';
        submessage = 'Something went wrong, please try again';
      } else {
        message = 'Error Occurred';
        submessage = errorMsg;
      }
      
      CustomSnackbar.showError(
        context,
        message: message,
        submessage: submessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations();
    final horizontalPadding = ResponsiveHelper.getHorizontalPadding(context);
    final verticalPadding = ResponsiveHelper.getVerticalPadding(context);
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);

    return Scaffold(
      body: PremiumGradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxWidth,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Container(
                          width: ResponsiveHelper.getIconSize(context, 120),
                          height: ResponsiveHelper.getIconSize(context, 120),
                          decoration: BoxDecoration(
                            color: AppTheme.darkBg2,
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getSpacing(context, 20),
                            ),
                            border: Border.all(
                              color: AppTheme.primaryGreen.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          padding: EdgeInsets.all(
                            ResponsiveHelper.getSpacing(context, 20),
                          ),
                          child: Image.asset(
                            'assets/images/fulllogo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.agriculture_rounded,
                                size: ResponsiveHelper.getIconSize(context, 60),
                                color: AppTheme.primaryGreen,
                              );
                            },
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getSpacing(context, 40)),

                        // Welcome Text
                        Text(
                          l10n.tr('welcome_back'),
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getFontSize(context, 32),
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getSpacing(context, 8)),
                        Text(
                          l10n.tr('sign_in_to_continue'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getFontSize(context, 15),
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getSpacing(context, 40)),

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
                                  labelText: l10n.tr('email_address'),
                                  hintText: 'your.email@example.com',
                                  icon: Icons.email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.tr('please_enter_email');
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return l10n.tr('enter_valid_email');
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: UIConstants.spacingXL),

                                // Premium Send OTP Button
                                PremiumGradientButton(
                                  text: l10n.tr('send_otp'),
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
                        InfoContainer(
                          icon: Icons.info_outline_rounded,
                          text: l10n.tr('otp_will_be_sent'),
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
