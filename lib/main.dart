import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/driver_login_screen.dart';
import 'screens/dashboard/driver_dashboard_screen.dart';
import 'services/driver_auth_service.dart';
import 'services/driver_settings_service.dart';
import 'services/trip_engine.dart';
import 'services/trip_history_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientation to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize active driver state cleanly
  final activeDriver = DriverAuthService().activeDriver;
  if (activeDriver != null) {
    TripEngine().onDriverAuthenticated(activeDriver);
    TripHistoryService().onDriverAuthenticated(activeDriver);
  }

  runApp(const CityRideDriverApp());
}

class CityRideDriverApp extends StatefulWidget {
  const CityRideDriverApp({super.key});

  @override
  State<CityRideDriverApp> createState() => _CityRideDriverAppState();
}

class _CityRideDriverAppState extends State<CityRideDriverApp> {
  final _settingsService = DriverSettingsService();
  final _authService = DriverAuthService();

  @override
  void initState() {
    super.initState();
    _settingsService.addListener(_onChanged);
    _authService.addListener(_onChanged);
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onChanged);
    _authService.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isNightHud = _settingsService.isNightHudMode;
    final isAuthenticated = _authService.isAuthenticated;

    return MaterialApp(
      title: 'CITYRIDE Driver Console',
      debugShowCheckedModeBanner: false,
      theme: CityRideTheme.lightTheme,
      darkTheme: CityRideTheme.darkTheme,
      themeMode: isNightHud ? ThemeMode.dark : ThemeMode.light,
      home: isAuthenticated ? const DriverDashboardScreen() : const DriverLoginScreen(),
    );
  }
}
