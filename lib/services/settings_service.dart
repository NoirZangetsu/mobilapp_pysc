import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsService {
  static const String _notificationSettingsKey = 'notification_settings';
  static const String _privacySettingsKey = 'privacy_settings';
  static const String _userPreferencesKey = 'user_preferences';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Notification Settings
  Future<Map<String, bool>> getNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_notificationSettingsKey);
      
      if (settingsJson != null) {
        final settings = json.decode(settingsJson) as Map<String, dynamic>;
        return settings.map((key, value) => MapEntry(key, value as bool));
      }
      
      // Default settings
      return {
        'voice_notifications': true,
        'flashcard_reminders': false,
        'podcast_notifications': true,
      };
    } catch (e) {
      print('Error getting notification settings: $e');
      return {
        'voice_notifications': true,
        'flashcard_reminders': false,
        'podcast_notifications': true,
      };
    }
  }

  Future<void> updateNotificationSetting(String setting, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentSettings = await getNotificationSettings();
      
      currentSettings[setting] = value;
      
      await prefs.setString(_notificationSettingsKey, json.encode(currentSettings));
      
      // Sync with Firestore if user is logged in
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('notifications')
            .set({
          'settings': currentSettings,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
      
      print('Notification setting updated: $setting = $value');
    } catch (e) {
      print('Error updating notification setting: $e');
      throw Exception('Bildirim ayarı güncellenemedi: $e');
    }
  }

  // Privacy Settings
  Future<Map<String, bool>> getPrivacySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_privacySettingsKey);
      
      if (settingsJson != null) {
        final settings = json.decode(settingsJson) as Map<String, dynamic>;
        return settings.map((key, value) => MapEntry(key, value as bool));
      }
      
      // Default settings
      return {
        'data_collection': true,
        'analytics': false,
        'personalization': true,
      };
    } catch (e) {
      print('Error getting privacy settings: $e');
      return {
        'data_collection': true,
        'analytics': false,
        'personalization': true,
      };
    }
  }

  Future<void> updatePrivacySetting(String setting, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentSettings = await getPrivacySettings();
      
      currentSettings[setting] = value;
      
      await prefs.setString(_privacySettingsKey, json.encode(currentSettings));
      
      // Sync with Firestore if user is logged in
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('privacy')
            .set({
          'settings': currentSettings,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
      
      print('Privacy setting updated: $setting = $value');
    } catch (e) {
      print('Error updating privacy setting: $e');
      throw Exception('Gizlilik ayarı güncellenemedi: $e');
    }
  }

  // User Preferences
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString(_userPreferencesKey);
      
      if (preferencesJson != null) {
        return json.decode(preferencesJson) as Map<String, dynamic>;
      }
      
      // Default preferences
      return {
        'theme': 'system',
        'language': 'tr',
        'voice_style': 'professional',
        'content_length': 'detailed',
      };
    } catch (e) {
      print('Error getting user preferences: $e');
      return {
        'theme': 'system',
        'language': 'tr',
        'voice_style': 'professional',
        'content_length': 'detailed',
      };
    }
  }

  Future<void> updateUserPreference(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentPreferences = await getUserPreferences();
      
      currentPreferences[key] = value;
      
      await prefs.setString(_userPreferencesKey, json.encode(currentPreferences));
      
      // Sync with Firestore if user is logged in
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('preferences')
            .set({
          'preferences': currentPreferences,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
      
      print('User preference updated: $key = $value');
    } catch (e) {
      print('Error updating user preference: $e');
      throw Exception('Kullanıcı tercihi güncellenemedi: $e');
    }
  }

  // Data Deletion
  Future<void> deleteUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Delete from Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('podcasts')
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('flashcardDecks')
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('documents')
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      // Delete user document
      await _firestore
          .collection('users')
          .doc(user.uid)
          .delete();

      // Clear local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      print('User data deleted successfully');
    } catch (e) {
      print('Error deleting user data: $e');
      throw Exception('Kullanıcı verileri silinemedi: $e');
    }
  }

  // Sync settings from Firestore
  Future<void> syncSettingsFromFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Sync notification settings
      final notificationDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('notifications')
          .get();

      if (notificationDoc.exists) {
        final settings = notificationDoc.data()?['settings'] as Map<String, dynamic>?;
        if (settings != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_notificationSettingsKey, json.encode(settings));
        }
      }

      // Sync privacy settings
      final privacyDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('privacy')
          .get();

      if (privacyDoc.exists) {
        final settings = privacyDoc.data()?['settings'] as Map<String, dynamic>?;
        if (settings != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_privacySettingsKey, json.encode(settings));
        }
      }

      // Sync user preferences
      final preferencesDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('preferences')
          .get();

      if (preferencesDoc.exists) {
        final preferences = preferencesDoc.data()?['preferences'] as Map<String, dynamic>?;
        if (preferences != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userPreferencesKey, json.encode(preferences));
        }
      }

      print('Settings synced from Firestore');
    } catch (e) {
      print('Error syncing settings from Firestore: $e');
    }
  }

  // Export user data
  Future<Map<String, dynamic>> exportUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final data = <String, dynamic>{};

      // Get user profile
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        data['profile'] = userDoc.data();
      }

      // Get podcasts
      final podcastsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('podcasts')
          .get();
      
      data['podcasts'] = podcastsSnapshot.docs.map((doc) => doc.data()).toList();

      // Get flashcard decks
      final flashcardSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('flashcardDecks')
          .get();
      
      data['flashcardDecks'] = flashcardSnapshot.docs.map((doc) => doc.data()).toList();

      // Get documents
      final documentsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('documents')
          .get();
      
      data['documents'] = documentsSnapshot.docs.map((doc) => doc.data()).toList();

      // Get settings
      final settingsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .get();
      
      data['settings'] = settingsSnapshot.docs.map((doc) => doc.data()).toList();

      return data;
    } catch (e) {
      print('Error exporting user data: $e');
      throw Exception('Kullanıcı verileri dışa aktarılamadı: $e');
    }
  }
} 