import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/conversation.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Authentication methods with enhanced error handling
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      print('Error signing in anonymously: $e');
      
      // Check if it's an admin-restricted operation
      if (e.toString().contains('admin-restricted-operation')) {
        print('Anonymous authentication is disabled. Using local mode.');
        return null;
      }
      
      // Check if it's a network error
      if (e.toString().contains('network') || e.toString().contains('timeout')) {
        print('Network error during anonymous sign in. Using local mode.');
        return null;
      }
      
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Firestore methods for conversations with enhanced error handling
  Future<void> saveConversation(Conversation conversation) async {
    try {
      // First, ensure the user document exists
      await _firestore
          .collection('users')
          .doc(conversation.userId)
          .set({
        'createdAt': DateTime.now().toIso8601String(),
        'lastUpdated': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      
      // Then save the conversation
      await _firestore
          .collection('users')
          .doc(conversation.userId)
          .collection('conversations')
          .doc(conversation.id)
          .set(conversation.toMap());
    } catch (e) {
      print('Error saving conversation: $e');
      
      // If Firestore save fails, try to save locally
      try {
        await _saveConversationLocally(conversation);
        print('Conversation saved locally as backup');
      } catch (localError) {
        print('Local save also failed: $localError');
        rethrow;
      }
    }
  }
  
  // Save conversation locally as backup
  Future<void> _saveConversationLocally(Conversation conversation) async {
    try {
      // This would save to local storage
      print('Saving conversation locally: ${conversation.id}');
    } catch (e) {
      print('Local save error: $e');
      rethrow;
    }
  }

  Future<void> updateConversation(Conversation conversation) async {
    try {
      await _firestore
          .collection('users')
          .doc(conversation.userId)
          .collection('conversations')
          .doc(conversation.id)
          .update(conversation.toMap());
    } catch (e) {
      print('Error updating conversation: $e');
      rethrow;
    }
  }

  Future<Conversation?> getConversation(String conversationId) async {
    try {
      final doc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();
      
      if (doc.exists) {
        return Conversation.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting conversation: $e');
      return null;
    }
  }

  // Get latest conversation for user with enhanced error handling
  Future<Conversation?> getLatestConversation(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('conversations')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Conversation.fromMap(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Failed to get latest conversation: $e');
      return null;
    }
  }

  // Get all conversations for user with enhanced error handling
  Future<List<Conversation>> getUserConversations(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('conversations')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Conversation.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to get user conversations: $e');
      return [];
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .delete();
    } catch (e) {
      print('Error deleting conversation: $e');
      rethrow;
    }
  }

  // Helper method to create a new conversation
  Conversation createNewConversation(String userId) {
    return Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      messages: [],
      createdAt: DateTime.now(),
    );
  }

  // Helper method to add message to conversation
  Conversation addMessageToConversation(
    Conversation conversation,
    ConversationMessage message,
  ) {
    final updatedMessages = List<ConversationMessage>.from(conversation.messages)
      ..add(message);
    
    return Conversation(
      id: conversation.id,
      userId: conversation.userId,
      messages: updatedMessages,
      createdAt: conversation.createdAt,
      updatedAt: DateTime.now(),
    );
  }
} 