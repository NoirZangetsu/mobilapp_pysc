import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email/Password Registration
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      // Create user document in Firestore
      await _createUserDocument(userCredential.user!);

      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Email/Password Sign In
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if email is verified
      if (!userCredential.user!.emailVerified) {
        await _auth.signOut();
        throw 'Lütfen e-posta adresinizi doğrulayın.';
      }

      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Google Sign In
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw 'Google ile giriş iptal edildi.';
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Create or update user document in Firestore
      await _createOrUpdateUserDocument(userCredential.user!);

      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Anonymous Sign In with enhanced error handling
  Future<UserCredential?> signInAnonymously() async {
    try {
      print('Attempting anonymous sign in...');
      
      // Check if anonymous auth is enabled in Firebase Console
      UserCredential userCredential = await _auth.signInAnonymously();
      
      print('Anonymous sign in successful: ${userCredential.user?.uid}');
      
      // Create user document for anonymous user
      try {
        await _createOrUpdateUserDocument(userCredential.user!);
        print('User document created/updated successfully');
      } catch (docError) {
        print('Error creating user document: $docError');
        // Continue even if document creation fails
      }
      
      return userCredential;
    } catch (e) {
      print('Anonymous sign in error: $e');
      
      // Check if it's an admin-restricted operation
      if (e.toString().contains('admin-restricted-operation') || 
          e.toString().contains('List<Object?>') ||
          e.toString().contains('PigeonUserDetails')) {
        print('Anonymous authentication is disabled or has configuration issues. Using local mode.');
        return null; // Return null instead of throwing
      }
      
      // Check if it's a network error
      if (e.toString().contains('network') || e.toString().contains('timeout')) {
        print('Network error during anonymous sign in. Using local mode.');
        return null; // Return null instead of throwing
      }
      
      // For other errors, provide a generic message and return null
      print('Authentication failed. Using local mode.');
      return null;
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user) async {
    try {
      UserModel userModel = UserModel.fromFirebaseUser(user);
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toMap());
    } catch (e) {
      print('Error creating user document: $e');
    }
  }

  // Create or update user document in Firestore
  Future<void> _createOrUpdateUserDocument(User user) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // Create new user document
        UserModel userModel = UserModel.fromFirebaseUser(user);
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());
      } else {
        // Update existing user document with latest info
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({
          'email': user.email,
          'displayName': user.displayName,
        });
      }
    } catch (e) {
      print('Error creating/updating user document: $e');
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user data in Firestore
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update(data);
    } catch (e) {
      throw 'Kullanıcı verileri güncellenirken hata oluştu: $e';
    }
  }

  // Handle authentication errors
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.';
        case 'wrong-password':
          return 'Hatalı şifre.';
        case 'email-already-in-use':
          return 'Bu e-posta adresi zaten kullanımda.';
        case 'weak-password':
          return 'Şifre çok zayıf. En az 6 karakter kullanın.';
        case 'invalid-email':
          return 'Geçersiz e-posta adresi.';
        case 'user-disabled':
          return 'Bu kullanıcı hesabı devre dışı bırakılmış.';
        case 'too-many-requests':
          return 'Çok fazla başarısız giriş denemesi. Lütfen daha sonra tekrar deneyin.';
        case 'operation-not-allowed':
          return 'Bu giriş yöntemi etkin değil.';
        default:
          return 'Kimlik doğrulama hatası: ${error.message}';
      }
    }
    return 'Beklenmeyen bir hata oluştu: $error';
  }
} 