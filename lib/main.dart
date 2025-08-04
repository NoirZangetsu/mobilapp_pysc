import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/learning_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/app_colors.dart';
import 'utils/app_text_styles.dart';
import 'config/env_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");
  
  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: EnvConfig.firebaseApiKey,
        appId: EnvConfig.firebaseAppId,
        messagingSenderId: EnvConfig.firebaseMessagingSenderId,
        projectId: EnvConfig.firebaseProjectId,
        storageBucket: EnvConfig.firebaseStorageBucket,
      ),
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LearningProvider()),
      ],
      child: MaterialApp(
        title: 'EduVoice AI',
        debugShowCheckedModeBanner: false,
        theme: _buildAppTheme(),
        home: const SplashScreen(),
      ),
    );
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: AppColors.primaryBackground,
      fontFamily: AppTextStyles.fontFamily,
      appBarTheme: _buildAppBarTheme(),
      dialogTheme: _buildDialogTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
    );
  }

  AppBarTheme _buildAppBarTheme() {
    return AppBarTheme(
      backgroundColor: AppColors.surfaceBackground,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.headingMedium,
      iconTheme: const IconThemeData(color: AppColors.headingText),
    );
  }

  DialogThemeData _buildDialogTheme() {
    return DialogThemeData(
      backgroundColor: AppColors.surfaceBackground,
      titleTextStyle: AppTextStyles.headingSmall,
      contentTextStyle: AppTextStyles.bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryButton,
        foregroundColor: AppColors.headingText,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentBlue,
      ),
    );
  }

  InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputFocusedBorder, width: 2),
      ),
      labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.inputLabel),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
