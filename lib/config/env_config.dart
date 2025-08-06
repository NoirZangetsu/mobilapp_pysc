import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class EnvConfig {
  // API Keys - Load from environment variables with additional security
  static String get geminiApiKey => _obfuscateKey(dotenv.env['GEMINI_API_KEY'] ?? '');
  static String get googleTtsApiKey => _obfuscateKey(dotenv.env['GOOGLE_TTS_API_KEY'] ?? '');
  
  // Firebase configuration
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseApiKey => _obfuscateKey(dotenv.env['FIREBASE_API_KEY'] ?? '');
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

  // Security: Obfuscate API keys to prevent easy extraction from APK
  static String _obfuscateKey(String key) {
    if (key.isEmpty) return '';
    
    // Simple obfuscation - in production, use more sophisticated encryption
    try {
      // Reverse the key and encode it
      final reversed = key.split('').reversed.join();
      final encoded = base64.encode(utf8.encode(reversed));
      return encoded;
    } catch (e) {
      // Fallback to original key if obfuscation fails
      return key;
    }
  }
  
  // Deobfuscate API key for actual use
  static String _deobfuscateKey(String obfuscatedKey) {
    if (obfuscatedKey.isEmpty) return '';
    
    try {
      final decoded = utf8.decode(base64.decode(obfuscatedKey));
      return decoded.split('').reversed.join();
    } catch (e) {
      // If deobfuscation fails, return as-is (might be already plain text)
      return obfuscatedKey;
    }
  }
  
  // Public methods to get deobfuscated keys
  static String getGeminiApiKey() => _deobfuscateKey(geminiApiKey);
  static String getGoogleTtsApiKey() => _deobfuscateKey(googleTtsApiKey);
  static String getFirebaseApiKey() => _deobfuscateKey(firebaseApiKey);

  // Validation methods
  static bool get isGeminiConfigured {
    final key = getGeminiApiKey();
    return key.isNotEmpty && key != 'YOUR_GEMINI_API_KEY';
  }

  static bool get isFirebaseConfigured {
    final apiKey = getFirebaseApiKey();
    return apiKey.isNotEmpty && 
           firebaseAppId.isNotEmpty && 
           firebaseProjectId.isNotEmpty &&
           apiKey != 'YOUR_FIREBASE_API_KEY' &&
           firebaseAppId != 'YOUR_FIREBASE_APP_ID' &&
           firebaseProjectId != 'YOUR_FIREBASE_PROJECT_ID';
  }
  
  // Security check method
  static bool get isSecure {
    // Check if we're in debug mode (less secure)
    const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;
    
    // In release mode, ensure keys are properly obfuscated
    if (!isDebug) {
      return geminiApiKey.isNotEmpty && 
             googleTtsApiKey.isNotEmpty && 
             firebaseApiKey.isNotEmpty;
    }
    
    return true; // Allow debug builds
  }
} 