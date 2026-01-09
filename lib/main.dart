import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/widgets.dart';
import 'providers/providers.dart';
import 'utils/utils.dart';
import 'services/services.dart';
import 'l10n/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();
  
  // Load shift settings on startup
  await ShiftSettingsService().loadSettings();
  
  // Load locale settings
  await AppLocalizations().loadLocale();
  
  // Initialize connectivity service with periodic checks
  ConnectivityService().startPeriodicCheck(interval: const Duration(seconds: 30));
  
  runApp(MyApp(themeProvider: themeProvider));
}

class MyApp extends StatefulWidget {
  final ThemeProvider themeProvider;
  
  const MyApp({
    super.key,
    required this.themeProvider,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Listen to locale changes and rebuild
    AppLocalizations().addListener(_onLocaleChange);
    // Listen to theme changes
    widget.themeProvider.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    AppLocalizations().removeListener(_onLocaleChange);
    widget.themeProvider.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onLocaleChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onThemeChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations();
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => widget.themeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: l10n.tr('app_name'),
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
            builder: (context, child) {
              // Lock text scale factor to 1.0 to prevent system font size from affecting layout
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.noScaling,
                  boldText: false,
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
