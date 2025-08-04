import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // API Keys - Load from environment variables
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get googleTtsApiKey => dotenv.env['GOOGLE_TTS_API_KEY'] ?? '';
  
  // Firebase configuration
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';
  static String get firebaseMessagingSenderId => dotenv.env['FIREBASE_SENDER_ID'] ?? '';
  static String get firebaseSenderId => dotenv.env['FIREBASE_SENDER_ID'] ?? '';
  static String get firebaseStorageBucket => dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
  
  // App configuration
  static const String appName = 'EduVoice AI';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI-powered educational voice assistant';
  
  // Feature flags
  static const bool enableTTS = true;
  static const bool enablePodcastCreation = true;
  static const bool enableFlashcardCreation = true;
  static const bool enableDocumentProcessing = true;

  // Validation methods
  static bool get isGeminiConfigured {
    return geminiApiKey.isNotEmpty && geminiApiKey != 'YOUR_GEMINI_API_KEY';
  }

  static bool get isFirebaseConfigured {
    return firebaseApiKey.isNotEmpty && 
           firebaseAppId.isNotEmpty && 
           firebaseProjectId.isNotEmpty &&
           firebaseApiKey != 'YOUR_FIREBASE_API_KEY' &&
           firebaseAppId != 'YOUR_FIREBASE_APP_ID' &&
           firebaseProjectId != 'YOUR_FIREBASE_PROJECT_ID';
  }
} 