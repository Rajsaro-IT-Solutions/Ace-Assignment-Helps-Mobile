import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/config/api_config.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize configurations and auth state
  await ApiConfig.init();
  await AuthService().init();

  runApp(const AceAssignmentPortalApp());
}

class AceAssignmentPortalApp extends StatelessWidget {
  const AceAssignmentPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ace Assignment Helps - Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
