import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _currentUser;
  // User data from Firestore
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null && _currentUser!.uid.isNotEmpty && !_isLoading;

  // Initialize auth state
  Future<void> initialize() async {
    try {
      _setLoading(true);
      
      // Check if user is already signed in
      final currentUser = _authService.currentUser;
      
      if (currentUser != null && currentUser.uid.isNotEmpty) {
        _currentUser = currentUser;
        // Load user data in background, don't wait for it
        _loadUserData();
        _setLoading(false);
        notifyListeners();
        return;
      }
      
      // Listen to auth state changes
      _authService.authStateChanges.listen((User? user) {
        _currentUser = user;
        if (user != null && user.uid.isNotEmpty) {
          _loadUserData();
        } else {
          _userData = null;
        }
        _setLoading(false);
        notifyListeners();
      });
      
      // If no user is signed in, set loading to false immediately
      if (currentUser == null || currentUser.uid.isEmpty) {
        _setLoading(false);
        notifyListeners();
      }
    } catch (e) {
      print('Auth initialization error: $e');
      _setLoading(false);
      notifyListeners();
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    try {
      if (_currentUser != null) {
        final userData = await _authService.getUserData(_currentUser!.uid);
        _userData = userData;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // Clear error
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Set error
  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  // Email/Password Registration
  Future<bool> registerWithEmailAndPassword(String email, String password) async {
    try {
      _clearError();
      _setLoading(true);
      
      await _authService.registerWithEmailAndPassword(email, password);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Email/Password Sign In
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _clearError();
      _setLoading(true);
      
      await _authService.signInWithEmailAndPassword(email, password);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Sign in with Google (not implemented)
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    
    try {
      // Google Sign-In is not implemented in this version
      _setError('Google ile giriş henüz desteklenmiyor');
      return false;
    } catch (e) {
      _setError('Google ile giriş hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _setError('Şifre sıfırlama hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign Out
  Future<bool> signOut() async {
    try {
      _clearError();
      _setLoading(true);
      
      await _authService.signOut();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Update user data
  Future<bool> updateUserData(Map<String, dynamic> data) async {
    try {
      if (_currentUser == null) return false;
      
      _clearError();
      _setLoading(true);
      
      await _authService.updateUserData(_currentUser!.uid, data);
      
      // Reload user data
      await _loadUserData();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    if (_currentUser != null) {
      await _loadUserData();
    }
  }
} 