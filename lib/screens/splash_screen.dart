import 'package:flutter/material.dart';
import '../core/models/user_model.dart';
import '../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'student/student_dashboard_screen.dart';
import 'expert/expert_dashboard_screen.dart';
import 'allocator/allocator_dashboard_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Add small delay for branding splash
    await Future.delayed(const Duration(milliseconds: 900));
    final auth = AuthService();
    await auth.init();

    if (!mounted) return;

    if (auth.isAuthenticated && auth.currentUser != null) {
      _navigateToPortal(auth.currentUser!);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _navigateToPortal(UserModel user) {
    Widget target;
    switch (user.role.toLowerCase()) {
      case 'admin':
        target = AdminDashboardScreen(user: user);
        break;
      case 'allocator':
        target = AllocatorDashboardScreen(user: user);
        break;
      case 'expert':
        target = ExpertDashboardScreen(user: user);
        break;
      default:
        target = StudentDashboardScreen(user: user);
        break;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => target),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ace Assignment Helps',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMain,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Portal Mobile Application',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textDim,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
