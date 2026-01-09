import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothService;
import '../../screens/screens.dart';
import '../../utils/utils.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
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
    // Wait for splash duration (reduced for faster testing)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
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

      // Request Bluetooth and Location permissions
      print('📍 SplashScreen: Requesting Bluetooth & Location permissions...');
      final bluetoothService = BluetoothService();
      await bluetoothService.requestPermissions();
      print('✅ SplashScreen: Permissions requested');

      // Check if Bluetooth is enabled
      final isBluetoothOn = await bluetoothService.isBluetoothEnabled();
      if (!isBluetoothOn && mounted) {
        print('📶 SplashScreen: Bluetooth is OFF, showing enable prompt...');
        await _showBluetoothEnableDialog();
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

        if (!mounted) return;

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
        
        if (!mounted) return;

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
    } catch (e, stackTrace) {
      print('❌ SplashScreen Navigation Error: $e');
      print('❌ Stack trace: $stackTrace');
      
      // Fallback to login screen on error
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0A0E27),
                    const Color(0xFF1A1F3A),
                    const Color(0xFF0F172A),
                  ]
                : [
                    const Color(0xFFFAFAFA),
                    const Color(0xFFF5F5F5),
                    const Color(0xFFEFEFEF),
                  ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                // Subtle grid pattern overlay
                Positioned.fill(
                  child: Opacity(
                    opacity: isDark ? 0.03 : 0.02,
                    child: CustomPaint(
                      painter: GridPainter(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                
                // Main content
                Column(
                  children: [
                    // Dairy Management System at top
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryGreen.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Dairy Management System',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                            color: AppTheme.primaryGreen.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Logo centered
                    ScaleTransition(
                      scale: _logoAnimation,
                      child: Image.asset(
                        'assets/images/fulllogo.png',
                        width: 160,
                        height: 160,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(24),
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
                    
                    const Spacer(),
                    
                    // Loading section - minimal
                    Column(
                      children: [
                        const FlowerSpinner(
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Initializing...',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.5,
                            color: isDark 
                                ? Colors.white.withOpacity(0.5)
                                : Colors.black.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Footer - minimal
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryGreen.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Poornasree Equipments',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: isDark
                                    ? Colors.white.withOpacity(0.6)
                                    : Colors.black.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'v1.0.0',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white.withOpacity(0.3)
                                : Colors.black.withOpacity(0.2),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
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

  /// Show dialog to prompt user to enable Bluetooth
  Future<void> _showBluetoothEnableDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkBg2 : AppTheme.cardLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bluetooth_disabled,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Enable Bluetooth',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bluetooth is currently turned off. This app uses Bluetooth to connect with Lactosure milk testing machines.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please enable Bluetooth from your device settings to use all features.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Later',
                style: TextStyle(
                  color: isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                // On Android, user needs to manually enable Bluetooth from settings
                // We can't programmatically turn it on due to security restrictions
                // The FlutterBluePlus package will show a system dialog on Android
                try {
                  // Request to turn on Bluetooth (will show system dialog on Android)
                  if (Theme.of(context).platform == TargetPlatform.android) {
                    await FlutterBluePlus.turnOn();
                  }
                } catch (e) {
                  print('Error requesting Bluetooth enable: $e');
                }
              },
              icon: const Icon(Icons.bluetooth, size: 18),
              label: const Text('Enable Bluetooth'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Grid painter for subtle tech background
class GridPainter extends CustomPainter {
  final Color color;

  GridPainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.05)
      ..strokeWidth = 0.5;

    const gridSize = 40.0;

    // Draw vertical lines
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}