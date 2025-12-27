import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../screens/screens.dart';
import '../../utils/utils.dart';
import '../../providers/providers.dart';
import '../widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _logoAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Logo animation controller
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Fade animation controller
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Logo scale animation
    _logoAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    // Fade in animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeIn,
    ));

    // Start animations and check authentication
    _startAnimations();
  }

  void _startAnimations() async {
    // Start fade animation immediately
    _fadeAnimationController.forward();
    
    // Start logo animation with a slight delay
    await Future.delayed(const Duration(milliseconds: 300));
    _logoAnimationController.forward();

    // Check authentication status
    await _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for splash duration
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    print('🔍 SplashScreen: Checking authentication...');

    // Get auth provider and check if user is already logged in
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.init();

    if (!mounted) return;

    print('🔍 SplashScreen: isAuthenticated = ${authProvider.isAuthenticated}');
    print('🔍 SplashScreen: user exists = ${authProvider.user != null}');
    if (authProvider.user != null) {
      print('🔍 SplashScreen: User ID = ${authProvider.user!.id}');
      print('🔍 SplashScreen: User Email = ${authProvider.user!.email}');
      print('🔍 SplashScreen: User Name = ${authProvider.user!.name}');
      print('🔍 SplashScreen: User Role = ${authProvider.user!.role}');
    }

    // Navigate based on authentication status
    if (authProvider.isAuthenticated && authProvider.user != null) {
      print('✅ SplashScreen: User authenticated, navigating to dashboard...');
      
      // User is already logged in, navigate to appropriate dashboard
      Widget nextScreen;
      
      if (authProvider.user?.role == 'farmer') {
        nextScreen = const FarmerDashboardScreen();
        print('✅ SplashScreen: Navigating to Farmer Dashboard');
      } else {
        nextScreen = const DashboardScreen();
        print('✅ SplashScreen: Navigating to Dashboard');
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      );
    } else {
      print('ℹ️ SplashScreen: User not authenticated, navigating to login...');
      
      // User is not logged in, navigate to login screen
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: PremiumGradientBackground(
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  
                  // Premium Logo Section with Hero Animation
                  ScaleTransition(
                    scale: _logoAnimation,
                    child: Column(
                      children: [
                        // Premium Icon Container for Logo
                        PremiumIconContainer(
                          size: UIConstants.iconContainerLarge,
                          borderRadius: UIConstants.radius3XL,
                          shadowColor: AppTheme.primaryTeal,
                          heroTag: 'app_logo',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              UIConstants.radius3XL - UIConstants.spacingXS,
                            ),
                            child: Image.asset(
                              'assets/images/fulllogo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      UIConstants.radius3XL - UIConstants.spacingXS,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.agriculture_rounded,
                                    size: 80,
                                    color: AppTheme.primaryGreen,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: UIConstants.spacingXXL),
                      
                      // Premium App Name with Gradient
                      GradientText(
                        text: 'Poornasree Connect',
                        fontSize: UIConstants.fontSize7XL,
                      ),
                      const SizedBox(height: UIConstants.spacingM),
                      
                      // App Tagline
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: UIConstants.spacingXL,
                        ),
                        child: Text(
                          'Connecting Farmers to Success',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: UIConstants.fontSizeL,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(flex: 1),
                
                // Loading Section with Premium Spinner
                Column(
                  children: [
                    // White flower spinner for green background
                    const FlowerSpinner(
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: UIConstants.spacingL),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: UIConstants.spacingL,
                        vertical: UIConstants.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(UIConstants.radiusXL),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Loading your dashboard...',
                        style: TextStyle(
                          fontSize: UIConstants.fontSizeM,
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const Spacer(flex: 1),
                
                // Premium Footer Section
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: UIConstants.spacingXL,
                    left: UIConstants.spacingXL,
                    right: UIConstants.spacingXL,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: UIConstants.spacingL,
                          vertical: UIConstants.spacingM,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(UIConstants.radiusL),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 20,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(width: UIConstants.spacingS),
                            Text(
                              'Powered by Poornasree Equipments',
                              style: TextStyle(
                                fontSize: UIConstants.fontSizeM,
                                color: Colors.white.withOpacity(0.95),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: UIConstants.spacingM),
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          fontSize: UIConstants.fontSizeS,
                          color: Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
     ) );
  }
}