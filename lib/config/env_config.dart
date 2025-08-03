import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static const String _geminiApiKeyEnv = 'GEMINI_API_KEY';
  static const String _firebaseApiKeyEnv = 'FIREBASE_API_KEY';
  static const String _firebaseAppIdEnv = 'FIREBASE_APP_ID';
  static const String _firebaseProjectIdEnv = 'FIREBASE_PROJECT_ID';
  static const String _firebaseSenderIdEnv = 'FIREBASE_SENDER_ID';
  static const String _firebaseStorageBucketEnv = 'FIREBASE_STORAGE_BUCKET';

  // Gemini API Configuration
  static String get geminiApiKey {
    final envKey = dotenv.env[_geminiApiKeyEnv];
    if (envKey != null && envKey.isNotEmpty && envKey != 'YOUR_GEMINI_API_KEY') {
      return envKey;
    }
    
    // Secure fallback - don't expose actual keys in code
    throw Exception('GEMINI_API_KEY environment variable is not configured. Please add it to your .env file.');
  }

  // Firebase Configuration
  static String get firebaseApiKey {
    final envKey = dotenv.env[_firebaseApiKeyEnv];
    if (envKey != null && envKey.isNotEmpty && envKey != 'YOUR_FIREBASE_API_KEY') {
      return envKey;
    }
    
    throw Exception('FIREBASE_API_KEY environment variable is not configured. Please add it to your .env file.');
  }

  static String get firebaseAppId {
    final envKey = dotenv.env[_firebaseAppIdEnv];
    if (envKey != null && envKey.isNotEmpty && envKey != 'YOUR_FIREBASE_APP_ID') {
      return envKey;
    }
    
    throw Exception('FIREBASE_APP_ID environment variable is not configured. Please add it to your .env file.');
  }

  static String get firebaseProjectId {
    final envKey = dotenv.env[_firebaseProjectIdEnv];
    if (envKey != null && envKey.isNotEmpty && envKey != 'YOUR_FIREBASE_PROJECT_ID') {
      return envKey;
    }
    
    throw Exception('FIREBASE_PROJECT_ID environment variable is not configured. Please add it to your .env file.');
  }

  static String get firebaseSenderId {
    final envKey = dotenv.env[_firebaseSenderIdEnv];
    if (envKey != null && envKey.isNotEmpty && envKey != 'YOUR_FIREBASE_SENDER_ID') {
      return envKey;
    }
    
    throw Exception('FIREBASE_SENDER_ID environment variable is not configured. Please add it to your .env file.');
  }

  static String get firebaseStorageBucket {
    final envKey = dotenv.env[_firebaseStorageBucketEnv];
    if (envKey != null && envKey.isNotEmpty && envKey != 'YOUR_FIREBASE_STORAGE_BUCKET') {
      return envKey;
    }
    
    throw Exception('FIREBASE_STORAGE_BUCKET environment variable is not configured. Please add it to your .env file.');
  }

  // Validation methods
  static bool get isGeminiConfigured {
    try {
      final key = geminiApiKey;
      return key.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static bool get isFirebaseConfigured {
    try {
      final apiKey = firebaseApiKey;
      final appId = firebaseAppId;
      final projectId = firebaseProjectId;
      return apiKey.isNotEmpty && appId.isNotEmpty && projectId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get all environment variables for debugging (without exposing actual keys)
  static Map<String, String> get allEnvVars {
    return {
      'GEMINI_API_KEY': isGeminiConfigured ? '***CONFIGURED***' : '***NOT_CONFIGURED***',
      'FIREBASE_API_KEY': isFirebaseConfigured ? '***CONFIGURED***' : '***NOT_CONFIGURED***',
      'FIREBASE_APP_ID': isFirebaseConfigured ? '***CONFIGURED***' : '***NOT_CONFIGURED***',
      'FIREBASE_PROJECT_ID': isFirebaseConfigured ? '***CONFIGURED***' : '***NOT_CONFIGURED***',
      'FIREBASE_SENDER_ID': isFirebaseConfigured ? '***CONFIGURED***' : '***NOT_CONFIGURED***',
      'FIREBASE_STORAGE_BUCKET': isFirebaseConfigured ? '***CONFIGURED***' : '***NOT_CONFIGURED***',
    };
  }
} 