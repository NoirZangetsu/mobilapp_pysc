import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      // Update last sign in time
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'lastSignIn': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      
      return credential;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      // Create user document
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'email': email,
        'createdAt': DateTime.now().toIso8601String(),
        'lastSignIn': DateTime.now().toIso8601String(),
      });
      
      return credential;
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('User signed out successfully');
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent');
    } catch (e) {
      print('Password reset error: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.updatePhotoURL(photoURL);
      print('User profile updated');
    } catch (e) {
      print('Profile update error: $e');
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      print('Get user data error: $e');
      return null;
    }
  }

  // Update user data in Firestore
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update(data);
      print('User data updated');
    } catch (e) {
      print('Update user data error: $e');
      rethrow;
    }
  }
} 