import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize auth provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<AuthProvider>(context, listen: false).initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while initializing
        if (!_isInitialized || authProvider.isLoading) {
          return Scaffold(
            backgroundColor: AppColors.primaryBackground,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Yükleniyor...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // User is authenticated, show main app
        if (authProvider.isAuthenticated && authProvider.currentUser != null) {
          return const HomeScreen();
        }

        // User is not authenticated, show login screen
        return const LoginScreen();
      },
    );
  }
} 