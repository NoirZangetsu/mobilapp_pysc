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
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }
    
    // Fallback for development
    return 'YOUR_GEMINI_API_KEY';
  }

  // Firebase Configuration
  static String get firebaseApiKey {
    final envKey = dotenv.env[_firebaseApiKeyEnv];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }
    
    return 'YOUR_FIREBASE_API_KEY';
  }

  static String get firebaseAppId {
    final envKey = dotenv.env[_firebaseAppIdEnv];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }
    
    return 'YOUR_FIREBASE_APP_ID';
  }

  static String get firebaseProjectId {
    final envKey = dotenv.env[_firebaseProjectIdEnv];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }
    
    return 'YOUR_FIREBASE_PROJECT_ID';
  }

  static String get firebaseSenderId {
    final envKey = dotenv.env[_firebaseSenderIdEnv];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }
    
    return 'YOUR_FIREBASE_SENDER_ID';
  }

  static String get firebaseStorageBucket {
    final envKey = dotenv.env[_firebaseStorageBucketEnv];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }
    
    return 'YOUR_FIREBASE_STORAGE_BUCKET';
  }

  // Validation methods
  static bool get isGeminiConfigured {
    return geminiApiKey != 'YOUR_GEMINI_API_KEY';
  }

  static bool get isFirebaseConfigured {
    return firebaseApiKey != 'YOUR_FIREBASE_API_KEY' &&
           firebaseAppId != 'YOUR_FIREBASE_APP_ID' &&
           firebaseProjectId != 'YOUR_FIREBASE_PROJECT_ID';
  }

  // Get all environment variables for debugging
  static Map<String, String> get allEnvVars {
    return {
      'GEMINI_API_KEY': geminiApiKey,
      'FIREBASE_API_KEY': firebaseApiKey,
      'FIREBASE_APP_ID': firebaseAppId,
      'FIREBASE_PROJECT_ID': firebaseProjectId,
      'FIREBASE_SENDER_ID': firebaseSenderId,
      'FIREBASE_STORAGE_BUCKET': firebaseStorageBucket,
    };
  }
} 